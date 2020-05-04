import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'dart:ui' as ui;

import 'package:flutter/services.dart';
import 'package:createimageflutter/image_generator.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:image_gallery_saver/image_gallery_saver.dart';

class ImageGeneratorPage extends StatefulWidget {
  @override
  _ImageGeneratorPageState createState() => _ImageGeneratorPageState();
}

class _ImageGeneratorPageState extends State<ImageGeneratorPage> {
  ByteData _imgBytes;
  ui.Image _topImage;
  ui.Image _bottomImage;

  @override
  void initState() {
    super.initState();
    _loadImage('images/icon2.jpg').then((image) {
      setState(() {
        _topImage = image;
      });
    });
    _loadImage('images/bottom_text.jpg').then((image) {
      setState(() {
        _bottomImage = image;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;
    return Scaffold(
      backgroundColor: Colors.teal,
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.max,
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: <Widget>[
            Padding(
              padding: const EdgeInsets.all(12.0),
              child: RaisedButton(
                child: Text("Image generate"),
                onPressed: () {
                  _generate(screenWidth);
                },
              ),
            ),
            _imgBytes != null
                ? Container(
                child: Image.memory(
                  Uint8List.view(_imgBytes.buffer),
                  height: 500,
                ))
                : Container()
          ],
        ),
      ),
    );
  }

  /// 加载图片
  Future<ui.Image> _loadImage(String path) async {
    var data = await rootBundle.load(path);
    var codec = await ui.instantiateImageCodec(data.buffer.asUint8List());
    var info = await codec.getNextFrame();
    return info.image;
  }

  void _generate(double screenWidth) async {
    ByteData byteData = await ImageGenerator().generate(
        _topImage,
        _bottomImage,
        screenWidth,
        "90后海归硕士多次偷快递 压力太大只为看看里面是什么",
        "3月20日中午，一名年轻女子来取快递，3月20日中午，一名年轻女子来取快递，3月20日中午，一名年轻女子来取快递，3月20日中午，一名年轻女子来取快递，3月20日中午，一名年轻女子来取快递，3月20日中午，一名年轻女子来取快递，3月20日中午，一名年轻女子来取快递，3月20日中午，一名年轻女子来取快递，3月20日中午，一名年轻女子来取快递，3月20日中午，一名年轻女子来取快递，3月20日中午，一名年轻女子来取快递，3月20日中午，一名年轻女子来取快递，3月20日中午，一名年轻女子来取快递，3月20日中午，一名年轻女子来取快递，3月20日中午，一名年轻女子来取快递，3月20日中午，一名年轻女子来取快递，3月20日中午，一名年轻女子来取快递，1111111112222欧某问了她门牌号码并帮她找到了该住户的快递。但她离开后不久，此住户真正的物主来找快递未果，向欧某反映自己的快递丢失。欧某再次查找监控，11",
        "2019年7月1日 英山网");

    saveFile(byteData);

    setState(() {
      _imgBytes = byteData;
    });
  }

  saveFile(ByteData byteData) async {
    print("SaveImage!");
    Uint8List pngBytes = byteData.buffer.asUint8List();
    final result = await ImageGallerySaver.saveImage(pngBytes); //这个是核心的保存图片的插件
    print("result = $result");
    Fluttertoast.showToast(
        msg: "filePath = $result",
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.CENTER,
        timeInSecForIosWeb: 1,
        backgroundColor: Colors.yellow,
        textColor: Colors.black,
        fontSize: 16.0);
  }
}

