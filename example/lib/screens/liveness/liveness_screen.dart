import 'dart:io';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../app/router.dart';
import '../../app/theme.dart';
import '../../core/constants/capture.dart';
import '../../widgets/document_overlay.dart';
import '../../widgets/loading/busy_overlay.dart';
import '../document/document_controller.dart';

class LivenessScreen extends StatefulWidget {
  const LivenessScreen({super.key});

  @override
  State<LivenessScreen> createState() => _LivenessScreenState();
}

class _LivenessScreenState extends State<LivenessScreen> {
  late final DocumentController controller;
  String? error;
  bool _navigated = false;

  @override
  void initState() {
    super.initState();
    controller = DocumentController();
    _boot();
  }

  Future<void> _boot() async {
    final status = await Permission.camera.request();
    if (!status.isGranted) {
      setState(() => error = 'Camera permission is required');
      return;
    }
    try {
      await controller.initCamera();
      controller.addListener(_onUpdate);
      setState(() {});
    } catch (e) {
      setState(() => error = '$e');
    }
  }

  void _onUpdate() {
    if (!mounted) return;
    setState(() {});
    final json = controller.lastResultJson;
    if (!_navigated && json != null && json.isNotEmpty) {
      _navigated = true;
      goResult(context, json);
    }
  }

  @override
  void dispose() {
    controller.removeListener(_onUpdate);
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (error != null) {
      return Scaffold(
        backgroundColor: AppColors.bg,
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(error!, style: const TextStyle(color: AppColors.text)),
              TextButton(
                onPressed: () => context.pop(),
                child: const Text('Close'),
              ),
            ],
          ),
        ),
      );
    }

    final cam = controller.camera;
    if (cam == null || !cam.value.isInitialized) {
      return const Scaffold(
        backgroundColor: Colors.black,
        body: Center(child: CircularProgressIndicator(color: AppColors.accent)),
      );
    }

    final locked =
        controller.scorePct >= highThreshold && controller.corners != null;
    final pad = MediaQuery.paddingOf(context);

    return Scaffold(
      backgroundColor: Colors.black,
      body: LayoutBuilder(
        builder: (context, constraints) {
          controller.updateViewSize(
            Size(constraints.maxWidth, constraints.maxHeight),
          );
          return Stack(
            fit: StackFit.expand,
            children: [
              _coverPreview(cam),
              DocumentOverlay(
                corners: controller.corners,
                locked: locked,
              ),
              Positioned(
                top: pad.top + 16,
                left: 16,
                right: 16,
                child: Row(
                  children: [
                    Material(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(24),
                      clipBehavior: Clip.antiAlias,
                      child: InkWell(
                        onTap: () => context.pop(),
                        child: const SizedBox(
                          width: 48,
                          height: 48,
                          child: Center(
                            child: Text(
                              '✕',
                              style: TextStyle(
                                color: AppColors.text,
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Positioned(
                top: pad.top + 76,
                left: 0,
                right: 0,
                child: Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      border: Border.all(color: AppColors.border),
                      borderRadius: BorderRadius.circular(AppColors.radiusPill),
                    ),
                    child: Text(
                      '${controller.scorePct}%',
                      style: const TextStyle(
                        color: AppColors.text,
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ),
              // TEMPORARY CROP PREVIEW — start
              // Delete only this block when asked to "Delete temporary preview".
              if (controller.latestPath != null)
                Positioned(
                  right: 12,
                  bottom: pad.bottom + 16 + 64 + 16 + 48,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      const Text(
                        'Crop preview (temporary)',
                        style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(height: 4),
                      Container(
                        width: 148,
                        height: 104,
                        color: Colors.black54,
                        foregroundDecoration: BoxDecoration(
                          border: Border.all(color: const Color(0xFFF59E0B), width: 2),
                        ),
                        child: Image.file(
                          File(controller.latestPath!),
                          key: ValueKey(controller.latestPath),
                          fit: BoxFit.contain,
                          errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                        ),
                      ),
                    ],
                  ),
                ),
              // TEMPORARY CROP PREVIEW — end
              Positioned(
                left: 24,
                right: 24,
                bottom: pad.bottom + 16 + 64 + 16,
                child: Text(
                  controller.hint,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.white, fontSize: 15),
                ),
              ),
              Positioned(
                left: 20,
                right: 20,
                bottom: pad.bottom + 16,
                child: SizedBox(
                  height: 64,
                  child: FilledButton(
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.accent,
                      foregroundColor: Colors.white,
                      disabledBackgroundColor:
                          AppColors.accent.withValues(alpha: 0.4),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(32),
                      ),
                    ),
                    onPressed: (!controller.captureEnabled || controller.busy)
                        ? null
                        : () => controller.onCapture(),
                    child: controller.busy
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                          )
                        : const Text(
                            'Capture',
                            style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
                          ),
                  ),
                ),
              ),
              if (controller.busy) const BusyOverlay(),
            ],
          );
        },
      ),
    );
  }

  Widget _coverPreview(CameraController cam) {
    final preview = cam.value.previewSize;
    if (preview == null) return CameraPreview(cam);
    return ClipRect(
      child: FittedBox(
        fit: BoxFit.cover,
        child: SizedBox(
          width: preview.height,
          height: preview.width,
          child: CameraPreview(cam),
        ),
      ),
    );
  }
}
