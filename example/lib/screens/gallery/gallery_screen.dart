import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../app/router.dart';
import '../../app/theme.dart';
import '../../services/document_service.dart';

class GalleryScreen extends StatefulWidget {
  const GalleryScreen({super.key});

  @override
  State<GalleryScreen> createState() => _GalleryScreenState();
}

class _GalleryScreenState extends State<GalleryScreen> {
  final _picker = ImagePicker();
  final _docs = DocumentService();
  String? front;
  String? back;
  bool busy = false;
  String error = '';

  Future<void> _pick(bool isFront) async {
    final picked = await _picker.pickImage(source: ImageSource.gallery);
    if (picked == null) return;
    setState(() {
      if (isFront) {
        front = picked.path;
      } else {
        back = picked.path;
      }
      error = '';
    });
  }

  Future<void> _recognize() async {
    if (front == null || busy) return;
    setState(() {
      busy = true;
      error = '';
    });
    try {
      final json = await _docs.recognize(front!, back: back);
      if (!mounted) return;
      goResult(context, json);
    } catch (e) {
      setState(() => error = '$e');
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  String _name(String? path) {
    if (path == null) return '';
    return path.split(RegExp(r'[\\/]')).last;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Gallery')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _tile(
              'Front',
              front,
              _name(front).isEmpty ? 'Front image' : _name(front),
              () => _pick(true),
              () => setState(() => front = null),
            ),
            const SizedBox(height: 14),
            _tile(
              'Back',
              back,
              _name(back).isEmpty ? 'Back image' : _name(back),
              () => _pick(false),
              () => setState(() => back = null),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              height: 56,
              child: FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.accent,
                  foregroundColor: Colors.white,
                  disabledBackgroundColor: AppColors.accent.withValues(alpha: 0.45),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppColors.radiusPill),
                  ),
                ),
                onPressed: (front == null || busy) ? null : _recognize,
                child: busy
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : const Text(
                        'Recognize',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                      ),
              ),
            ),
            if (error.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 14),
                child: Text(error, style: const TextStyle(color: AppColors.statusError)),
              ),
          ],
        ),
      ),
    );
  }

  Widget _tile(
    String label,
    String? path,
    String filename,
    VoidCallback onPick,
    VoidCallback onClear,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SizedBox(
          height: 176,
          child: Material(
            color: AppColors.surface,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppColors.radiusCard),
              side: const BorderSide(color: AppColors.border),
            ),
            clipBehavior: Clip.antiAlias,
            child: InkWell(
              onTap: onPick,
              child: Stack(
                children: [
                  if (path == null)
                    Center(
                      child: Text(
                        label,
                        style: const TextStyle(color: AppColors.muted, fontSize: 15),
                      ),
                    )
                  else
                    Positioned.fill(child: Image.file(File(path), fit: BoxFit.contain)),
                  if (path != null)
                    Positioned(
                      top: 8,
                      right: 8,
                      child: GestureDetector(
                        onTap: onClear,
                        child: Container(
                          width: 28,
                          height: 28,
                          decoration: BoxDecoration(
                            color: AppColors.surface,
                            border: Border.all(color: AppColors.border),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: const Icon(Icons.close, size: 16, color: AppColors.muted),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          filename,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(color: AppColors.muted, fontSize: 12),
        ),
      ],
    );
  }
}
