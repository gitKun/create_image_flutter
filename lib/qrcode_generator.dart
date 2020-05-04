/*
import 'package:flutter/material.dart';
import 'package:flutter_platforms/generator/paint_cache.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'dart:ui' as ui;

// default color for the qr code pixels
const _qrDefaultColor = Color(0xff111111);
const _finderPatternLimit = 7;

class QrCodeGenerator {
  ui.Image topImage;
  ui.Image bottomImage;



  /// The QR code version.
  final int version; // the qr code version
  /// The error correction level of the QR code.
  final int errorCorrectionLevel; // the qr code error correction level
  /// The color of the squares.
  final Color color; // the color of the dark squares
  /// The color of the non-squares (background).
  @Deprecated(
      'You should us the background color value of your container widget')
  final Color emptyColor; // the other color
  /// If set to false, the painter will leave a 1px gap between each of the
  /// squares.
  final bool gapless;

  /// The image data to embed (as an overlay) in the QR code. The image will
  /// be added to the center of the QR code.
  ui.Image embeddedImage;

  /// Styling options for the image overlay.
  final QrEmbeddedImageStyle embeddedImageStyle;

  /// The base QR code data
  QrCode _qr;

  /// This is the version (after calculating) that we will use if the user has
  /// requested the 'auto' version.
  int _calcVersion;

  /// The size of the 'gap' between the pixels
  final double _gapSize = 0.25;

  /// Cache for all of the [Paint] objects.
  final _paintCache = PaintCache();

  QrCodeGenerator(
      {@required String data,
        @required this.version,
        this.errorCorrectionLevel = QrErrorCorrectLevel.L,
        this.color = _qrDefaultColor,
        this.emptyColor,
        this.gapless = false,
        this.embeddedImage,
        this.embeddedImageStyle}) {
    _init(data);
  }

  bool _hasAdjacentVerticalPixel(int x, int y, int moduleCount) {
    if (y + 1 >= moduleCount) return false;
    return _qr.isDark(y + 1, x);
  }

  bool _hasAdjacentHorizontalPixel(int x, int y, int moduleCount) {
    if (x + 1 >= moduleCount) return false;
    return _qr.isDark(y, x + 1);
  }

  Size _scaledAspectSize(
      Size widgetSize, Size originalSize, Size requestedSize) {
    if (requestedSize != null && !requestedSize.isEmpty) {
      return requestedSize;
    } else if (requestedSize != null && _hasOneNonZeroSide(requestedSize)) {
      final maxSide = requestedSize.longestSide;
      final ratio = maxSide / originalSize.longestSide;
      return Size(ratio * originalSize.width, ratio * originalSize.height);
    } else {
      final maxSide = 0.25 * widgetSize.shortestSide;
      final ratio = maxSide / originalSize.longestSide;
      return Size(ratio * originalSize.width, ratio * originalSize.height);
    }
  }

  bool _isFinderPatternPosition(int x, int y) {
    final isTopLeft = (y < _finderPatternLimit && x < _finderPatternLimit);
    final isBottomLeft = (y < _finderPatternLimit &&
        (x >= _qr.moduleCount - _finderPatternLimit));
    final isTopRight = (y >= _qr.moduleCount - _finderPatternLimit &&
        (x < _finderPatternLimit));
    return isTopLeft || isBottomLeft || isTopRight;
  }

  bool _hasOneNonZeroSide(Size size) => size.longestSide > 0;

  void _drawFinderPatternItem(
      FinderPatternPosition position,
      Canvas canvas,
      _PaintMetrics metrics,
      ) {
    final totalGap = (_finderPatternLimit - 1) * metrics.gapSize;
    final radius = ((_finderPatternLimit * metrics.pixelSize) + totalGap) -
        metrics.pixelSize;
    final strokeAdjust = (metrics.pixelSize / 2.0);
    final edgePos =
        (metrics.inset + metrics.innerContentSize) - (radius + strokeAdjust);
    Offset offset;
    if (position == FinderPatternPosition.topLeft) {
      offset =
          Offset(metrics.inset + strokeAdjust, metrics.inset + strokeAdjust);
    } else if (position == FinderPatternPosition.bottomLeft) {
      offset = Offset(metrics.inset + strokeAdjust, edgePos);
    } else {
      offset = Offset(edgePos, metrics.inset + strokeAdjust);
    }
    // configure the paints
    final outerPaint = _paintCache.firstPaint(QrCodeElement.finderPatternOuter,
        position: position);
    outerPaint.strokeWidth = metrics.pixelSize;
    outerPaint.color = color;
    final innerPaint = _paintCache.firstPaint(QrCodeElement.finderPatternInner,
        position: position);
    innerPaint.strokeWidth = metrics.pixelSize;
    innerPaint.color = emptyColor ?? Color(0x00ffffff);
    final dotPaint = _paintCache.firstPaint(QrCodeElement.finderPatternDot,
        position: position);
    dotPaint.color = color;
    final outerRect = Rect.fromLTWH(offset.dx, offset.dy, radius, radius);
    canvas.drawRect(outerRect, outerPaint);
    final innerRadius = radius - (2 * metrics.pixelSize);
    final innerRect = Rect.fromLTWH(offset.dx + metrics.pixelSize,
        offset.dy + metrics.pixelSize, innerRadius, innerRadius);
    canvas.drawRect(innerRect, innerPaint);
    final gap = metrics.pixelSize * 2;
    final dotSize = radius - gap - (2 * strokeAdjust);
    final dotRect = Rect.fromLTWH(offset.dx + metrics.pixelSize + strokeAdjust,
        offset.dy + metrics.pixelSize + strokeAdjust, dotSize, dotSize);
    canvas.drawRect(dotRect, dotPaint);
  }

  void _drawImageOverlay(
      Canvas canvas, Offset position, Size size, QrEmbeddedImageStyle style) {
    final paint = Paint()
      ..isAntiAlias = true
      ..filterQuality = FilterQuality.high;
    if (style != null) {
      if (style.color != null) {
        paint.colorFilter = ColorFilter.mode(style.color, BlendMode.srcATop);
      }
    }
    final srcSize =
    Size(embeddedImage.width.toDouble(), embeddedImage.height.toDouble());
    final src = Alignment.center.inscribe(srcSize, Offset.zero & srcSize);
    final dst = Alignment.center.inscribe(size, position & size);
    canvas.drawImageRect(embeddedImage, src, dst, paint);
  }

  void _init(String data) {
    if (!QrVersions.isSupportedVersion(version)) {
      throw QrUnsupportedVersionException(version);
    }
    // configure and make the QR code data
    final validationResult = QrValidator.validate(
      data: data,
      version: version,
      errorCorrectionLevel: errorCorrectionLevel,
    );
    if (!validationResult.isValid) {
      throw validationResult.error;
    }
    _qr = validationResult.qrCode;
    _calcVersion = _qr.typeNumber;
    _initPaints();
  }

  void _initPaints() {
    // Cache the pixel paint object. For now there is only one but we might
    // expand it to multiple later (e.g.: different colours).
    _paintCache.cache(
        Paint()..style = PaintingStyle.fill, QrCodeElement.codePixel);
    // Cache the empty pixel paint object. Empty color is deprecated and will go
    // away.
    _paintCache.cache(
        Paint()..style = PaintingStyle.fill, QrCodeElement.codePixelEmpty);
    // Cache the finder pattern painters. We'll keep one for each one in case
    // we want to provide customization options later.
    for (final position in FinderPatternPosition.values) {
      _paintCache.cache(Paint()..style = PaintingStyle.stroke,
          QrCodeElement.finderPatternOuter,
          position: position);
      _paintCache.cache(Paint()..style = PaintingStyle.stroke,
          QrCodeElement.finderPatternInner,
          position: position);
      _paintCache.cache(
          Paint()..style = PaintingStyle.fill, QrCodeElement.finderPatternDot,
          position: position);
    }
  }

  /// 绘制二维码
  drawQrCode(Canvas canvas, Size size, double dx, double dy) async {
    canvas.save();
    canvas.translate(dx, dy);
    // if the widget has a zero size side then we cannot continue painting.
    if (size.shortestSide == 0) {
      print("[QR] WARN: width or height is zero. You should set a 'size' value "
          "or nest this painter in a Widget that defines a non-zero size");
      return;
    }
    final paintMetrics = _PaintMetrics(
      containerSize: size.shortestSide,
      moduleCount: _qr.moduleCount,
      gapSize: (gapless ? 0 : _gapSize),
    );
    // draw the finder pattern elements
    _drawFinderPatternItem(FinderPatternPosition.topLeft, canvas, paintMetrics);
    _drawFinderPatternItem(
        FinderPatternPosition.bottomLeft, canvas, paintMetrics);
    _drawFinderPatternItem(
        FinderPatternPosition.topRight, canvas, paintMetrics);
    double left;
    double top;
    final gap = !gapless ? _gapSize : 0;
    // get the painters for the pixel information
    final pixelPaint = _paintCache.firstPaint(QrCodeElement.codePixel);
    pixelPaint.color = color;
    Paint emptyPixelPaint;
    if (emptyColor != null) {
      emptyPixelPaint = _paintCache.firstPaint(QrCodeElement.codePixelEmpty);
      emptyPixelPaint.color = emptyColor;
    }
    for (var x = 0; x < _qr.moduleCount; x++) {
      for (var y = 0; y < _qr.moduleCount; y++) {
        // draw the finder patterns independently
        if (_isFinderPatternPosition(x, y)) continue;
        final paint = _qr.isDark(y, x) ? pixelPaint : emptyPixelPaint;
        if (paint == null) continue;
        // paint a pixel
        left = paintMetrics.inset + (x * (paintMetrics.pixelSize + gap));
        top = paintMetrics.inset + (y * (paintMetrics.pixelSize + gap));
        var pixelHTweak = 0.0;
        var pixelVTweak = 0.0;
        if (gapless && _hasAdjacentHorizontalPixel(x, y, _qr.moduleCount)) {
          pixelHTweak = 0.5;
        }
        if (gapless && _hasAdjacentVerticalPixel(x, y, _qr.moduleCount)) {
          pixelVTweak = 0.5;
        }
        final squareRect = Rect.fromLTWH(
          left,
          top,
          paintMetrics.pixelSize + pixelHTweak,
          paintMetrics.pixelSize + pixelVTweak,
        );
        canvas.drawRect(squareRect, paint);
      }
    }
    if (embeddedImage != null) {
      final originalSize = Size(
        embeddedImage.width.toDouble(),
        embeddedImage.height.toDouble(),
      );
      final requestedSize =
      embeddedImageStyle != null ? embeddedImageStyle.size : null;
      final imageSize = _scaledAspectSize(size, originalSize, requestedSize);
      final position = Offset(
        (size.width - imageSize.width) / 2.0,
        (size.height - imageSize.height) / 2.0,
      );
      // draw the image overlay.
      _drawImageOverlay(canvas, position, imageSize, embeddedImageStyle);
    }
    canvas.restore();
  }
}

class _PaintMetrics {
  _PaintMetrics(
      {@required this.containerSize,
        @required this.gapSize,
        @required this.moduleCount}) {
    _calculateMetrics();
  }

  final int moduleCount;
  final double containerSize;
  final double gapSize;
  double _pixelSize;

  double get pixelSize => _pixelSize;
  double _innerContentSize;

  double get innerContentSize => _innerContentSize;
  double _inset;

  double get inset => _inset;

  void _calculateMetrics() {
    final gapTotal = (moduleCount - 1) * gapSize;
    var pixelSize = (containerSize - gapTotal) / moduleCount;
    _pixelSize = (pixelSize * 2).roundToDouble() / 2;
    _innerContentSize = (_pixelSize * moduleCount) + gapTotal;
    _inset = (containerSize - _innerContentSize) / 2;
  }
}
*/
