import 'dart:ui' as ui;
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';

class ImageGenerator {
  generate(ui.Image topImg, ui.Image bottomImg, double screenWidth,
      String title, String content, String time) async {
    print("screenWidth = $screenWidth");

    final recorder = ui.PictureRecorder();

    ui.Paint paint = new Paint()
      ..isAntiAlias = true
      ..filterQuality = ui.FilterQuality.high;
    double rectTextTop = 150; // 文本显示矩形顶部距离图片最顶部的距离
    double textMargin = 20; // 文字间间距，包括距离矩形边框左右间距
    double pagePadding = 22; // 页面内容左右边距
    double bottomHeight = 160; // 底部区域高度
    // 获取标题高度等信息
    double textMaxWidth = screenWidth - pagePadding * 2 - textMargin * 2;
    TextPainter titlePainter = new TextPainter(
        text: TextSpan(
          text: title,
          style: TextStyle(
              fontSize: 20,
              color: Colors.black87,
              fontWeight: FontWeight.bold,
              height: 1.2),
        ),
        textDirection: TextDirection.ltr)
      ..layout(maxWidth: textMaxWidth);
    var titleHeight = titlePainter.height;
    print("titleHeight =  $titleHeight");

    TextPainter contentPainter = new TextPainter(
        text: TextSpan(
          text: content,
          style: TextStyle(
              fontSize: 16,
              color: Colors.black87,
              fontWeight: FontWeight.normal,
              height: 1.5),
        ),
        textDirection: TextDirection.ltr)
      ..layout(maxWidth: textMaxWidth);
    var contentHeight = contentPainter.height;
    print("contentheight = $contentHeight");

    double textHeight = titleHeight + contentHeight + 3 * textMargin;
    double bottom = textHeight + rectTextTop + textMargin * 2 + bottomHeight;
    double shadowBottom = textHeight + rectTextTop;
    print("bottom = $bottom");
    if (bottom < 300) {
      bottom = 300;
    }
    // 利用矩形左边的X坐标、矩形顶部的Y坐标、矩形右边的X坐标、矩形底部的Y坐标确定矩形的大小和位置
    var canvasRect = Rect.fromLTWH(0, 0, screenWidth, bottom);
    final canvas = Canvas(recorder, canvasRect);
    // 0. 绘制背景
    canvas.drawColor(Color(0xfffefefe), BlendMode.color);

    // 1. 绘制图片
    canvas.drawImageRect(
        topImg,
        Rect.fromLTWH(0, 0, topImg.width.toDouble(), topImg.height.toDouble()),
        Rect.fromLTWH(
            0, 0, screenWidth, topImg.height * screenWidth / topImg.width),
        paint);

    // 2. 绘制时间
    new TextPainter(
        text: TextSpan(
          text: time,
          style: TextStyle(
              fontSize: 16,
              color: Colors.white,
              fontWeight: FontWeight.normal,
              height: 1.5),
        ),
        textDirection: TextDirection.ltr)
      ..layout(maxWidth: textMaxWidth)
      ..paint(canvas, Offset(pagePadding, rectTextTop - 40));

    // 2. 绘制矩形，先绘制矩形，否则文字被覆盖
    paint.color = Color(0x00ffffffff);
    var rrect = RRect.fromRectAndRadius(
        Rect.fromLTWH(pagePadding, rectTextTop, screenWidth - pagePadding * 2,
            textHeight),
        Radius.circular(6));

    var path = Path()
      ..moveTo(pagePadding, rectTextTop)
      ..lineTo(screenWidth - pagePadding, rectTextTop)
      ..lineTo(screenWidth - pagePadding, shadowBottom)
      ..lineTo(pagePadding, shadowBottom)
      ..close();
    canvas.drawShadow(path, Colors.black, 6, true);
    canvas.drawRRect(rrect, paint);

    // 3. 绘制文字
    titlePainter.paint(
        canvas, Offset(pagePadding + textMargin, rectTextTop + textMargin));
    contentPainter.paint(
        canvas,
        Offset(pagePadding + textMargin,
            rectTextTop + textMargin * 2 + titleHeight));

    double bottomTextWidth = screenWidth * 2 / 5; // 底部文案宽度
    double bottomTextTopMargin = bottomHeight * 2 / 5; // 底部文案距离上面文字间距

    canvas.drawImageRect(
        bottomImg,
        Rect.fromLTWH(
            0, 0, bottomImg.width.toDouble(), bottomImg.height.toDouble()),
        // height / width = h / sc
        Rect.fromLTWH(
            screenWidth * 2 / 5,
            shadowBottom + bottomTextTopMargin + 5,
            bottomTextWidth,
            bottomImg.height.toDouble() *
                bottomTextWidth /
                bottomImg.width.toDouble()),
        paint);
    // 绘制二维码
//    new QrCodeGenerator(data: "123456", version: 2).drawQrCode(
//        canvas, new Size(90, 90), 45, shadowBottom + bottomTextTopMargin);
    canvas.save();
    canvas.translate(45, shadowBottom + bottomTextTopMargin);
    QrPainter(data: "123456", version: 2).paint(canvas, Size(90, 90));
    canvas.restore();

    // 转换成图片
    final picture = recorder.endRecording();
    ui.Image img = await picture.toImage(screenWidth.toInt(), bottom.toInt());

    print('img的尺寸: $img');
    final byteData = await img.toByteData(format: ui.ImageByteFormat.png);
    return byteData;
  }
}

