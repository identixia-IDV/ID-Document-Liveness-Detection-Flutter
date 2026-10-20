import 'dart:io';
import 'dart:math' as math;
import 'dart:ui';

import 'package:image/image.dart' as img;

import '../result/result_parser.dart';

/// ID-1 card frame (ISO/IEC 7810, 85.6×53.98 mm ≈ 1.586, 86% × 72%).
Rect passportGuideRect(Size view) {
  if (view.width <= 0 || view.height <= 0) return Rect.zero;
  const ratio = 85.6 / 53.98;
  var fw = view.width * 0.86;
  var fh = fw / ratio;
  if (fh > view.height * 0.72) {
    fh = view.height * 0.72;
    fw = fh * ratio;
  }
  return Rect.fromLTWH(
    (view.width - fw) / 2,
    (view.height - fh) / 2,
    fw,
    fh,
  );
}

/// Cover-map [viewRect] onto an image the same way the preview fills the view.
Rect mapViewRectToImage(Rect viewRect, Size view, int imageW, int imageH) {
  final scale = math.max(view.width / imageW, view.height / imageH);
  final dx = (view.width - imageW * scale) / 2;
  final dy = (view.height - imageH * scale) / 2;
  final left = ((viewRect.left - dx) / scale).round().clamp(0, imageW - 1);
  final top = ((viewRect.top - dy) / scale).round().clamp(0, imageH - 1);
  final right = ((viewRect.right - dx) / scale).round().clamp(left + 1, imageW);
  final bottom = ((viewRect.bottom - dy) / scale).round().clamp(top + 1, imageH);
  return Rect.fromLTRB(
    left.toDouble(),
    top.toDouble(),
    right.toDouble(),
    bottom.toDouble(),
  );
}

/// Pixel size used to cover-map the overlay onto a still.
///
/// When the displayed preview aspect differs from the JPEG, map using the
/// preview aspect (center-sliced into the JPEG) so the cut matches the hole.
Size mappingImageSize(int imageW, int imageH, Size? preview) {
  if (preview == null || preview.width <= 1 || preview.height <= 1) {
    return Size(imageW.toDouble(), imageH.toDouble());
  }
  final displayed = preview.width > preview.height
      ? Size(preview.height, preview.width)
      : preview;
  final displayAspect = displayed.width / displayed.height;
  final imageAspect = imageW / imageH;
  if ((displayAspect - imageAspect).abs() < 0.01) {
    return Size(imageW.toDouble(), imageH.toDouble());
  }
  if (displayAspect > imageAspect) {
    return Size(imageW.toDouble(), imageW / displayAspect);
  }
  return Size(imageH * displayAspect, imageH.toDouble());
}

Rect cropRectForGuide(Size view, int imageW, int imageH, {Size? preview}) {
  if (view.width <= 1 || view.height <= 1 || imageW < 8 || imageH < 8) {
    return Rect.zero;
  }
  final map = mappingImageSize(imageW, imageH, preview);
  final mapW = map.width.round().clamp(1, imageW);
  final mapH = map.height.round().clamp(1, imageH);
  final ox = (imageW - mapW) / 2.0;
  final oy = (imageH - mapH) / 2.0;
  final guide = passportGuideRect(view);
  final visible = mapViewRectToImage(
    Rect.fromLTWH(0, 0, view.width, view.height),
    view,
    mapW,
    mapH,
  );
  final left = visible.left + visible.width * (guide.left / view.width);
  final top = visible.top + visible.height * (guide.top / view.height);
  final right = left + visible.width * (guide.width / view.width);
  final bottom = top + visible.height * (guide.height / view.height);
  return Rect.fromLTRB(
    (left + ox).clamp(0, imageW - 1),
    (top + oy).clamp(0, imageH - 1),
    (right + ox).clamp(1, imageW.toDouble()),
    (bottom + oy).clamp(1, imageH.toDouble()),
  );
}

img.Image _uprightPortrait(img.Image src) {
  if (src.width <= src.height) return src;
  return img.copyRotate(src, angle: 90);
}

/// Map locate corners (crop-image space) onto the on-screen guide rectangle.
List<Point>? mapCropCornersToGuide(
  List<Point> corners,
  double imageW,
  double imageH,
  Size view,
) {
  final guide = passportGuideRect(view);
  if (corners.length < 4 ||
      imageW <= 1 ||
      imageH <= 1 ||
      guide.width <= 1 ||
      guide.height <= 1) {
    return null;
  }
  return [
    for (final c in corners)
      Point(
        guide.left + c.x * guide.width / imageW,
        guide.top + (imageH - c.y) * guide.height / imageH,
      ),
  ];
}

/// Crop [path] to the on-screen guide rectangle. Null if the crop cannot be made.
///
/// [preview] is the displayed camera preview size (same FittedBox child as
/// `_coverPreview`). When its aspect differs from the JPEG, mapping uses the
/// preview aspect so the cut matches the overlay hole.
Future<String?> cropFileToGuide(String path, Size view, {Size? preview}) async {
  if (view.width <= 1 || view.height <= 1) return null;
  final bytes = await File(path).readAsBytes();
  final decoded = img.decodeImage(bytes);
  if (decoded == null) return null;
  final upright = _uprightPortrait(decoded);
  final src = cropRectForGuide(
    view,
    upright.width,
    upright.height,
    preview: preview,
  );
  if (src.width < 32 || src.height < 32) return null;
  final cropped = img.copyCrop(
    upright,
    x: src.left.round(),
    y: src.top.round(),
    width: src.width.round(),
    height: src.height.round(),
  );
  final out = File('${path}_guide.jpg');
  await out.writeAsBytes(img.encodeJpg(cropped, quality: 92));
  return out.path;
}
