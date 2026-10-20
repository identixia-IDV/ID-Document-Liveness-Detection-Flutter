import 'package:document_reader_sdk/document_reader_sdk.dart';
import 'package:flutter/material.dart';

import '../core/utils/result_parser.dart';
import '../app/theme.dart';

class DocumentOverlay extends StatelessWidget {
  const DocumentOverlay({
    super.key,
    this.corners,
    this.locked = false,
    this.showFrame = true,
  });

  final List<Point>? corners;
  final bool locked;
  final bool showFrame;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _GuidePainter(
        corners: corners,
        locked: locked,
        showFrame: showFrame,
      ),
      child: const SizedBox.expand(),
    );
  }
}

class _GuidePainter extends CustomPainter {
  _GuidePainter({
    required this.corners,
    required this.locked,
    required this.showFrame,
  });

  final List<Point>? corners;
  final bool locked;
  final bool showFrame;

  @override
  void paint(Canvas canvas, Size size) {
    final dim = Paint()..color = const Color(0xCCE6E9EF);
    final clear = Paint()..blendMode = BlendMode.clear;
    final stroke = Paint()
      ..color = locked ? AppColors.accent : AppColors.muted
      ..style = PaintingStyle.stroke
      ..strokeWidth = locked ? 8 : 5
      ..strokeJoin = StrokeJoin.round;

    Path path;
    final found = corners;
    if (found != null && found.length >= 4) {
      path = Path()
        ..moveTo(found[0].x, found[0].y)
        ..lineTo(found[1].x, found[1].y)
        ..lineTo(found[2].x, found[2].y)
        ..lineTo(found[3].x, found[3].y)
        ..close();
    } else if (showFrame) {
      path = Path()
        ..addRRect(
          RRect.fromRectAndRadius(
            passportGuideRect(size),
            const Radius.circular(16),
          ),
        );
    } else {
      return;
    }

    canvas.saveLayer(Offset.zero & size, Paint());
    canvas.drawRect(Offset.zero & size, dim);
    canvas.drawPath(path, clear);
    canvas.restore();
    canvas.drawPath(path, stroke);
  }

  @override
  bool shouldRepaint(covariant _GuidePainter oldDelegate) {
    return oldDelegate.corners != corners ||
        oldDelegate.locked != locked ||
        oldDelegate.showFrame != showFrame;
  }
}
