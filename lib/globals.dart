library delivery_service.globals;

import 'package:flutter/material.dart';
import 'dart:async';

// global data
bool isLoggedIn = false;
String loginName = '';
String loginPwd  = '';
String loginLang = '';
DateTime loginDate = DateTime.now();
String userName  = '';
String userLang  = '';
String lastLang  = '';
String formatDate  = '';  // TT.MM.JJJJ + MM/DD/YYY
String decimSep  = ''; 
String hostSAP   = '';   
String serviceSAP  = '';   
String portSAP   = '';   
String clientSAP = '';   
String usrSAP    = '';
String pwdSAP    = '';
String deviceId  = '';
String printer   = '';
String locUser1  = '';
String locUser2  = '';
String plant     = '';
String lgnum     = '';
String appDocPath = '';  

bool   sapAnonym = false; //Anmeldung im SAP anonym (User im Service hinterlegt)
bool   loginSAP  = false; //Anmeldung an der App mit dem SAP-User 
bool   loginSec  = false; //Anmeldung an der App mit dem Sekundär-User (Prüfung im SAP)
bool   loginLoc  = false; //Anmeldung an der App mit dem lokalen Benutzer
bool   demoModus = false;
String prefPrefix = 'set_';

// Current document
String docNum   = '';
String docItem  = '';
String docType  = '';
String docStat  = '';

String currentTourNo  = '';
String currentDrivNo  = '';
String currentDelvNo  = '';
int    currentDlvIndex = 0;
String currentTourStat = '';  
String currentDelvStat = '';
String lastReturnMssg = ''; // Übertragung an Backend
int    lastReturnCode = 0;  // Übertragung an Backend
String lastEvent = '';      // Übertragung an Backend
String lastDateTime = '';   // Übertragung an Backend
bool   toBeSynchronized = false;  // Übertragung erforderlich 
DateTime lastSubTableLoad;  

// Application data (set/get)
String matnr = '';

// Icons
const myIcons = <String, IconData> {
  'add_box': Icons.add_box,
  'add_shopping_cart': Icons.add_shopping_cart,
  'build': Icons.build,
  'view_module': Icons.view_module,
  'perm_scan_wifi': Icons.perm_scan_wifi,
  'local_printshop': Icons.local_printshop, 
  'local_shipping': Icons.local_shipping, 
  'input': Icons.input,
  'launch': Icons.launch,
  'check_box': Icons.check_box,
  'compare_arrows': Icons.compare_arrows,
  'move_to_inbox': Icons.move_to_inbox,
};
// Layout
const Color primaryColor = Colors.blue;
const Color actionColor  = Colors.blue;

TextStyle styleHeaderTitle = TextStyle(color: Colors.white,fontSize: 22.0, height: 1.7);
TextStyle styleHeaderSubTitle = TextStyle(color: Colors.white, fontSize: 16.0, height: 1.3);
TextStyle styleBottomButton = TextStyle(fontSize: 18.0, color: Colors.white);
TextStyle styleLabelDisplay = TextStyle(fontSize: 16.0, color: Colors.black54);
TextStyle styleDisplayField = TextStyle(fontSize: 18.0, fontWeight: FontWeight.bold);
TextStyle styleInputField = TextStyle(fontSize: 18.0, fontWeight: FontWeight.bold, color: Colors.black87);
TextStyle styleLabelTextField = TextStyle(fontSize: 16.0, color: Colors.black87);
TextStyle styleTableTextHeader = TextStyle(fontSize: 16.0, fontWeight: FontWeight.bold);
TextStyle styleTableTextHighlight  = TextStyle(fontSize: 16.0, color: primaryColor, fontWeight: FontWeight.bold);
TextStyle styleTableTextNormal     = TextStyle(fontSize: 16.0, color: Colors.black87);
TextStyle styleTableTextNormalBlue = TextStyle(fontSize: 16.0, color: primaryColor);
TextStyle styleTableTextNormalBold = TextStyle(fontSize: 16.0, fontWeight: FontWeight.bold, color: Colors.black87);
TextStyle styleTextNormal     = TextStyle(fontSize: 16.0, color: Colors.black87);
TextStyle styleTextNormalBlue = TextStyle(fontSize: 16.0, color: primaryColor);
TextStyle styleTextNormalBoldBlue = TextStyle(fontSize: 16.0, color: primaryColor, fontWeight: FontWeight.bold);
TextStyle styleTextNormalBold = TextStyle(fontSize: 16.0, fontWeight: FontWeight.bold, color: Colors.black87);
TextStyle styleTextBig        = TextStyle(fontSize: 18.0, color: Colors.black87);
TextStyle styleTextBigBlue    = TextStyle(fontSize: 18.0, fontWeight: FontWeight.bold, color: primaryColor );
TextStyle styleTextBigBold    = TextStyle(fontSize: 18.0, fontWeight: FontWeight.bold, color: Colors.black87 );
TextStyle styleFlatButton = TextStyle(fontSize: 16.0, color: primaryColor, fontWeight: FontWeight.bold);

const double heightBottomButton = 50.0;
const double heightRow = 50.0;
const double tableCellHeight = 25.0;

// Document Types
const String documentType_tour      = 'X';
const String documentType_delivery  = 'L';
const String documentType_transfer  = 'T';
const String documentType_purchaseOrder  = 'B';
const String documentType_customerOrder  = 'K';

const String tourStat_initial     = '';
const String tourStat_scheduled   = 'A';
const String tourStat_started     = 'B';
const String tourStat_completed   = 'C';
const String tourStat_interrupted = 'D';

const String delvStat_initial     = '';
const String delvStat_inProcess   = 'B';
const String delvStat_completed   = 'C';
const String delvStat_postponed   = 'D';

// Pass Data 
int passKmStand  = 0; 
int passCounter  = 0;
double passLatitude  = 0.0;
double passLongitude = 0.0;
String waers;
bool changeData = false;
bool changeSign = false;

// Events
const String event_tour_start     = '01';
const String event_tour_reset     = '02';
const String event_tour_ende      = '03';
const String event_tour_break     = '04';
const String event_tour_continue  = '05';
const String event_delv_start     = '11';
const String event_delv_reset     = '12';
const String event_delv_ende      = '13';
const String event_break_start    = '21';
const String event_break_ende     = '22';

const String reason_break         = '1';
const String reason_traffic_jam   = '2';
const String reason_accident      = '3';
const String reason_emergency     = '4';
const String reason_waiting       = '5';