import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'document_reader_sdk_platform_interface.dart';

/// MethodChannel implementation — channel name matches RN `DocumentRecognitionSdk`.
class MethodChannelDocumentRecognitionSdk extends DocumentRecognitionSdkPlatform {
  @visibleForTesting
  final methodChannel = const MethodChannel('DocumentRecognitionSdk');

  @override
  Future<String> getMachineCode() async {
    final value = await methodChannel.invokeMethod<String>('getMachineCode');
    return value ?? '';
  }

  @override
  Future<int> setActivation(String license) async {
    final value =
        await methodChannel.invokeMethod<int>('setActivation', license);
    return value ?? -1;
  }

  @override
  Future<int> init() async {
    final value = await methodChannel.invokeMethod<int>('init');
    return value ?? -1;
  }

  @override
  Future<void> deinit() async {
    await methodChannel.invokeMethod<void>('deinit');
  }

  @override
  Future<String> startNewSession(String optionsJson) async {
    final value = await methodChannel.invokeMethod<String>(
      'startNewSession',
      optionsJson,
    );
    return value ?? '';
  }

  @override
  Future<String> locateDocument(
    String image, {
    bool alreadyCropped = false,
  }) async {
    final value = await methodChannel.invokeMethod<String>('locateDocument', {
      'image': image,
      'alreadyCropped': alreadyCropped,
    });
    return value ?? '';
  }

  @override
  Future<String> recognize(
    String front,
    String? back,
    String authenticityMode, {
    bool alreadyCropped = false,
  }) async {
    final value = await methodChannel.invokeMethod<String>(
      'recognize',
      <String, dynamic>{
        'front': front,
        'back': back,
        'authenticityMode': authenticityMode,
        'alreadyCropped': alreadyCropped,
      },
    );
    return value ?? '';
  }

  @override
  Future<String> documentRecognition(
    String front,
    String? back, {
    bool alreadyCropped = false,
  }) async {
    final value = await methodChannel.invokeMethod<String>(
      'documentRecognition',
      <String, dynamic>{
        'front': front,
        'back': back,
        'alreadyCropped': alreadyCropped,
      },
    );
    return value ?? '';
  }

  @override
  Future<String> documentLiveness(
    String front,
    String? back, {
    bool alreadyCropped = false,
  }) async {
    final value = await methodChannel.invokeMethod<String>(
      'documentLiveness',
      <String, dynamic>{
        'front': front,
        'back': back,
        'alreadyCropped': alreadyCropped,
      },
    );
    return value ?? '';
  }

  @override
  Future<String> lastLicenseError() async {
    final value =
        await methodChannel.invokeMethod<String>('lastLicenseError');
    return value ?? '';
  }

  @override
  Future<String> getLicenseStatus() async {
    final value =
        await methodChannel.invokeMethod<String>('getLicenseStatus');
    return value ?? '{}';
  }

  @override
  Future<void> writeStatus(String json) async {
    await methodChannel.invokeMethod<void>('writeStatus', json);
  }

  @override
  Future<String> documentProcess(
    String imagesJson,
    String rfidJson,
    String optionsJson,
  ) async {
    final res = await methodChannel.invokeMethod<String>('documentProcess', {
      'imagesJson': imagesJson,
      'rfidJson': rfidJson,
      'optionsJson': optionsJson,
    });
    return res ?? '{}';
  }

  @override
  Future<String> faceLiveness(String image, int mode) async {
    final res = await methodChannel.invokeMethod<String>('faceLiveness', {
      'image': image,
      'mode': mode,
    });
    return res ?? '{}';
  }
}
