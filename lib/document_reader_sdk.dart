import 'dart:convert';

import 'license_status.dart';
import 'normalize_result.dart';
import 'src/document_reader_sdk_platform_interface.dart';

export 'capture/document_capture.dart';
export 'live/camera_frame_jpeg.dart';
export 'live/guide_crop.dart';
export 'live/locate_session.dart';
export 'license_status.dart';
export 'normalize_result.dart';
export 'result/result_parser.dart';

const int sdkSuccess = 0;
const int sdkLicenseInvalid = 1;
const int sdkLicenseExpired = 2;
const int sdkNotActivated = 3;
const int sdkInitFailed = 4;

/// File path, content URI, or base64 (optionally `data:` URL).
typedef ImageInput = String;

/// … machine code for license requests.
Future<String> getMachineCode() {
  return DocumentRecognitionSdkPlatform.instance.getMachineCode();
}

/// Activate with … bound to applicationId / bundle id.
Future<int> setActivation(String license) {
  return DocumentRecognitionSdkPlatform.instance.setActivation(license);
}

/// Load engine + database. Returns SDK status code (0 = success).
Future<int> init() {
  return DocumentRecognitionSdkPlatform.instance.init();
}

Future<void> deinit() {
  return DocumentRecognitionSdkPlatform.instance.deinit();
}

/// Open a process session. Prefer FullProcess before recognize.
Future<String> startNewSession([
  String optionsJson = '{"scenario":"FullProcess","series":false}',
]) {
  return DocumentRecognitionSdkPlatform.instance.startNewSession(optionsJson);
}

/// Live locate — JSON with score + position.corners.
Future<String> locateDocument(
  ImageInput image, {
  bool alreadyCropped = false,
}) {
  return DocumentRecognitionSdkPlatform.instance.locateDocument(
    image,
    alreadyCropped: alreadyCropped,
  );
}

String authenticityModeValue([Object? authenticity = true]) {
  if (authenticity == false || authenticity == 'none') return 'none';
  return 'normal';
}

/// Still OCR / MRZ / barcode. Returns canonical iOS-shaped JSON.
/// [authenticity] is `true`/`false` or `'none'` / `'normal'`.
/// [alreadyCropped] false for camera guide crops (re-detect + upright); true only for tight gallery crops.
Future<String> recognize(
  ImageInput front, [
  ImageInput? back,
  Object authenticity = true,
  bool alreadyCropped = false,
]) async {
  final json = await DocumentRecognitionSdkPlatform.instance.recognize(
    front,
    back,
    authenticityModeValue(authenticity),
    alreadyCropped: alreadyCropped,
  );
  return normalizeResultJson(json);
}

/// OCR / MRZ / barcode only. Authenticity is always off.
Future<String> documentRecognition(
  ImageInput front, [
  ImageInput? back,
  bool alreadyCropped = false,
]) async {
  final json = await DocumentRecognitionSdkPlatform.instance.documentRecognition(
    front,
    back,
    alreadyCropped: alreadyCropped,
  );
  return normalizeResultJson(json);
}

/// Authenticity / security only. OCR / MRZ / barcode are always off.
Future<String> documentLiveness(
  ImageInput front, [
  ImageInput? back,
  bool alreadyCropped = false,
]) async {
  final json = await DocumentRecognitionSdkPlatform.instance.documentLiveness(
    front,
    back,
    alreadyCropped: alreadyCropped,
  );
  return normalizeResultJson(json);
}

/// Typed recognize — same as [recognize] then [normalizeResult].
Future<DocResult> recognizeResult(
  ImageInput front, [
  ImageInput? back,
  Object authenticity = true,
  bool alreadyCropped = false,
]) async {
  final json = await recognize(
    front,
    back,
    authenticity,
    alreadyCropped,
  );
  return normalizeResult(json);
}

Future<String> lastLicenseError() {
  return DocumentRecognitionSdkPlatform.instance.lastLicenseError();
}

/// Parsed license capabilities (`label` is what About / home status show).
Future<LicenseStatus> getLicenseStatus() async {
  final json = await DocumentRecognitionSdkPlatform.instance.getLicenseStatus();
  return LicenseStatus.fromJson(json);
}

/// Writes a JSON status blob for device debug.
Future<void> writeStatus(Map<String, dynamic> payload) {
  return DocumentRecognitionSdkPlatform.instance.writeStatus(jsonEncode(payload));
}

Future<String> documentProcess({
  required String imagesJson,
  String rfidJson = '',
  String optionsJson = '{}',
}) async {
  return DocumentRecognitionSdkPlatform.instance.documentProcess(
    imagesJson,
    rfidJson,
    optionsJson,
  );
}

Future<String> faceLiveness(ImageInput image, {int mode = 0}) async {
  return DocumentRecognitionSdkPlatform.instance.faceLiveness(image, mode);
}

