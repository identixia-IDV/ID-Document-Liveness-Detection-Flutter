import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../app/theme.dart';
import '../../models/sdk_status.dart';
import '../../services/sdk_service.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final sdk = context.watch<SdkService>();
    final ready = sdk.ready;
    final license = 'License: ${sdk.licenseVerdict}';
    final readyLabel = ready
        ? 'Ready'
        : sdk.status.phase == SdkPhase.loading
            ? '…'
            : sdk.statusMessage;

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: _chip(license.isEmpty ? 'License' : license),
                  ),
                  const SizedBox(width: 10),
                  _chip(readyLabel, bold: true),
                ],
              ),
              const SizedBox(height: 16),
              Expanded(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(minHeight: 248),
                  child: Material(
                    color: AppColors.accent,
                    borderRadius: BorderRadius.circular(AppColors.radiusCard),
                    clipBehavior: Clip.antiAlias,
                    child: InkWell(
                      onTap: () => _guard(
                        context,
                        ready,
                        sdk.statusMessage,
                        () => context.push('/camera'),
                      ),
                      child: const Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.photo_camera, color: Colors.white, size: 72),
                            SizedBox(height: 16),
                            Text(
                              'Camera',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 22,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                height: 124,
                child: Row(
                  children: [
                    Expanded(
                      child: _smallTile(
                        'Gallery',
                        Icons.photo_library,
                        () => _guard(
                          context,
                          ready,
                          sdk.statusMessage,
                          () => context.push('/gallery'),
                        ),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: _smallTile(
                        'About',
                        Icons.info_outline,
                        () => context.push('/about'),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  static Widget _chip(String text, {bool bold = false}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(AppColors.radiusPill),
      ),
      child: Text(
        text,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          color: AppColors.text,
          fontSize: 13,
          fontWeight: bold ? FontWeight.w700 : FontWeight.w500,
        ),
      ),
    );
  }

  static Widget _smallTile(String title, IconData icon, VoidCallback onTap) {
    return Material(
      color: AppColors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: const BorderSide(color: AppColors.border),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: AppColors.accent, size: 36),
            const SizedBox(height: 10),
            Text(
              title,
              style: const TextStyle(
                color: AppColors.text,
                fontSize: 15,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }

  static void _guard(
    BuildContext context,
    bool ready,
    String status,
    VoidCallback go,
  ) {
    if (!ready) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(status.isEmpty ? 'SDK is not ready' : status)),
      );
      return;
    }
    go();
  }
}
