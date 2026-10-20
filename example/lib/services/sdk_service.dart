import 'package:flutter/foundation.dart';

import 'package:document_reader_sdk/document_reader_sdk.dart';

import '../core/constants/license.dart';
import '../models/sdk_status.dart';

class SdkService extends ChangeNotifier {
  SdkStatus _status = const SdkStatus(
    phase: SdkPhase.loading,
    message: 'Starting SDK…',
  );

  SdkStatus get status => _status;
  bool get ready => _status.ready;
  String get statusMessage => _status.message;
  String _licenseVerdict = '…';
  String get licenseVerdict => _licenseVerdict;

  Future<void> bootstrap() async {
    _status = const SdkStatus(
      phase: SdkPhase.loading,
      message: 'Starting SDK…',
    );
    notifyListeners();

    try {
      final mc = await getMachineCode();
      debugPrint('[DocReader] machine=$mc');
      final key = demoLicense().trim();
      if (key.isEmpty) {
        _licenseVerdict = 'Empty';
        _status = SdkStatus(phase: SdkPhase.error, message: 'Empty license', machine: mc);
        notifyListeners();
        return;
      }
      final act = await setActivation(key);
      debugPrint('[DocReader] setActivation=$act');
      if (act != 0) {
        _licenseVerdict = act == 2 ? 'Expired' : 'Failed';
        final detail = await lastLicenseError();
        _status = SdkStatus(
          phase: SdkPhase.error,
          message: '${_statusLabel(act)}${detail.isNotEmpty ? ': $detail' : ''}',
          machine: mc,
        );
        notifyListeners();
        return;
      }
      final code = await init();
      debugPrint('[DocReader] init=$code');
      var message = _statusLabel(code);
      _licenseVerdict = code == 0 ? 'Correct' : (code == 2 ? 'Expired' : 'Failed');
      if (code == 0) {
        try {
          final license = await getLicenseStatus();
          message = readyStatusMessage(license.label);
        } catch (_) {}
      }
      _status = SdkStatus(
        phase: code == 0 ? SdkPhase.ready : SdkPhase.error,
        message: message,
        machine: mc,
      );
      notifyListeners();
      try {
        await writeStatus({
          'step': 'dart',
          'status': message,
          'ready': code == 0,
          'machine': mc,
          'code': code,
        });
      } catch (_) {}
    } catch (e) {
      debugPrint('[DocReader] init exception=$e');
      _status = SdkStatus(
        phase: SdkPhase.error,
        message: 'Init error: $e',
      );
      notifyListeners();
    }
  }

  Future<void> refresh() => bootstrap();

  String _statusLabel(int code) {
    switch (code) {
      case 0:
        return 'Ready';
      case 1:
        return 'Invalid license';
      case 2:
        return 'License expired';
      case 3:
        return 'License not activated';
      case 4:
        return 'Engine failed to start';
      case 5:
        return 'No database found';
      case 6:
        return 'Database loading error';
      default:
        return 'Failed ($code)';
    }
  }
}
