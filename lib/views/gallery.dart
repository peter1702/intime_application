import 'package:flutter/material.dart';
import 'package:flutter_swiper/flutter_swiper.dart';
import 'dart:io';

import '../models/tour.dart';
import '../helpers/helpers.dart';
import '../globals.dart' as globals;

class GalleryPage extends StatefulWidget {
  GalleryPage({Key key, this.delivery}) : super(key: key);

  Delivery delivery;

  @override
  _GalleryPageState createState() => new _GalleryPageState();
}

class _GalleryPageState extends State<GalleryPage> {

  Delivery delivery;
  List<Images> displayImages = [];
  Map loopControl = {};

  _initializeData() {
    delivery = widget.delivery;
    int j = 0;
    int i = 0;
    delivery.imageList.forEach((element) {
      //var i = delivery.imageList.indexOf(element);
      List<DelvItem> itemList = delivery.itemList.where((x) => x.posnr == element.posnr).toList();
      if (itemList.length > 0) {
        DelvItem item = itemList[0];
        i = delivery.itemList.indexOf(item);
      } else {
        i = 999;
      }
      if (element.changeKz != 'D') {
        displayImages.add(element);
        loopControl[j] = i;
      }
    });
  }
  Future<bool> _exitApp(BuildContext context) {
    Navigator.pop(context, true);
  }

  // Initialization
  @override
  void initState() {
    super.initState();
    _initializeData();
  }

  @override
  Widget build(BuildContext context) {
    return new Scaffold(
      appBar: new AppBar(
        title: new Text(H.getText(context, 'images')),
        backgroundColor: globals.primaryColor,
        leading: new IconButton(
          icon: new Icon(Icons.arrow_back_ios, color: Colors.white),
          onPressed: () {
            _exitApp(context);
          }),
      ),
      body:  new Swiper(
        itemBuilder: (BuildContext context,int index){
          return Column(children: <Widget>[
            Text(H.getText(context,'item')+': '+displayImages[index].posnr),
            Text(loopControl[index] < 999 ? delivery.itemList[loopControl[index]].maktx : ''),
            Text(H.getText(context,'note')+': '+displayImages[index].comment),
            Expanded(child:
              new Image(image: FileImage(File(displayImages[index].fileName)),fit: BoxFit.contain,),
            ),
          ],);
        },
        itemCount: displayImages.length,
        pagination: new SwiperPagination(),
        control: new SwiperControl(color: globals.primaryColor),
      ),
    );
  }
}