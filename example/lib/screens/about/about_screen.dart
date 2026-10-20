import 'dart:io' show Platform;

import 'package:document_reader_sdk/document_reader_sdk.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:provider/provider.dart';

import '../../app/theme.dart';
import '../../services/sdk_service.dart';
import '../../core/constants/license.dart';
import '../../widgets/identixia_logo.dart';

class AboutScreen extends StatefulWidget {
  const AboutScreen({super.key});

  @override
  State<AboutScreen> createState() => _AboutScreenState();
}

class _AboutScreenState extends State<AboutScreen> {
  String _licenseText = 'License: …';
  late final String _appId = !kIsWeb && Platform.isIOS ? iosBundleId : androidApplicationId;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    try {
      final status = await getLicenseStatus();
      if (!mounted) return;
      setState(() {
        _licenseText = 'License: ${context.read<SdkService>().licenseVerdict}';
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _licenseText = 'License: ${context.read<SdkService>().licenseVerdict}');
    }
  }

  BoxDecoration get _card => BoxDecoration(
        color: AppColors.surface,
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(AppColors.radiusCard),
      );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('About')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const IdentixiaLogo(size: 96, onPressed: IdentixiaLogo.openWebsite),
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(18),
              decoration: _card,
              child: Text(_licenseText, style: const TextStyle(color: AppColors.text, fontSize: 13)),
            ),
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.all(18),
              decoration: _card,
              child: Text(
                _appId,
                style: const TextStyle(
                  color: AppColors.text,
                  fontSize: 13,
                  fontFamily: 'monospace',
                ),
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              height: 56,
              child: FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.accent,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppColors.radiusPill),
                  ),
                ),
                onPressed: () async {
                  await Clipboard.setData(ClipboardData(text: _appId));
                  if (!context.mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Copy')),
                  );
                },
                child: const Text(
                  'Copy',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                ),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              height: 56,
              child: OutlinedButton(
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.accent,
                  backgroundColor: AppColors.surface,
                  side: const BorderSide(color: AppColors.border),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppColors.radiusPill),
                  ),
                ),
                onPressed: IdentixiaLogo.openWebsite,
                child: const Text(
                  'identixia.com',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
