import 'package:flutter/material.dart';
import 'package:preferences/preferences.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:path_provider/path_provider.dart';
import 'package:intl/intl.dart';
import 'package:validators/validators.dart' as validator;
import 'package:geolocator/geolocator.dart'; //permissions needed!!

import '../helpers/translations.dart';
import '../globals.dart' as globals;

//*******************
class Helpers {    
//*******************
  /*---------------------------------------------------------------------------------*/
  // Double in String umwandeln - mit Berücksichtigung DezimalStellen und Komma
  /*---------------------------------------------------------------------------------*/
  static String double2String(double input, {int decim = 3}) {
    String output;
    NumberFormat f;
    if (globals.decimSep == "Komma" || globals.decimSep == "123.456,789") {
      f = new NumberFormat.currency(
          locale: "eu", symbol: "", decimalDigits: decim);
    } else {
      f = new NumberFormat.currency(
          locale: 'en_US', symbol: "", decimalDigits: decim);
    }
    output = f.format(input).trim();
    return output;

  }

  /*---------------------------------------------------------------------------------*/
  // String in double umwandeln, mit Berücksichtigung DezimalStellen und Komma
  /*---------------------------------------------------------------------------------*/
  static double string2Double(String input) {
    String output = input;
    if (globals.decimSep == "Komma" || globals.decimSep == "123.456,789") {
      output = output.replaceAll(".", "#");
      output = output.replaceAll(",", ".");
      output = output.replaceAll("#", ",");
    }
    //print("string2Double "+output);
    return double.parse(output);
  }

  /*---------------------------------------------------------------------------------*/
  // Prüfung auf double - mit Berücksichtigung des Dezimal-Kommas
  /*---------------------------------------------------------------------------------*/
  static bool isFloat(String str) {
    RegExp _floatPoint = new RegExp(
        r'^(?:-?(?:[0-9]+))?(?:\.[0-9]*)?(?:[eE][\+\-]?(?:[0-9]+))?$');
    RegExp _floatComma = new RegExp(
        r'^(?:-?(?:[0-9]+))?(?:\,[0-9]*)?(?:[eE][\+\-]?(?:[0-9]+))?$');
    if (globals.decimSep == "Komma" || globals.decimSep == "123.456,789") {
      return _floatComma.hasMatch(str);
    } else {
      return _floatPoint.hasMatch(str);
    }
  }
  static bool isInt(String str) {
    if (validator.isInt(str)) {
      return true;
    } else {
      return false;
    }
  }
  /*---------------------------------------------------------------------------------*/
  // Preferences in die globalen Variablen laden (auch nach Änderung der Settings)
  /*---------------------------------------------------------------------------------*/
  static void loadGlobals() {

    if (PrefService != null) {
      globals.userName   = PrefService.getString("user_display_name");
      globals.userLang   = PrefService.getString("user_language");
      globals.formatDate = PrefService.getString("user_format_date");
      globals.decimSep   = PrefService.getString("user_dec_sep");
      globals.deviceId   = PrefService.getString("device_id");
      globals.printer    = PrefService.getString("printer");
      //globals.demoModus  = PrefService.getBool("demo_modus");
      if (globals.userName == null || globals.userName == '')
        globals.userName = globals.loginName;
      if (globals.loginName.toLowerCase()  == 'demo'    ||
          globals.loginName.toLowerCase()  == 'demorf' ) {
        globals.demoModus = true;
      } else {
        globals.demoModus = false;
      }
      if (globals.userLang == null ) {
        globals.userLang = 'DE';
      }
      globals.loginLang  = globals.userLang;

      globals.hostSAP    = PrefService.getString("sap_host");
      globals.serviceSAP = PrefService.getString("sap_service");
      globals.portSAP    = PrefService.getString("sap_port");
      globals.clientSAP  = PrefService.getString("sap_mandant");
      globals.usrSAP     = PrefService.getString("sap_user");
      globals.pwdSAP     = PrefService.getString("sap_password");
      globals.sapAnonym  = PrefService.getBool("sap_anonym");
      globals.loginSAP   = PrefService.getBool("login_with_sap");
      globals.loginSec   = PrefService.getBool("login_with_sec");
      globals.loginLoc   = PrefService.getBool("login_with_loc");
      globals.locUser1   = PrefService.getString("local_user1");
      globals.locUser2   = PrefService.getString("local_user2");

      globals.plant      = PrefService.getString("sap_plant");
      globals.lgnum      = PrefService.getString("sap_lgnum");
    } else {
      print(">>> loadGlobals - not initialized !!!");
    }
    //print("loadGlobals - loginSAP:"+globals.loginSAP.toString());
    if (globals.decimSep == null || globals.decimSep == "") {
      globals.decimSep = "123.456,789";
    }
    if (globals.formatDate == null || globals.formatDate == "") {
      globals.formatDate = 'TT.MM.JJJJ';
    }
    if (globals.userLang == null ) {
      globals.userLang = globals.loginLang = 'DE';
    }
    //in den globalen Preferences speichern, die zur Anmeldung benötigt werden
    _storeGlobalPreferences();

    //ApplicationDirectory schon vorab bestimmen
    _setApplicationDirectory();

  }
  /*---------------------------------------------------------------------------------*/
  // Application Directory vorab bestimmen 
  /*---------------------------------------------------------------------------------*/
  static void _setApplicationDirectory() async {
    final directory = await getApplicationDocumentsDirectory();
    globals.appDocPath = directory.path;
  }
  /*---------------------------------------------------------------------------------*/
  // Preferences speichern, die schon bei der Anmeldung benötigt werden 
  /*---------------------------------------------------------------------------------*/
  static void _storeGlobalPreferences() async {
    SharedPreferences prefs;
    prefs = await SharedPreferences.getInstance();
    if (prefs != null) {
      prefs.setString('LNG', globals.loginLang);
      prefs.setBool('login_with_sap', globals.loginSAP);
      prefs.setBool('login_with_sec', globals.loginSec);
      prefs.setBool('login_with_loc', globals.loginLoc);
      prefs.setString('local_user1', globals.locUser1);
      prefs.setString('local_user2', globals.locUser2);
      prefs.setString('sap_host', globals.hostSAP);
      prefs.setString('sap_port', globals.portSAP);
      prefs.setString('sap_service', globals.serviceSAP);
      prefs.setString('sap_mandant', globals.clientSAP);
      prefs.setString('sap_user', globals.usrSAP);
      prefs.setString('sap_password', globals.pwdSAP);
    }
  }
  /*---------------------------------------------------------------------------------*/
  // Get the current geo-location 
  /*---------------------------------------------------------------------------------*/
   static Future<void> getCurrentLocation() async {

    globals.passLatitude  = 0.0;
    globals.passLongitude = 0.0;

    final Geolocator geolocator = Geolocator()..forceAndroidLocationManager = true;
        
    GeolocationStatus geolocationStatus =
        await geolocator.checkGeolocationPermissionStatus();
    if (geolocationStatus == GeolocationStatus.disabled) {
      print(">> geolocationStatus = disabled");
      return;
    } 

    await geolocator
        .getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high)
        .then((Position position) {
          globals.passLatitude  = position.latitude;
          globals.passLongitude = position.longitude;
        }).catchError((e) {
          print(e);
          return;
      });

    //print("Helpers.getCurrentLocation: "+globals.passLatitude.toString()+" / "+globals.passLongitude.toString());
  }

  /*---------------------------------------------------------------------------------*/
  // Formatter
  /*---------------------------------------------------------------------------------*/
  static String formatDate(DateTime dateTime, {bool long:false}) {
    DateFormat dateFormat;
    if (globals.formatDate == "TT.MM.JJJJ") {
      dateFormat = DateFormat('dd.MM.yyyy');
      if (long) dateFormat = DateFormat('dd.MM.yyyy - HH:mm');
    } else {
      dateFormat = DateFormat('MM/dd/yyyy');
      if (long) dateFormat = DateFormat('MM/dd/yyyy - hh:mm');
    }
    return dateFormat.format(dateTime);
  }

  static String formatTime(DateTime dateTime, {bool seconds:false}) {
    DateFormat dateFormat;
    dateFormat = DateFormat('HH:mm');
    if (seconds) dateFormat = DateFormat('HH:mm:ss');
    return dateFormat.format(dateTime);
  }

  static String formatInt(int zahl) {
    NumberFormat numberFormat;
    if (globals.decimSep == "Komma" || globals.decimSep == "123.456,789") {
      numberFormat = NumberFormat("#,###", "eu");
    } else {
      numberFormat = NumberFormat("#,###", "en_Us");
    }
    return numberFormat.format(zahl);
  }

} //class Helpers

//*******************
class H {
//*******************
  /*---------------------------------------------------------------------------------*/
  // Text aus dem Repository holen 
  /*---------------------------------------------------------------------------------*/
  static String getText(BuildContext context,
         String input, {String v1:"", String v2:"", String suffix:"" }) {
  
    if (input == null) input = '';
    if (v1 == null) v1 = '';
    if (v2 == null) v2 = '';

    if (globals.userLang != globals.lastLang) {
      globals.lastLang = globals.userLang;
      AppLocalizations.of(context).load();
    }
    String _output = AppLocalizations.of(context).translate(input);
    if (_output == null) {
      _output = '';
    }
    if (_output == "") {
      _output = input;
    }
    _output = _output.replaceFirst("&", v1);
    if (v2 != "") {
      _output = _output.replaceFirst("&", v2);
    }
    //print("lang:"+globals.userLang+",input:"+input+",output:"+_output);
    _output = _output.trim();
    if (suffix != '') _output = _output+suffix;
    return _output;

  } //getText
  /*---------------------------------------------------------------------------------*/
  // Text aus dem Repository holen
  /*---------------------------------------------------------------------------------*/
  String concat(BuildContext context,
                String text1, String text2, {String sep:''}) {

    String str1 = getText(context, text1);
    String str2 = getText(context, text2);
    return str1+sep+str2;

  }
  /*---------------------------------------------------------------------------------*/
  // Message ausgeben
  /*---------------------------------------------------------------------------------*/
  static void message(BuildContext context,
      {String msgId: "",
       String msgTy: "S",
       String msgV1: "",
       String msgV2: ""}) {
    String _output;
    if (msgId != null && msgId != "") {
      _output = getText(context, msgId);
    }
    if (_output == "") {
      _output = msgV1;
    }
    if (msgV1 != null && msgV1 != "") {
      _output = _output.replaceFirst("&", msgV1);
      if (msgV2 != null && msgV2 != "") {
        _output = _output.replaceFirst("&", msgV2);
      }
    }
    if (_output == "") {
      _output = msgId + "???";
    }
    var color = Colors.green;
    switch (msgTy) {
      case "E":
        color = Colors.red;
        break;
      case "W":
        color = Colors.yellow;
        break;
      case "I":
        color = Colors.blue;
        break;
      case "S":
        color = Colors.green;
        break;
    }
    showToast(context, _output, color: color);

  } //Message 

  /*---------------------------------------------------------------------------------*/
  // Toast
  /*---------------------------------------------------------------------------------*/
  static void showToast(BuildContext context, String message,
      {Color color = Colors.blue}) {

    final scaffold = Scaffold.of(context);
    scaffold.showSnackBar(
      SnackBar(
        content: new Text(message),
        backgroundColor: color,
      ),
    );
  } //Toast

  /*---------------------------------------------------------------------------------*/
  // Simple Alert
  /*---------------------------------------------------------------------------------*/
  static void simpleAlert(BuildContext ctxt,
         String title, [String mess, String msgty]) {

    if (title == null) title = '';
    if (mess == null) mess = '';
    if (msgty == null) msgty = '';

  showDialog(
    context: ctxt,
    builder: (BuildContext ctxt) {
      return AlertDialog(
        title: new Text(title),
        content: 
          mess == ''
          ? Container()
          : Row(children: <Widget>[
            Container(
              padding: EdgeInsets.only(right: 10),
              child: msgty == 'E'
              ? Icon(Icons.error_outline, color:Colors.red)
              : msgty == 'W'
                ? Icon(Icons.warning, color:Colors.orange)
                : Icon(Icons.done, color:Colors.green),
            ),
            Expanded(
              child: Text(mess)),
          ],),
        actions: <Widget>[
          FlatButton(
            child: new Icon(Icons.done),
            onPressed: () {
              Navigator.of(ctxt).pop();
            },
          ),
        ],
      );
    });
  }

  /*---------------------------------------------------------------------------------*/ 
  // Popup To Confirm
  /*---------------------------------------------------------------------------------*/
  static Future<String> confirmDialog(BuildContext context, String title, String content) async {

    if(title == null) title = '';
    if(content == null) content = '';

    return showDialog(
      context: context,
      child: new AlertDialog(
        title: new Text(title),
        content: new Text(content),
        actions: <Widget>[
          new FlatButton(
            onPressed: () => Navigator.of(context).pop('N'),
            child: new Text(H.getText(context, 'no'),
                        style: globals.styleTextBigBlue),
          ),
          new FlatButton(
            onPressed: () => Navigator.of(context).pop('Y'),
            child: new Text(H.getText(context, 'yes'),
                    style: globals.styleTextBigBlue),
            ),
        ],
      ),
    ) ??
    'N'; 
  }

} //class H

/*---------------------------------------------------------------------------------*/
// Klasse Parameter: Standard Struktur Key/Value
/*---------------------------------------------------------------------------------*/
class Parameter {
  String key;
  String val;
  Parameter(this.key, this.val);
}

/*---------------------------------------------------------------------------------*/
// Klasse CustomPopupMenu: Struktur für PopupMenu
/*---------------------------------------------------------------------------------*/
class CustomPopupMenu {
  CustomPopupMenu({this.title: '', 
                  this.icon, 
                  this.text,
                  this.action: '', 
                  this.divider:   false, 
                  this.invisible: false, 
                  this.disabled:  false});
  String title;
  IconData icon;
  String action;
  String text;
  bool divider   = false;
  bool invisible = false;
  bool disabled  = false;
}