import 'dart:ui';

import 'package:document_reader_sdk/document_reader_sdk.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('passportGuideRect is ID-1 (~1.586), 86% wide, centered', () {
    const view = Size(1000, 2000);
    final guide = passportGuideRect(view);
    expect(guide.width, closeTo(860, 0.01));
    expect(guide.height, closeTo(860 * 53.98 / 85.6, 0.01));
    expect(guide.left, closeTo((1000 - guide.width) / 2, 0.01));
    expect(guide.top, closeTo((2000 - guide.height) / 2, 0.01));
  });

  test('mapCropCornersToGuide places crop-space corners on the guide', () {
    const view = Size(1000, 2000);
    final guide = passportGuideRect(view);
    final mapped = mapCropCornersToGuide(
      [Point(0, 0), Point(100, 0), Point(100, 50), Point(0, 50)],
      100,
      50,
      view,
    );
    expect(mapped, isNotNull);
    expect(mapped![0].x, closeTo(guide.left, 0.5));
    expect(mapped[2].x, closeTo(guide.right, 0.5));
  });

  test('mapViewRectToImage cover-maps the guide onto the still', () {
    const view = Size(100, 200);
    final guide = passportGuideRect(view);
    final src = mapViewRectToImage(guide, view, 400, 800);
    expect(src.left, greaterThanOrEqualTo(0));
    expect(src.top, greaterThanOrEqualTo(0));
    expect(src.right, lessThanOrEqualTo(400));
    expect(src.bottom, lessThanOrEqualTo(800));
    expect(src.width, greaterThanOrEqualTo(32));
    expect(src.height, greaterThanOrEqualTo(32));
  });

  test('overlay guide mapped onto a still equals the crop rect', () {
    const view = Size(390, 760);
    const imageW = 1080;
    const imageH = 1920;
    final overlay = passportGuideRect(view);
    final mapped = mapViewRectToImage(overlay, view, imageW, imageH);
    final crop = cropRectForGuide(view, imageW, imageH);
    expect(crop.left, closeTo(mapped.left, 1));
    expect(crop.top, closeTo(mapped.top, 1));
    expect(crop.width, closeTo(mapped.width, 1));
    expect(crop.height, closeTo(mapped.height, 1));
  });

  test('JPEG vs preview aspect uses displayed preview for the crop', () {
    const view = Size(390, 760);
    const jpegW = 2000;
    const jpegH = 4000;
    const preview = Size(1080, 1920);
    final overlay = passportGuideRect(view);
    final map = mappingImageSize(jpegW, jpegH, preview);
    expect(map.width / map.height, closeTo(preview.width / preview.height, 0.02));
    final mapped = mapViewRectToImage(
      overlay,
      view,
      map.width.round(),
      map.height.round(),
    );
    final crop = cropRectForGuide(view, jpegW, jpegH, preview: preview);
    expect(crop.left, closeTo(mapped.left + (jpegW - map.width) / 2, 2));
    expect(crop.top, closeTo(mapped.top + (jpegH - map.height) / 2, 2));
    final sameAspect = cropRectForGuide(view, jpegW, jpegH);
    expect(
      (crop.left - sameAspect.left).abs() > 0.5 ||
          (crop.top - sameAspect.top).abs() > 0.5 ||
          (crop.width - sameAspect.width).abs() > 0.5,
      isTrue,
    );
    expect(crop.width, lessThan(sameAspect.width + 1));
  });

  test('guide crop is the overlay fraction of the cover-visible still', () {
    const view = Size(390, 760);
    const imageW = 1080;
    const imageH = 1920;
    final guide = passportGuideRect(view);
    final visible = mapViewRectToImage(
      const Rect.fromLTWH(0, 0, 390, 760),
      view,
      imageW,
      imageH,
    );
    final crop = cropRectForGuide(view, imageW, imageH);
    expect(crop.width / visible.width, closeTo(guide.width / view.width, 0.02));
    expect(crop.height / visible.height, closeTo(guide.height / view.height, 0.02));
  });
}
