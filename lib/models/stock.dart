import 'package:flutter/services.dart' show rootBundle;
import 'dart:convert';
import 'units.dart';
//import 'package:intl/intl_browser.dart';

import '../models/bapiret.dart';
import '../models/files.dart';
import '../models/sap.dart';

import '../globals.dart' as globals;

class Stock {
  String matnr;
  String werks;
  String lgort;
  String charg;
  double menge;
  String meins;
  DateTime vfdat;

  Stock(
      {this.matnr, this.werks, this.lgort, this.charg, this.menge, this.meins, this.vfdat});

  factory Stock.fromJson(Map<String, dynamic> json) {
    return new Stock(
        matnr: json['matnr'] as String,
        werks: json['werks'] as String,
        lgort: json['lgort'] as String,
        charg: json['charg'] as String,
        menge: json['menge'] as double,
        vfdat: DateTime.parse(json['vfdat']),
        meins: json['meins'] as String);
  }
}

class StockData {
  String matnr;
  String werks;
  String maktx;
  String meins;
  DateTime datum;
  bool xchar;

  List<Stock> stockList;
  List<Units> unitsList;

  int    returnCode;
  String returnMssg;

  static StockData buffer;

  StockData({
    this.matnr,
    this.werks,
    this.maktx,
    this.meins,
    this.xchar,
    this.datum,
    this.stockList,
    this.unitsList,
    this.returnCode,
    this.returnMssg,
  });

  factory StockData.fromJson(Map<String, dynamic> json) {
    List<Stock> stockList = new List<Stock>();
    List<Units> unitsList = new List<Units>();
    //List<Bapiret> bapiretList = new List<Bapiret>();

    json['stock'].forEach((i) {
      stockList.add(new Stock.fromJson(i));
    });
    json['units'].forEach((i) {
      unitsList.add(new Units.fromJson(i));
    });
    //json['bapiret'].forEach((i) {
    //  bapiretList.add(new Bapiret.fromJson(i));
    //});

    return new StockData(
        matnr: json['matnr'] as String,
        werks: json['werks'] as String,
        maktx: json['maktx'] as String,
        meins: json['meins'] as String,
        xchar: json['xchar'] as bool,
        datum: DateTime.parse(json['datum']),
        stockList: stockList,
        unitsList: unitsList,
        returnCode: 0, 
        returnMssg: '' 
    );
  }

  static Future<String> _loadAsset() async {
    return await rootBundle.loadString("resources/data/stock_data.json");
  }

  static Future<StockData> getStockData(String matnr, {String werks}) async {
    final List<StockData> listData = [];
  
    StockData stockData;
    String rawData = '';
    
    if (globals.demoModus == true) {
      //get JSON data from asset/file
      if (matnr == '600-100') {
        try {
          rawData = await _loadAsset();
        } catch (e) {
          print("getStockData from asset/file failed");
        }
      } else {
        stockData = new StockData();
        stockData.returnCode = 1;
        stockData.returnMssg = 'no data found';
        return stockData;
      }
    } else {
      //get JSON data via HTTP (from SAP)
      print("get data from SAP");
      //get JSON data via HTTP (from SAP)
      RequestStock requestStock = new RequestStock();
      requestStock.matnr = matnr;
      requestStock.werks = werks;
      requestStock.datum = DateTime.now();  //Test
      if (requestStock.werks == null || requestStock.werks == '')
        requestStock.werks = globals.plant;
      if (requestStock.werks == null)
        requestStock.werks = '';
      
      String json = jsonEncode(requestStock.toJson());

      SAP sap = new SAP();
      await sap.requestToSAP("get_stock", "0", json);
      if( sap.returnCode == 0) {
        rawData = sap.returnData;
      } else {
        StockData stockData = new StockData();
        stockData.returnCode = 1;
        stockData.returnMssg = sap.returnMssg;
        return stockData;
      }
    }
    //Decode JSON data
    final mapData = jsonDecode(rawData);
    for (Map i in mapData) {
      stockData = StockData.fromJson(i);
      stockData.returnCode = 0;
      listData.add(stockData);
    }
    //Store data to buffer
    Units.setUnits(stockData.unitsList);
    StockData.setBuffer(stockData);
    //
    return listData[0];
  }

  static void setBuffer(StockData stockData) {
    buffer = stockData;
  }

  static StockData getBuffer() {
    return buffer;
  }
}

class RequestStock {
  String matnr; 
  String werks; 
  DateTime datum;

  RequestStock({this.matnr, this.werks, this.datum});

  factory RequestStock.fromJson(Map<String, dynamic> json) {
    return new RequestStock(
      matnr: json['matnr'] as String,
      werks: json['werks'] as String,
      datum: DateTime.parse(json['datum']), 
    );
  }
  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'matnr': matnr,
      'werks': werks,
      'datum': datum.toIso8601String(),
    };
  }
}