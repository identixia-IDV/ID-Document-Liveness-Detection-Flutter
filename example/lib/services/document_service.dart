import 'package:document_reader_sdk/document_reader_sdk.dart' as sdk;

import '../core/utils/result_parser.dart';

class DocumentService {
  Future<String> locate(String imagePath) {
    return sdk.locateDocument(imagePath);
  }

  Future<String> recognize(
    String front, {
    String? back,
    Object authenticity = true,
    bool alreadyCropped = false,
  }) {
    return sdk.recognize(
      front,
      back,
      authenticity,
      alreadyCropped,
    );
  }

  int scorePercent(String locateJson) => documentPercent(locateJson);
}
