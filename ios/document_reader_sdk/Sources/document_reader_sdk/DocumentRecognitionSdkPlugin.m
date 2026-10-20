#import "DocumentRecognitionSdkPlugin.h"
#import <UIKit/UIKit.h>

#if __has_include(<documentlivenesssdk/DocumentLivenessSDK.h>)
#import <documentlivenesssdk/DocumentLivenessSDK.h>
#define DRS_HAS_DOCSDK 1
#elif __has_include("DocumentLivenessSDK.h")
#import "DocumentLivenessSDK.h"
#define DRS_HAS_DOCSDK 1
#endif

@implementation DocumentRecognitionSdkPlugin

+ (void)registerWithRegistrar:(NSObject<FlutterPluginRegistrar> *)registrar {
  FlutterMethodChannel *channel =
      [FlutterMethodChannel methodChannelWithName:@"DocumentRecognitionSdk"
                                  binaryMessenger:[registrar messenger]];
  DocumentRecognitionSdkPlugin *instance = [[DocumentRecognitionSdkPlugin alloc] init];
  [registrar addMethodCallDelegate:instance channel:channel];
}

static void DRSWriteStatusFile(NSDictionary *payload) {
  NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
  if (paths.count == 0) {
    return;
  }
  NSString *path = [paths[0] stringByAppendingPathComponent:@"docreader_status.json"];
  NSMutableDictionary *body = [payload mutableCopy] ?: [NSMutableDictionary dictionary];
  body[@"ts"] = @((long long)([[NSDate date] timeIntervalSince1970] * 1000.0));
  NSError *err = nil;
  NSData *data = [NSJSONSerialization dataWithJSONObject:body options:NSJSONWritingPrettyPrinted error:&err];
  if (data == nil) {
    return;
  }
  [data writeToFile:path atomically:YES];
}

static UIImage *DRSImageFromUriOrBase64(NSString *uriOrBase64) {
  if (uriOrBase64 == nil || uriOrBase64.length == 0) {
    return nil;
  }

  BOOL looksBase64 = [uriOrBase64 hasPrefix:@"data:"] ||
    ([uriOrBase64 length] > 256 &&
     [uriOrBase64 rangeOfString:@"://"].location == NSNotFound &&
     ![uriOrBase64 hasPrefix:@"/"] &&
     ![uriOrBase64 hasPrefix:@"file:"]);

  if (looksBase64) {
    NSString *payload = uriOrBase64;
    NSRange range = [uriOrBase64 rangeOfString:@"base64,"];
    if (range.location != NSNotFound) {
      payload = [uriOrBase64 substringFromIndex:range.location + range.length];
    }
    NSData *data = [[NSData alloc] initWithBase64EncodedString:payload options:NSDataBase64DecodingIgnoreUnknownCharacters];
    if (data == nil) {
      return nil;
    }
    return [UIImage imageWithData:data];
  }

  if ([uriOrBase64 hasPrefix:@"/"] || [uriOrBase64 hasPrefix:@"file:"]) {
    NSString *path = uriOrBase64;
    if ([path hasPrefix:@"file:"]) {
      NSURL *fileURL = [NSURL URLWithString:path];
      path = fileURL.path ?: path;
    }
    UIImage *fromFile = [UIImage imageWithContentsOfFile:path];
    if (fromFile != nil) {
      return fromFile;
    }
  }

  NSURL *url = [NSURL URLWithString:uriOrBase64];
  if (url == nil) {
    return nil;
  }
  NSData *data = [NSData dataWithContentsOfURL:url];
  if (data == nil) {
    return nil;
  }
  return [UIImage imageWithData:data];
}

static UIImage *DRSRedrawAtScale1(UIImage *image, CGSize pixelSize) {
  UIGraphicsImageRendererFormat *format = [UIGraphicsImageRendererFormat defaultFormat];
  format.scale = 1;
  format.opaque = YES;
  UIGraphicsImageRenderer *renderer =
    [[UIGraphicsImageRenderer alloc] initWithSize:pixelSize format:format];
  return [renderer imageWithActions:^(UIGraphicsImageRendererContext * _Nonnull ctx) {
    [image drawInRect:CGRectMake(0, 0, pixelSize.width, pixelSize.height)];
  }];
}

static UIImage *DRSFixOrientation(UIImage *image) {
  if (image == nil) {
    return nil;
  }
  if (image.imageOrientation == UIImageOrientationUp && image.scale == 1.0) {
    return image;
  }
  CGSize pixelSize = CGSizeMake(image.size.width * image.scale, image.size.height * image.scale);
  return DRSRedrawAtScale1(image, pixelSize);
}

static UIImage *DRSUprightCameraImage(UIImage *image) {
  if (image == nil) {
    return nil;
  }
  UIImage *oriented = image;
  CGFloat pw = image.size.width * image.scale;
  CGFloat ph = image.size.height * image.scale;
  if (pw > ph && image.imageOrientation == UIImageOrientationUp) {
    oriented = [UIImage imageWithCGImage:image.CGImage scale:1.0 orientation:UIImageOrientationRight];
  }
  return DRSFixOrientation(oriented);
}

static UIImage *DRSScaledMaxEdge(UIImage *image, CGFloat maxEdge) {
  if (image == nil) {
    return nil;
  }
  CGFloat pw = image.size.width * image.scale;
  CGFloat ph = image.size.height * image.scale;
  CGFloat longest = MAX(pw, ph);
  if (longest <= maxEdge || longest <= 0) {
    return image;
  }
  CGFloat factor = maxEdge / longest;
  CGSize newSize = CGSizeMake(MAX(1.0, pw * factor), MAX(1.0, ph * factor));
  return DRSRedrawAtScale1(image, newSize);
}

static NSString *DRSRescaleLocateJson(
  NSString *json,
  CGFloat locateW,
  CGFloat locateH,
  CGFloat imageW,
  CGFloat imageH
) {
  if (json.length == 0) {
    return json;
  }
  NSData *data = [json dataUsingEncoding:NSUTF8StringEncoding];
  id parsed = data ? [NSJSONSerialization JSONObjectWithData:data options:0 error:nil] : nil;
  if (![parsed isKindOfClass:[NSDictionary class]]) {
    return json;
  }
  NSMutableDictionary *root = [parsed mutableCopy];
  root[@"_locateImageWidth"] = @(imageW);
  root[@"_locateImageHeight"] = @(imageH);
  id posObj = root[@"position"];
  if (![posObj isKindOfClass:[NSDictionary class]]) {
    NSData *metaOnly = [NSJSONSerialization dataWithJSONObject:root options:0 error:nil];
    return metaOnly ? [[NSString alloc] initWithData:metaOnly encoding:NSUTF8StringEncoding] : json;
  }
  NSMutableDictionary *pos = [posObj mutableCopy];
  CGFloat sx = imageW / MAX(locateW, 1.0);
  CGFloat sy = imageH / MAX(locateH, 1.0);

  id corners = pos[@"corners"];
  if ([corners isKindOfClass:[NSArray class]]) {
    NSMutableArray *scaled = [NSMutableArray arrayWithCapacity:[corners count]];
    for (id item in corners) {
      if (![item isKindOfClass:[NSDictionary class]]) {
        continue;
      }
      NSDictionary *p = item;
      [scaled addObject:@{
        @"x": @([p[@"x"] doubleValue] * sx),
        @"y": @([p[@"y"] doubleValue] * sy),
      }];
    }
    pos[@"corners"] = scaled;
  } else {
    if (pos[@"left"] != nil) pos[@"left"] = @([pos[@"left"] doubleValue] * sx);
    if (pos[@"top"] != nil) pos[@"top"] = @([pos[@"top"] doubleValue] * sy);
    if (pos[@"right"] != nil) pos[@"right"] = @([pos[@"right"] doubleValue] * sx);
    if (pos[@"bottom"] != nil) pos[@"bottom"] = @([pos[@"bottom"] doubleValue] * sy);
  }
  root[@"position"] = pos;
  NSData *out = [NSJSONSerialization dataWithJSONObject:root options:0 error:nil];
  return out ? [[NSString alloc] initWithData:out encoding:NSUTF8StringEncoding] : json;
}

- (void)handleMethodCall:(FlutterMethodCall *)call result:(FlutterResult)result {
  if ([@"getMachineCode" isEqualToString:call.method]) {
    dispatch_async(dispatch_get_global_queue(QOS_CLASS_USER_INITIATED, 0), ^{
#ifdef DRS_HAS_DOCSDK
      NSString *mc = [DocumentLivenessSDK getMachineCode] ?: @"";
      DRSWriteStatusFile(@{ @"step": @"getMachineCode", @"machine": mc });
      result(mc);
#else
      result([FlutterError errorWithCode:@"E_SDK"
                                 message:@"documentlivenesssdk.framework not linked. Drop frameworks into ios/Frameworks/."
                                 details:nil]);
#endif
    });
  } else if ([@"setActivation" isEqualToString:call.method]) {
    NSString *license = call.arguments ?: @"";
    dispatch_async(dispatch_get_global_queue(QOS_CLASS_USER_INITIATED, 0), ^{
#ifdef DRS_HAS_DOCSDK
      int code = [DocumentLivenessSDK setActivation:license];
      DRSWriteStatusFile(@{
        @"step": @"setActivation",
        @"code": @(code),
        @"licenseError": [DocumentLivenessSDK lastLicenseError] ?: @""
      });
      result(@(code));
#else
      result([FlutterError errorWithCode:@"E_SDK" message:@"documentlivenesssdk.framework not linked" details:nil]);
#endif
    });
  } else if (([@"init" isEqualToString:call.method] || [@"initSDK" isEqualToString:call.method])) {
    dispatch_async(dispatch_get_global_queue(QOS_CLASS_USER_INITIATED, 0), ^{
#ifdef DRS_HAS_DOCSDK
      int code = [DocumentLivenessSDK initSDK];
      DRSWriteStatusFile(@{
        @"step": @"init",
        @"code": @(code),
        @"ready": @(code == 0),
        @"licenseError": [DocumentLivenessSDK lastLicenseError] ?: @""
      });
      result(@(code));
#else
      result([FlutterError errorWithCode:@"E_SDK" message:@"documentlivenesssdk.framework not linked" details:nil]);
#endif
    });
  } else if (([@"deinit" isEqualToString:call.method] || [@"deinitSDK" isEqualToString:call.method])) {
    dispatch_async(dispatch_get_global_queue(QOS_CLASS_USER_INITIATED, 0), ^{
#ifdef DRS_HAS_DOCSDK
      [DocumentLivenessSDK deinitSDK];
      result(nil);
#else
      result([FlutterError errorWithCode:@"E_SDK" message:@"documentlivenesssdk.framework not linked" details:nil]);
#endif
    });
  } else if ([@"startNewSession" isEqualToString:call.method]) {
    NSString *optionsJson = call.arguments;
    dispatch_async(dispatch_get_global_queue(QOS_CLASS_USER_INITIATED, 0), ^{
#ifdef DRS_HAS_DOCSDK
      NSString *json = (optionsJson == nil || optionsJson.length == 0)
        ? [DocumentLivenessSDK startNewSession]
        : [DocumentLivenessSDK startNewSession:optionsJson];
      result(json ?: @"");
#else
      result([FlutterError errorWithCode:@"E_SDK" message:@"documentlivenesssdk.framework not linked" details:nil]);
#endif
    });
  } else if ([@"locateDocument" isEqualToString:call.method]) {
    NSString *imageUri = @"";
    BOOL alreadyCropped = NO;
    if ([call.arguments isKindOfClass:[NSDictionary class]]) {
      NSDictionary *args = call.arguments;
      imageUri = [args[@"image"] isKindOfClass:[NSString class]] ? args[@"image"] : @"";
      alreadyCropped = args[@"alreadyCropped"] != nil ? [args[@"alreadyCropped"] boolValue] : NO;
    } else if ([call.arguments isKindOfClass:[NSString class]]) {
      imageUri = call.arguments;
    }
    dispatch_async(dispatch_get_global_queue(QOS_CLASS_USER_INITIATED, 0), ^{
#ifdef DRS_HAS_DOCSDK
      UIImage *raw = DRSImageFromUriOrBase64(imageUri);
      UIImage *image = DRSUprightCameraImage(raw);
      if (image == nil) {
        result([FlutterError errorWithCode:@"E_IMAGE" message:@"Could not decode image" details:nil]);
        return;
      }
      CGFloat imageW = image.size.width * image.scale;
      CGFloat imageH = image.size.height * image.scale;
      UIImage *locateBmp = DRSScaledMaxEdge(image, 480.0);
      CGFloat locateW = locateBmp.size.width * locateBmp.scale;
      CGFloat locateH = locateBmp.size.height * locateBmp.scale;
      NSString *json = nil;
      json = [DocumentLivenessSDK locateDocument:locateBmp] ?: @"";
      result(DRSRescaleLocateJson(json ?: @"", locateW, locateH, imageW, imageH));
#else
      result([FlutterError errorWithCode:@"E_SDK" message:@"documentlivenesssdk.framework not linked" details:nil]);
#endif
    });
  } else if ([@"recognize" isEqualToString:call.method]) {
    NSDictionary *args = call.arguments;
    NSString *frontUri = [args[@"front"] isKindOfClass:[NSString class]] ? args[@"front"] : @"";
    // Flutter encodes Dart null as NSNull — must not treat it as NSString.
    id backArg = args[@"back"];
    NSString *backUri = ([backArg isKindOfClass:[NSString class]] && [(NSString *)backArg length] > 0)
        ? (NSString *)backArg
        : nil;
    NSString *mode = [args[@"authenticityMode"] isKindOfClass:[NSString class]] ? args[@"authenticityMode"] : nil;
    if (mode.length == 0) {
      BOOL authenticity = args[@"authenticity"] != nil ? [args[@"authenticity"] boolValue] : YES;
      mode = authenticity ? @"normal" : @"none";
    }
    BOOL alreadyCropped = args[@"alreadyCropped"] != nil ? [args[@"alreadyCropped"] boolValue] : NO;
    dispatch_async(dispatch_get_global_queue(QOS_CLASS_USER_INITIATED, 0), ^{
#ifdef DRS_HAS_DOCSDK
      UIImage *front = DRSImageFromUriOrBase64(frontUri);
      if (front == nil) {
        result([FlutterError errorWithCode:@"E_IMAGE" message:@"Could not decode front image" details:nil]);
        return;
      }
      UIImage *back = backUri != nil ? DRSImageFromUriOrBase64(backUri) : nil;
      // Liveness product: authenticity / PAD path uses FullAuth.
      [DocumentLivenessSDK startNewSession:@"{\"scenario\":\"FullAuth\",\"series\":false}"];
      NSString *json = nil;
      if ([DocumentLivenessSDK respondsToSelector:@selector(recognizeFront:back:authenticityMode:alreadyCropped:)]) {
        json = [DocumentLivenessSDK recognizeFront:front back:back authenticityMode:mode alreadyCropped:alreadyCropped];
      } else if ([DocumentLivenessSDK respondsToSelector:@selector(recognizeFront:back:authenticityMode:)]) {
        json = [DocumentLivenessSDK recognizeFront:front back:back authenticityMode:mode];
      } else {
        json = [DocumentLivenessSDK recognizeFront:front back:back authenticity:![mode.lowercaseString isEqualToString:@"none"]];
      }
      result(json ?: @"");
#else
      result([FlutterError errorWithCode:@"E_SDK" message:@"documentlivenesssdk.framework not linked" details:nil]);
#endif
    });
  } else if ([@"documentRecognition" isEqualToString:call.method] ||
             [@"documentLiveness" isEqualToString:call.method]) {
    NSDictionary *args = call.arguments;
    NSString *frontUri = [args[@"front"] isKindOfClass:[NSString class]] ? args[@"front"] : @"";
    id backArg = args[@"back"];
    NSString *backUri = ([backArg isKindOfClass:[NSString class]] && [(NSString *)backArg length] > 0)
        ? (NSString *)backArg
        : nil;
    BOOL alreadyCropped = args[@"alreadyCropped"] != nil ? [args[@"alreadyCropped"] boolValue] : NO;
    BOOL livenessOnly = [@"documentLiveness" isEqualToString:call.method];
    dispatch_async(dispatch_get_global_queue(QOS_CLASS_USER_INITIATED, 0), ^{
#ifdef DRS_HAS_DOCSDK
      UIImage *front = DRSImageFromUriOrBase64(frontUri);
      if (front == nil) {
        result([FlutterError errorWithCode:@"E_IMAGE" message:@"Could not decode front image" details:nil]);
        return;
      }
      UIImage *back = backUri != nil ? DRSImageFromUriOrBase64(backUri) : nil;
      NSString *scenario = livenessOnly
          ? @"{\"scenario\":\"FullAuth\",\"series\":false}"
          : @"{\"scenario\":\"FullProcess\",\"series\":false}";
      [DocumentLivenessSDK startNewSession:scenario];
      NSString *json = nil;
      if (livenessOnly) {
        if ([DocumentLivenessSDK respondsToSelector:@selector(documentLivenessFront:back:alreadyCropped:)]) {
          json = [DocumentLivenessSDK documentLivenessFront:front back:back alreadyCropped:alreadyCropped];
        } else if ([DocumentLivenessSDK respondsToSelector:@selector(documentLivenessFront:back:)]) {
          json = [DocumentLivenessSDK documentLivenessFront:front back:back];
        } else {
          json = [DocumentLivenessSDK documentAuthenticityFront:front back:back];
        }
      } else if ([DocumentLivenessSDK respondsToSelector:@selector(documentRecognitionFront:back:alreadyCropped:)]) {
        json = [DocumentLivenessSDK documentRecognitionFront:front back:back alreadyCropped:alreadyCropped];
      } else if ([DocumentLivenessSDK respondsToSelector:@selector(documentRecognitionFront:back:)]) {
        json = [DocumentLivenessSDK documentRecognitionFront:front back:back];
      } else {
        json = [DocumentLivenessSDK recognizeFront:front back:back authenticityMode:@"none"];
      }
      result(json ?: @"");
#else
      result([FlutterError errorWithCode:@"E_SDK" message:@"documentlivenesssdk.framework not linked" details:nil]);
#endif
    });

  } else if ([@"documentProcess" isEqualToString:call.method]) {
    NSDictionary *args = [call.arguments isKindOfClass:[NSDictionary class]] ? call.arguments : @{};
    NSString *imagesJson = args[@"imagesJson"] ?: args[@"images"] ?: @"[]";
    NSString *rfidJson = args[@"rfidJson"] ?: args[@"rfid"] ?: @"";
    NSString *optionsJson = args[@"optionsJson"] ?: args[@"options"] ?: @"{}";
    dispatch_async(dispatch_get_global_queue(QOS_CLASS_USER_INITIATED, 0), ^{
      NSString *json = [DocumentLivenessSDK documentProcess:imagesJson rfid:rfidJson options:optionsJson];
      dispatch_async(dispatch_get_main_queue(), ^{ result(json ?: @"{}"); });
    });
  } else if ([@"faceLiveness" isEqualToString:call.method]) {
    NSDictionary *args = [call.arguments isKindOfClass:[NSDictionary class]] ? call.arguments : @{};
    NSString *uri = args[@"image"] ?: args[@"portrait"] ?: @"";
    int mode = [args[@"mode"] intValue];
    dispatch_async(dispatch_get_global_queue(QOS_CLASS_USER_INITIATED, 0), ^{
      UIImage *img = DRSImageFromUriOrBase64(uri);
      if (!img) {
        dispatch_async(dispatch_get_main_queue(), ^{
          result([FlutterError errorWithCode:@"E_IMAGE" message:@"Could not decode portrait" details:uri]);
        });
        return;
      }
      NSString *json = [DocumentLivenessSDK faceLiveness:img mode:mode];
      dispatch_async(dispatch_get_main_queue(), ^{ result(json ?: @"{}"); });
    });
  } else if ([@"lastLicenseError" isEqualToString:call.method]) {
#ifdef DRS_HAS_DOCSDK
    result([DocumentLivenessSDK lastLicenseError] ?: @"");
#else
    result(@"");
#endif
  } else if ([@"getLicenseStatus" isEqualToString:call.method]) {
#ifdef DRS_HAS_DOCSDK
    if ([DocumentLivenessSDK respondsToSelector:@selector(getLicenseStatus)]) {
      result([DocumentLivenessSDK getLicenseStatus] ?: @"{}");
    } else {
      result(@"{}");
    }
#else
    result(@"{}");
#endif
  } else if ([@"writeStatus" isEqualToString:call.method]) {
    NSString *json = call.arguments ?: @"{}";
    NSData *data = [json dataUsingEncoding:NSUTF8StringEncoding];
    id obj = data ? [NSJSONSerialization JSONObjectWithData:data options:0 error:nil] : nil;
    if ([obj isKindOfClass:[NSDictionary class]]) {
      DRSWriteStatusFile((NSDictionary *)obj);
    } else {
      DRSWriteStatusFile(@{ @"step": @"writeStatus", @"raw": json ?: @"" });
    }
    result(nil);
  } else {
    result(FlutterMethodNotImplemented);
  }
}

@end
