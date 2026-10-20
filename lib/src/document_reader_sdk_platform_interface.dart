import 'package:plugin_platform_interface/plugin_platform_interface.dart';

import 'document_reader_sdk_method_channel.dart';

abstract class DocumentRecognitionSdkPlatform extends PlatformInterface {
  DocumentRecognitionSdkPlatform() : super(token: _token);

  static final Object _token = Object();

  static DocumentRecognitionSdkPlatform _instance = MethodChannelDocumentRecognitionSdk();

  static DocumentRecognitionSdkPlatform get instance => _instance;

  static set instance(DocumentRecognitionSdkPlatform instance) {
    PlatformInterface.verifyToken(instance, _token);
    _instance = instance;
  }

  Future<String> getMachineCode() {
    throw UnimplementedError('getMachineCode() has not been implemented.');
  }

  Future<int> setActivation(String license) {
    throw UnimplementedError('setActivation() has not been implemented.');
  }

  Future<int> init() {
    throw UnimplementedError('init() has not been implemented.');
  }

  Future<void> deinit() {
    throw UnimplementedError('deinit() has not been implemented.');
  }

  Future<String> startNewSession(String optionsJson) {
    throw UnimplementedError('startNewSession() has not been implemented.');
  }

  Future<String> locateDocument(
    String image, {
    bool alreadyCropped = false,
  }) {
    throw UnimplementedError('locateDocument() has not been implemented.');
  }

  Future<String> recognize(
    String front,
    String? back,
    String authenticityMode, {
    bool alreadyCropped = false,
  }) {
    throw UnimplementedError('recognize() has not been implemented.');
  }

  Future<String> documentRecognition(
    String front,
    String? back, {
    bool alreadyCropped = false,
  }) {
    throw UnimplementedError('documentRecognition() has not been implemented.');
  }

  Future<String> documentLiveness(
    String front,
    String? back, {
    bool alreadyCropped = false,
  }) {
    throw UnimplementedError('documentLiveness() has not been implemented.');
  }

  Future<String> lastLicenseError() {
    throw UnimplementedError('lastLicenseError() has not been implemented.');
  }

  Future<String> getLicenseStatus() {
    throw UnimplementedError('getLicenseStatus() has not been implemented.');
  }

  Future<void> writeStatus(String json) {
    throw UnimplementedError('writeStatus() has not been implemented.');
  }

  Future<String> documentProcess(
    String imagesJson,
    String rfidJson,
    String optionsJson,
  ) {
    throw UnimplementedError('documentProcess() has not been implemented.');
  }

  Future<String> faceLiveness(String image, int mode) {
    throw UnimplementedError('faceLiveness() has not been implemented.');
  }
}
