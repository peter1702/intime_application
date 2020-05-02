import '../helpers/helpers.dart';
import 'dart:convert';

class Units {
  String meins; //Mengeneinheit
  String bezei; //Bezeichnung 
  double umrez; //Zähler
  double umren; //Nenner
  int    decim; //Decimals

  static List<Units> buffer = [];

  Units({this.meins, this.bezei, this.umrez, this.umren, this.decim});

  factory Units.fromJson(Map<String, dynamic> json) {
    buffer = [];
    return new Units(
        meins: json['meins'] as String,
        bezei: json['bezei'] as String,
        umrez: json['umrez'] as double,
        umren: json['umren'] as double,
        decim: json['decim'] as int);
  }
  
  Map<String, dynamic> toJsonMap(Units unit) {
    var mapData = new Map<String, dynamic>();
    mapData["meins"]    = unit.meins;
    mapData["bezei"]    = unit.bezei;
    mapData["umrez"]    = unit.umrez;
    mapData["umren"]    = unit.umren;
    mapData["decim"]    = unit.decim;

    return mapData;
  }

  String toJson (Units unit) {
    var mapData = toJsonMap(unit);
    String json = jsonEncode(mapData);
    return json;
  }

  static void setUnits(List<Units> units) {
    buffer = units;
  }

  static List<Units> getUnits() {
    return buffer;
  }

  static double convertUnit(String newUnit, String oldUnit, double quantity) {
    double newQuantity = 0.0;
    double umren = 1.0;
    double umrez = 1.0;
    if (newUnit == oldUnit) {
      return quantity;
    }
    List<Units> tUnits = getUnits();
    if (tUnits.isEmpty) {
      print(">> convertUnit "+"Tabelle Units ist leer!");
      return quantity;
    }
    final int index = tUnits.indexWhere((Units el) => el.meins == newUnit);
    if(tUnits[index].meins == newUnit){
      umren = tUnits[index].umren;
      umrez = tUnits[index].umrez;
    }
    if (umren == 0) {
      umren = 1.0;
    }
    if (umrez == 0) {
      umrez = 1.0;
    }
    newQuantity = (quantity * umrez) / umren;
    return newQuantity;
  }

  static String convertUnit2String(String newUnit, String oldUnit, double quantity) {
    double newQuantity = convertUnit(newUnit, oldUnit, quantity);
    List<Units> tUnits = getUnits();

    if (tUnits != null && !tUnits.isEmpty) {
      final int index = tUnits.indexWhere((Units el) => el.meins == newUnit);
      return Helpers.double2String(newQuantity, decim: tUnits[index].decim);
    } else {
      print("convertUnit2String" + ">> Unit-Tabelle ist leer!");
      return newQuantity.toString();
    }
  }
}