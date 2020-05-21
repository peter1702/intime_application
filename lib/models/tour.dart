import 'package:flutter/services.dart' show rootBundle;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'dart:convert';
import 'dart:async';
import 'dart:io' as Io;

import '../globals.dart' as globals;
import '../helpers/helpers.dart';
import '../models/sap.dart';
import '../models/units.dart';
import '../models/files.dart';

/* ****************************************************************************** */
// Class Tour                                                                     */
/* ****************************************************************************** */
class Tour {

  String routno; // Tour-Nummer
  String drivno; // Fahrt
  String descr; // Beschreibung
  String driver; // Fahrer
  String driver2; // Beifahrer
  String kfzKz; // KFZ-Kennzeichen 
  DateTime creation; // Anlage Datum & Zeit
  DateTime startTime; // Start
  DateTime endeTime;  // Ende
  DateTime syncTime;  // Letzte Synchronisation
  String tourStat; // Status der Tour
  String changeKz; // Änderungskennzeichen I,U,D + S=Sync
  int returnCode;
  String returnMssg;
  int countDelv;
  int openDelv;
  int closedDelv;
  int startKM; 
  int endeKM;

  List<Delivery> delvList = []; // Lieferungen zur Tour
  List<Events> eventList = [];  // Ereignisse zur Tour

  // Timer für Datenübertragung im Background 
  static Timer timer;
  static bool  timerActive  = false; // 
  static bool  timerStop    = false; // 
  static int   timerRetries = 0;     // 
  static int   timerMaxRetries = 10; // 
  static int   timerInterval   = 120; // in seconds


  Tour({
      this.routno,
      this.drivno,
      this.descr,
      this.driver,
      this.driver2,
      this.kfzKz,
      this.creation,
      this.startTime,
      this.endeTime,
      this.syncTime,
      this.tourStat,
      this.returnCode,
      this.returnMssg,
      this.changeKz,
      this.countDelv,
      this.openDelv,
      this.closedDelv,
      this.startKM, 
      this.endeKM,
      this.delvList,
      this.eventList,
    });

  // ------------------------------------------------------------------------------- //
  // Tourdaten aus den JSON Daten aufbauen
  // ------------------------------------------------------------------------------- //
  factory Tour.fromJson(Map<String, dynamic> json) {

    List<Delivery> delvList = new List<Delivery>();
    List<Events> eventList = new List<Events>();

    int cntOpen = 0;
    int cntClosed = 0;
    int cntDelv = 0;

    if ( json['routno'] == null ) {
      Tour tourFehl = new Tour();
      tourFehl.routno = '';
      tourFehl.drivno = '';
      tourFehl.returnCode = 1;
      tourFehl.returnMssg = 'no data received';
      return tourFehl;
    }

    try {
      json["delivery"].forEach((i) {
        delvList.add(new Delivery.fromJson(i));
        if (delvList[cntDelv].delvStat == '') {
          cntOpen++;
        }
        if (delvList[cntDelv].delvStat == globals.delvStat_completed) {
          cntClosed++;
        }
        cntDelv++;
      });
    } catch (e) {
      print("found no deliveries");
    }
    try {
      json["event"].forEach((i) {
        eventList.add(new Events.fromJson(i));
      });
    } catch (e) {
      //print("found no events");
    }


    return new Tour(
      routno: json['routno'] as String,
      drivno: json['drivno'] as String,
      descr: json['descr'] as String,
      driver: json['driver'] as String,
      driver2: json['driver2'] as String,
      kfzKz: json['kfzkz'] == null ? '' : json['kfzkz'] as String,
      tourStat: json['tourstat'] == null ? '' : json['tourstat'] as String,
      creation: json['creation'] == null ? new DateTime(1900) : DateTime.parse(json['creation']),
      startTime: json['starttime'] == null ? new DateTime(1900) : DateTime.parse(json['starttime']),
      endeTime: json['endetime'] == null ? new DateTime(1900) : DateTime.parse(json['endetime']),
      syncTime: json['synctime'] == null ? new DateTime(1900) : DateTime.parse(json['synctime']),
      changeKz: json['changekz'] == null ? '' : json['changekz'] as String,
      startKM: json['startkm'] == null ? 0 : json['startkm'],
      endeKM: json['endekm'] == null ? 0 : json['endekm'],
      returnCode: 0,
      returnMssg: '',
      openDelv: cntOpen,
      closedDelv: cntClosed,
      countDelv: cntDelv,
      delvList: delvList,
      eventList: eventList
    );
  }
  // ------------------------------------------------------------------------------- //
  // Tourdaten in das JSON Format serialisieren 
  // ------------------------------------------------------------------------------- //
  String toJson(Tour tourData,{bool delta:false, String dlvno, bool head:false}) {
    
    var mapData = new Map<String, dynamic>();

    if (dlvno == null) {
      dlvno = '';
    }

    mapData["routno"] = tourData.routno;
    mapData["drivno"] = tourData.drivno;
    mapData["driver"] = tourData.driver;
    mapData["driver2"] = tourData.driver2;
    mapData["kfzkz"] = tourData.kfzKz;
    mapData["tourstat"] = tourData.tourStat;
    mapData["creation"] = tourData.creation.toIso8601String(); 
    mapData["starttime"] = tourData.startTime.toIso8601String(); 
    mapData["endetime"] = tourData.endeTime.toIso8601String(); 
    mapData["synctime"] = tourData.syncTime.toIso8601String(); 
    mapData["changekz"] = tourData.changeKz;
    mapData["startkm"] = tourData.startKM;
    mapData["endekm"] = tourData.endeKM;

    if ( delta == false ) {
      mapData["descr"] = tourData.descr;
      mapData["opendelv"] = tourData.openDelv;
      mapData["countdelv"] = tourData.countDelv;
      mapData["returncode"] = tourData.returnCode;
      mapData["returnMssg"] = tourData.returnMssg;
    }
    
    // Only Header?
    if ( head == false ) {
      // add deliveries
      Delivery delvObj = new Delivery();
      List<Map<String, dynamic>> delvMap =
        tourData.delvList.map((delv) => delvObj.toJsonMap(delv, delta:delta)).toList();
      
      if(delvMap.length > 0) {
        mapData["delivery"] = delvMap;
      }
    }
      
    // Add events
    List<Map<String, dynamic>> eventMap = [];
    for (Events evt in tourData.eventList) {
      if ( delta == false || evt.changeKz != '' ) {
        eventMap.add(evt.toJson());
      }
    }
    if(eventMap.length > 0) {
      mapData["event"] = eventMap; 
    }

    // Encode JSON
    String json = jsonEncode(mapData);
    return json;
  }

  // ------------------------------------------------------------------------------- //
  // Ermitteln der aktuellen Tourdaten vom Backend oder von der Sicherung. 
  // Vom Backend werden die Daten nur gelesen, wenn der Parameter "Force" gesetzt 
  // wurde. Dies ist der Fall, wenn die Daten manuell neu angefordert werden. 
  // Steht noch eine Synchronisierung App -> SAP an ("to be synchronized"), 
  // werden die Daten nicht geladen!
  // Können die Daten nicht vom SAP geladen werden, werden sie aus der 
  // Sicherung (File) gelesen. 
  // ------------------------------------------------------------------------------- //
  static Future<Tour> getCurrentTour(String routno, String drivno, {bool force:false}) async {
    
    if (globals.toBeSynchronized == null) {
      globals.toBeSynchronized = false;
    }
    if (routno == null) {
      routno = '';
      drivno = '';
    }
    print("getCurrentTour - to be synchronized: "+globals.toBeSynchronized.toString());

    Tour tourData;

    if (globals.demoModus == true) {
      tourData = await readFromFile(routno, drivno);
      print("readFromFile: "+routno);
    } else {
      //get JSON data via HTTP from SAP - if not available get data from file
      if (force && globals.toBeSynchronized == false) {

        tourData = await _requestFromSAP(routno, drivno);
        globals.lastReturnCode = tourData.returnCode;
        globals.lastReturnMssg = tourData.returnMssg;

        if (tourData.returnCode != 0) {
          print("SAP not available - read data from file");
          tourData = await readFromFile(routno, drivno);
          if (tourData.routno == null || tourData.routno != routno || tourData.drivno != drivno) {
            print("Data not available on file");
            tourData.routno = '';
            tourData.drivno = '';
          }
        } else if (tourData.routno == null || tourData.routno == '') { 
          globals.lastReturnMssg = tourData.returnMssg = 'no data received';
          globals.lastReturnCode = tourData.returnCode = 1;
          tourData.routno = '';
          tourData.drivno = '';
          print("keine Daten empfangen");
        } else {
          if (globals.lastSubTableLoad == null) {
            globals.lastSubTableLoad = DateTime(1900);
          }
          DateTime today = new DateTime.now();
          var diffDt = today.difference(globals.lastSubTableLoad);
          if ( diffDt.inDays > 0 ) {
            Fahrer.getFromBackend();
            StandardLeergut.getFromBackend();
            globals.lastSubTableLoad = today;
          }
        }

      } else {
        tourData = await readFromFile(routno, drivno);
        print("readFromFile: "+tourData.routno);
        if (tourData.routno == null || tourData.routno != routno || tourData.drivno != drivno) {
          tourData.routno = '';
          tourData.drivno = '';
        }
      }

      // es sind noch Daten an SAP zu übertragen 
      if(globals.toBeSynchronized == true && tourData.routno != '') {
        syncTour(tourData);
      }
    }
    // return Data
    return tourData;
  }
  // ------------------------------------------------------------------------------- //
  // Nächste Tour vom Backend ermitteln lassen
  // Dies ist nur dann möglich, wenn die vorherige Tour abgeschlossen wurde
  // ------------------------------------------------------------------------------- //
  static Future<Tour> getNextTour(String user) async {
    print("getNextTour - start");

    //final List<Tour> listTourData = [];
    Tour tourData;
    String rawData = '';
    String routno = '';
    String drivno = '';

    if (globals.demoModus == true) {

      //get JSON data from asset/file
      try {
        rawData = await _loadAsset();
        //print(rawData);
      } catch (e) {
        print("getNextTour from asset/file failed");
      }

      //Decode JSON data
      if (rawData == null || rawData == "") {
        tourData = new Tour();
        tourData.routno = '0';
        tourData.drivno = '0';
        tourData.returnCode = 1;
        tourData.returnMssg = 'no data received';
        return tourData;
      }
      final mapData = jsonDecode(rawData);
      tourData = Tour.fromJson(mapData);

    } else {

      //get JSON data via HTTP from SAP
      tourData = await _requestFromSAP(routno,drivno);
    }

    if (tourData.routno != null) {
      if (tourData.returnMssg == null || tourData.returnMssg == '') {
        tourData.returnMssg = 'ok';
      }
    } else {
      tourData = new Tour();
      tourData.routno = '0';
      tourData.drivno = '0';
      tourData.returnCode = 3;
      tourData.returnMssg = 'no data received';
    }

    // Hilfstabellen 1x täglich frisch laden
    if (globals.lastSubTableLoad == null) {
      globals.lastSubTableLoad = DateTime(1900);
    }
    DateTime today = new DateTime.now();
    if (globals.lastSubTableLoad == null) {
      globals.lastSubTableLoad = DateTime(1900);
    }
    var diffDt = today.difference(globals.lastSubTableLoad);
    if ( diffDt.inDays > 0 ) {
      Fahrer.getFromBackend();
      StandardLeergut.getFromBackend();
      globals.lastSubTableLoad = today;
    }

    // Initialize data
    _initializeData(tourData);

    // return Data
    return tourData;
  }
  // ------------------------------------------------------------------------------- //
  // Initialisieren der Daten nach dem Aufbau aus dem JSON-String 
  // ------------------------------------------------------------------------------- //
  static _initializeData(Tour tourData) {

    if (tourData.routno == null) {
      tourData.routno = '';
    }
    if (tourData.routno == '') {
      return;
    }

    if (tourData.driver == null)
      tourData.driver = '';
    if (tourData.driver2 == null)
      tourData.driver2 = '';
    if (tourData.startKM == null)
      tourData.startKM = 0;
    if (tourData.endeKM == null)
      tourData.endeKM = 0;

    if (tourData.delvList != null )  {
      for (Delivery delv in tourData.delvList) {
        if (delv.waers == null || delv.waers == '') delv.waers = 'EUR';
        if (globals.waers == null || globals.waers == '') globals.waers = delv.waers;
        if (delv.akonto == null)  delv.akonto = false;
        if (delv.barkz == null)   delv.barkz = false;
        if (delv.total == null)   delv.total = 0.0; 
        if (delv.betrag == null)  delv.betrag = 0.0; 
        if (delv.itemList != null) {
          for (DelvItem item in delv.itemList) {
            if (item.completed == null) item.completed = false;
            if (item.damaged   == null) item.damaged  = false;
            if (item.shortage  == null) item.shortage = false;
            if (item.mixed     == null) item.mixed    = false;
          }
        }
      }
    }

    globals.changeData = false; 
    switch (globals.waers.toUpperCase()) {
      case 'EUR': globals.waers = '€'; break;
      case 'USD': globals.waers = '\$'; break;
      case 'GBP': globals.waers = '£'; break;
      default: globals.waers = globals.waers;
    }
  }
  // ------------------------------------------------------------------------------- //
  // Sichern der Tourdaten auf dem Backend und Sicherung als File. 
  // Nach erfolgreicher Übertragung an SAP, werden die Änderungsflags zurückgesetzt.
  // Scheitert die Übertragung, wird das Flag "to be synchronized" gesetzt und 
  // der Timer gestartet, der die Übertragung zyklisch im Background probiert.
  // ------------------------------------------------------------------------------- //
  static _saveTour(
        Tour tourData, 
        {
        String event:'',
        String reason:'',
        String dlvno:'',
        bool head:false,
        bool sync:false
        }
        ) async {

    print("Save Tour - Begin") ;

    bool transmitFailed = false;

    if (tourData == null || tourData.routno == '') {
      print("Save Tour - routno ist nicht gefüllt!");
      return;
    }

    // Transmit the data to the backend
    if (globals.demoModus == false) {
      tourData.changeKz = 'S'; // to be synchronized with backend
      if (event != null && event != '') {
        await appendEvent(tourData, event, reason: reason, dlvno: dlvno);
      }
      await _transmitToSAP(tourData, dlvno:dlvno, head:head);
      if (tourData.returnCode == 0) {
        _resetChangeKz(tourData);
      } else {
        transmitFailed = true;
      }
    } 

    if (globals.demoModus == true) {
      if (event != null && event != '') {
        await appendEvent(tourData, event, reason: reason, dlvno: dlvno);
      }
      tourData.returnCode = 0;
      _resetChangeKz(tourData);
    }

    // Save current state in local file
    _saveToFile(tourData);

    // save last data 
    if (event == null) {
      event = '';
    }
    globals.lastReturnCode = tourData.returnCode;
    globals.lastReturnMssg = tourData.returnMssg;
    globals.lastDateTime = DateFormat('dd.MM.yyyy - hh:mm').format(DateTime.now());
    globals.lastEvent    = event;
    if (tourData.returnCode == 0) {
      globals.toBeSynchronized = false;
      _setPreferences();  
    }
    print("Save Tour - End");

    // if transmission failed, try it n times in the background 
    if (sync == false) {
      if (transmitFailed) {
        print("Transmission failed");
        if (timerActive) {
          //timerRetries = 0;
        } else {
          _startTimer(tourData);
        }
      } else if (timerActive) {
        timerStop = true;
      }
    }

  }
  // ------------------------------------------------------------------------------- //
  // Starten des Timers für die Übertragung von Daten im Background 
  // ------------------------------------------------------------------------------- //
  static void _startTimer(Tour tourData) async {

    print("startTimer - Timer is active: "+timerActive.toString());

    if(timerActive)
      return;
    timerStop = false;
    timerRetries = 0;
    timer = Timer.periodic(Duration(seconds: timerInterval), (timer) {
      timerActive = true;
      if(timerStop == true || globals.toBeSynchronized == false) {
        timer.cancel();
        timerActive = false;
        timerStop = false;
        print("Timer stopped");
      } else {
        timerRetries++;
        if (timerRetries >= timerMaxRetries) {
          timer.cancel();
          timerActive = false;
          timerStop = false;
          print("Timer stopped");
        }
        // do something
        print("Timer: "+ DateFormat('dd.MM.yyyy - hh:mm:ss').format(DateTime.now()) + " Retries: "+ timerRetries.toString());
        //print("DelvStat delivery "+tourData.delvList[3].dlvno+" = "+tourData.delvList[3].delvStat);
        //syncTour(tourData, timer:true);
      }
    });
  }

  // ------------------------------------------------------------------------------- //
  // Synchronisieren der Tourdaten (Übertragen nach SAP)
  // Die Funktion kann manuell aufgerufen werden, wenn das Kennzeichen 
  // "to be synchronized" gesetzt ist 
  // ------------------------------------------------------------------------------- //
  static Future<Tour> syncTour(Tour tourData, {bool timer:false}) async {
    await _saveTour(tourData, sync:true);
    return tourData;
  }

  // ------------------------------------------------------------------------------- //
  // Starten einer Tour.
  // Vor dem Start bewirkt die Methode "get next tour" nur, dass eine Tour vom 
  // Backend ermittelt wird und in der "Tourvorschau" angezeigt wird. Dies kann 
  // solange wiederholt werden, bis die Tour gestartet wurde. 
  // ------------------------------------------------------------------------------- //
  static Future<Tour> startTour(Tour tourData) async {

    String _oldRoutNo = globals.currentTourNo; 
    String _oldDrivNo = globals.currentDrivNo; 

    print("Start Tour - begin") ;
    tourData.tourStat     = globals.tourStat_started;
    tourData.startTime    = DateTime.now();
    tourData.changeKz     = 'U';
    
    globals.currentTourNo = tourData.routno;
    globals.currentDrivNo = tourData.drivno;
    globals.currentTourStat = tourData.tourStat;
    globals.toBeSynchronized = true;
    globals.currentDelvNo   = '';
    globals.currentDlvIndex = 0;
    globals.lastReturnCode = 0;
    globals.lastReturnMssg = '';

    _setPreferences();
    _saveTour(tourData, event:globals.event_tour_start, head:true);
    print("Start Tour - end") ;

    if (_oldRoutNo != null && _oldRoutNo != '') {
      if ( _oldRoutNo == tourData.routno && _oldDrivNo == tourData.drivno) {
        print("old Tour = new Tour");
      } else {
        deleteTour(_oldRoutNo, _oldDrivNo);
      }
    }

  }
  // ------------------------------------------------------------------------------- //
  // Abschluss der Tour
  // ------------------------------------------------------------------------------- //
  static Future<Tour> finishTour(Tour tourData) async {

    print("Finish Tour - begin") ;
    tourData.tourStat     = globals.tourStat_completed;
    tourData.endeTime    = DateTime.now();
    tourData.changeKz     = 'U';
    
    globals.currentTourNo = tourData.routno;
    globals.currentDrivNo = tourData.drivno;
    globals.currentTourStat = tourData.tourStat;
    globals.toBeSynchronized = true;
    globals.currentDelvNo   = '';
    globals.currentDlvIndex = 0;
    globals.lastReturnCode = 0;
    globals.lastReturnMssg = '';

    _setPreferences();
    _saveTour(tourData, event:globals.event_tour_ende, head:true);

    print("Finish Tour - end") ;
  }
  // ------------------------------------------------------------------------------- //
  // Zurücksetzen des Tour-Starts
  // Das ist nur möglich, wenn noch keine Lieferung bearbeitet wurde
  // ------------------------------------------------------------------------------- //
  static Future<Tour> resetTour(Tour tourData) async {

    tourData.tourStat     = globals.tourStat_initial;
    tourData.startTime    = DateTime(1900);
    tourData.changeKz     = 'U';

    globals.currentTourNo = tourData.routno;
    globals.currentDrivNo = tourData.drivno;
    globals.currentTourStat = tourData.tourStat;
    globals.toBeSynchronized = true;

    _setPreferences();
    _saveTour(tourData, event:globals.event_tour_reset, head:true);
  }
  // ------------------------------------------------------------------------------- //
  // Tour unterbrechen 
  // ------------------------------------------------------------------------------- //
  static Future<Tour> breakTour(Tour tourData, String reason, {String delvno:''}) async {

    tourData.tourStat     = globals.tourStat_interrupted;
    tourData.changeKz     = 'U';
    tourData.syncTime     = DateTime.now();
    globals.toBeSynchronized = true;
    globals.currentTourStat = tourData.tourStat;

    _setPreferences();
    _saveTour(tourData, event:globals.event_tour_break, reason:reason, dlvno:delvno, );
  }
  // ------------------------------------------------------------------------------- //
  // Tour nach Unterbrechung fortsetzen 
  // ------------------------------------------------------------------------------- //
  static Future<Tour> continueTour(Tour tourData, {String delvno:''}) async {

    tourData.tourStat     = globals.tourStat_started;
    tourData.changeKz     = 'U';
    globals.toBeSynchronized = true;
    globals.currentTourStat = tourData.tourStat;

    _setPreferences();
    _saveTour(tourData, event:globals.event_tour_continue, dlvno:delvno, head:true);
  }
  // ------------------------------------------------------------------------------- //
  // Starten der Entladung einer Lieferung 
  // ------------------------------------------------------------------------------- //
  static Future<Tour> startDelivery(Tour tourData, int dlvIndex) async {  

    print("Start Delivery") ;
    String _dlvNo = tourData.delvList[dlvIndex].dlvno;

    globals.toBeSynchronized = true;
    globals.currentDelvNo    = _dlvNo;
    globals.currentDlvIndex  = dlvIndex;

    tourData.delvList[dlvIndex].changeKz  = 'U';
    tourData.delvList[dlvIndex].startTime = DateTime.now();
    tourData.delvList[dlvIndex].delvStat  = globals.delvStat_inProcess;

    _setPreferences();
    _saveTour(tourData, event:globals.event_delv_start, dlvno: _dlvNo);
  }
  // ------------------------------------------------------------------------------- //
  // Abschluss einer Lieferung
  // ------------------------------------------------------------------------------- //
  static Future<Tour> finishDelivery(Tour tourData, int dlvIndex) async {  

    print("Finish Delivery") ;
    String _dlvNo = tourData.delvList[dlvIndex].dlvno;

    globals.toBeSynchronized = true;
    globals.currentDelvNo    = '';
    //globals.currentDlvIndex  = dlvIndex;

    tourData.delvList[dlvIndex].changeKz  = 'U';
    tourData.delvList[dlvIndex].endeTime = DateTime.now();
    tourData.delvList[dlvIndex].delvStat  = globals.delvStat_completed;

    _setPreferences();
    _saveTour(tourData, event: globals.event_delv_ende, dlvno: _dlvNo);
  }
  // ------------------------------------------------------------------------------- //
  // Sichern der Daten einer Lieferung auf dem Backend und als File
  // ------------------------------------------------------------------------------- //
  static Future<Tour> saveDelivery(Tour tourData, int dlvIndex) async {  

    print("Save Delivery") ; 
    String _dlvNo = tourData.delvList[dlvIndex].dlvno;

    globals.toBeSynchronized = true;
    globals.currentDelvNo    = _dlvNo;
    globals.currentDlvIndex  = dlvIndex;

    tourData.delvList[dlvIndex].changeKz  = 'U';

    _setPreferences();
    _saveTour(tourData, dlvno: _dlvNo);
  }
  // ------------------------------------------------------------------------------- //
  // Zurücksetzen des Entladungs-Starts einer Lieferung 
  // ------------------------------------------------------------------------------- //
  static Future<Tour> resetDelivery(Tour tourData, Delivery delivery) async {

    delivery.delvStat   = globals.delvStat_initial;
    delivery.startTime  = DateTime(1900);
    delivery.changeKz   = 'U';

    globals.currentDelvNo   = '';
    globals.currentDlvIndex = 0;
    globals.currentDelvStat = globals.delvStat_initial;
    globals.toBeSynchronized = true;

    _setPreferences();
    _saveTour(tourData, event: globals.event_delv_reset,dlvno:delivery.dlvno);
  }
  // ------------------------------------------------------------------------------- //
  // Merken wichtiger Tourdaten als preferences 
  // ------------------------------------------------------------------------------- //
  static _setPreferences() async {

    SharedPreferences prefs;

    prefs = await SharedPreferences.getInstance();

    if (prefs != null) {
      prefs.setString('currentTourNo', globals.currentTourNo);
      prefs.setString('currentDrivNo', globals.currentDrivNo);
      prefs.setString('currentTourStat', globals.currentTourStat);
      prefs.setString('currentDelvNo', globals.currentDelvNo);
      prefs.setInt('currentDlvIndex', globals.currentDlvIndex);
      prefs.setBool('toBeSynchronized', globals.toBeSynchronized);
      prefs.setString('lastReturnMssg', globals.lastReturnMssg);
      prefs.setInt('lastReturnCode', globals.lastReturnCode);
      prefs.setString('lastEvent', globals.lastEvent);
      prefs.setString('lastDateTime', globals.lastDateTime);
    }
  }
  // ------------------------------------------------------------------------------- //
  // Tourdaten löschen 
  // Das ist nur möglich für abgeschlossene Touren (erfolgt automatisch beim Starten
  // der nächsten Tour) - oder für die Demo-Tour
  // ------------------------------------------------------------------------------- //
  static deleteTour(String tourNo, String drivNo, {bool demo:false}) {

    if (tourNo == null) {
      tourNo = '';
    }
    if (tourNo == globals.currentTourNo || demo == true) {
      globals.currentTourNo = '';
      globals.currentDrivNo = '';
      globals.currentTourStat = '';
      globals.toBeSynchronized = false;
      globals.currentDelvNo   = '';
      globals.currentDlvIndex = 0;
      _setPreferences();
    }
    if (tourNo != '') {
      //String fileName = _getFileName(tourNo);
      //Files.deleteFile(fileName);
      reorgTour(tourNo, drivNo);
    }
  }
  // ------------------------------------------------------------------------------- //
  // Alle Änderungskennzeichen nach erfolgreicher Übertragung an SAP löschen 
  // ------------------------------------------------------------------------------- //
  static void _resetChangeKz(Tour tourData) {
    tourData.changeKz = '';
    tourData.delvList.forEach((delivery) {
      delivery.changeKz = '';
      delivery.signCustomerChangeKz = '';
      delivery.signDriverChangeKz = '';
      delivery.itemList.forEach((item) {
        item.changeKz = '';
      });
      delivery.lgutList.forEach((lgut) {
        lgut.changeKz = '';
      });
      delivery.imageList.forEach((image) {
        image.changeKz = '';
      });
    });
    tourData.eventList.forEach((event) {
      event.changeKz = '';
    });
  }

  // ------------------------------------------------------------------------------- //
  // Demo Tour laden 
  // ------------------------------------------------------------------------------- //
  static Future<String> _loadAsset() async {
    print("load from asset");
    return await rootBundle.loadString("resources/data/tour_data.json");
  }

  // ------------------------------------------------------------------------------- //
  // Filename für die Sicherung der Tour ermitteln 
  // ------------------------------------------------------------------------------- //
  static String _getFileName(String tourNo, String drivNo) {
    return 'tour_'+tourNo+'_'+drivNo;
  }

  // ------------------------------------------------------------------------------- //
  // Tourdaten auf dem mobilen Gerät als File sichern 
  // ------------------------------------------------------------------------------- //
  static void _saveToFile(Tour tourData) async {

    String fileName = _getFileName(tourData.routno, tourData.drivno);
    String rawData  = tourData.toJson(tourData);
    print("Save To File Begin") ;

    int result = await Files.writeToFile(fileName, rawData);
    print("Save To File End") ;

  }

  // ------------------------------------------------------------------------------- //
  // Tourdaten aus File lesen 
  // ------------------------------------------------------------------------------- //
  static Future<Tour> readFromFile(String tourNo, String drivNo) async {

    String fileName = _getFileName(tourNo, drivNo);
    String rawData  = await Files.readFromFile(fileName);
    final Map newMap = jsonDecode(rawData);
    return Tour.fromJson(newMap);
  }

  // ------------------------------------------------------------------------------- //
  // Reorganisieren der Tourdaten beim Löschen 
  // insbesondere Bilder löschen 
  // ------------------------------------------------------------------------------- //
  static reorgTour(String tourNo, String drivNo) async {

    print("Tour reorganisieren: "+tourNo);
    //print("Verzeichnis-Inhalt vorher....");
    //Files.directoryList();

    String fileName = _getFileName(tourNo, drivNo);
    String fileNameSign = '';
    Tour _tourDataOld = await readFromFile(tourNo, drivNo);
    int result = 0;

    if (_tourDataOld == null || _tourDataOld.routno == '')
      return; 

    for (Delivery delivery in _tourDataOld.delvList) {
      if(delivery.signCustomer != null && delivery.signCustomer == true) {
        fileNameSign = "sign_customer_" + delivery.dlvno + '.png';
        result = await Files.deleteFile(fileNameSign);
      }
      if(delivery.signDriver != null && delivery.signDriver == true) {
        fileNameSign = "sign_driver_" + delivery.dlvno + '.png';
        result = await Files.deleteFile(fileNameSign); 
      }
      for (Images image in delivery.imageList) {
        result = await Files.deleteFile(image.fileName);
      }
    }
    result = await Files.deleteFile(fileName);
    //print("Verzeichnis-Inhalt nachher....");
    //Files.directoryList();
  }
  // ------------------------------------------------------------------------------- //
  // Event in die Eventliste der Tour hinzufügen 
  // beim Schreiben des Events werden auch die geo-Daten ermittelt!
  // ------------------------------------------------------------------------------- //
  static Future<void> appendEvent(
    Tour tourData, 
    String event, 
    {
      String reason: '', 
      String info:'', 
      String dlvno: ''
      }
    ) async {

    String twoDigits(int n) {
      if (n >= 10) return "$n";
      return "0$n";
    }

    // get the currenr geo-location (==> globals.passLatitude)
    try {
      await Helpers.getCurrentLocation().timeout(const Duration(seconds: 3));    
    } on TimeoutException catch (e) {
      print('Timeout while waiting on getCurrentLocation');
    } on Error catch (e) {
      print('Error: $e');
    }

    // Add new Event 
    Events eventObj = new Events();
    eventObj.event = event;
    eventObj.reason = reason;
    eventObj.delvno = dlvno;
    eventObj.info = info;
    eventObj.changeKz = 'I';
    eventObj.dateTime = DateTime.now();

    if (event == globals.event_tour_continue) {
      if (tourData.syncTime != null && info == '') {
        Duration dauer = eventObj.dateTime.difference(tourData.syncTime);
        String minutes = twoDigits(dauer.inMinutes.remainder(60));
        String seconds = twoDigits(dauer.inSeconds.remainder(60));
        String hours = twoDigits(dauer.inHours.remainder(100));
        if (hours != '00') {
          eventObj.info  = '$hours:$minutes:$seconds';
        } else {
          eventObj.info  = '$minutes:$seconds';
        }
      }
    }

    if (event == globals.event_tour_start && info == '') {
      String kmStand = Helpers.formatInt(tourData.startKM); //tourData.startKM.toString();
      eventObj.info  = 'km: $kmStand';
    }

    if (event == globals.event_tour_ende && info == '') {
      String kmStand = Helpers.formatInt(tourData.endeKM); //tourData.endeKM.toString();
      eventObj.info  = 'km: $kmStand';
    }

    eventObj.latitude = globals.passLatitude;
    eventObj.longitude = globals.passLongitude;
    tourData.eventList.add(eventObj);

    print("geo-location: "+globals.passLatitude.toString()+" / "+globals.passLongitude.toString());
    
  }
  // ------------------------------------------------------------------------------- //
  // Übertragung der Daten direkt an SAP per HTTP-Post
  // ------------------------------------------------------------------------------- //
  static _transmitToSAP(
    Tour tourData, 
    {
      String dlvno, 
      bool head:false
    }) async {

    String jsonData  = tourData.toJson(tourData, delta:true, dlvno:dlvno, head:head);
    //print("transmitted to SAP - start : JSON = "+jsonData);

    SAP sap = new SAP();
    await sap.requestToSAP("save_tour", "0", jsonData);

    if( sap.returnCode == 0) {
      jsonData = sap.returnData;
      tourData.returnCode = 0;
      tourData.returnMssg = sap.returnMssg;
    } else {
      tourData.returnCode = 1;
      tourData.returnMssg = sap.returnMssg;
    }
    print("transmitted to SAP - ende : ReturnCode = "+tourData.returnCode.toString());
  }
  // ------------------------------------------------------------------------------- //
  // Daten von SAP anfordern 
  // ------------------------------------------------------------------------------- //
  static Future<Tour> _requestFromSAP(String routno, String drivno) async {

    String step = '0'; //next Tour
    if (routno != '')
      step = '1';     // current Tour

    RequestTour requestTour = new RequestTour();
    requestTour.routno = routno;
    requestTour.drivno = drivno;

    String jsonData = jsonEncode(requestTour.toJson());

    SAP sap = new SAP();
    await sap.requestToSAP("get_next_tour", step, jsonData);

    if( sap.returnCode == 0 ) {
      jsonData = sap.returnData;
    } else {
      Tour tourData = new Tour();
      tourData.routno = '';
      tourData.drivno = '';
      tourData.returnCode = 1;
      tourData.returnMssg = sap.returnMssg;
      return tourData;
    }

    //print(jsonData.substring(0,200));

    //Decode JSON data
    Tour tourData = new Tour();
    final mapData = jsonDecode(jsonData);

    tourData = Tour.fromJson(mapData);

    //tourData.returnCode = 0;
    tourData.returnMssg = sap.returnMssg;

    if (tourData.routno != '') {
      _saveToFile(tourData);
    }

    return tourData;
  }
}

/* ****************************************************************************** */
// Class Delivery                                                                 */
/* ****************************************************************************** */
class Delivery {
  String dlvno; // Lieferungsnummer
  int sequ; // Anfahrts-Reihenfolge
  String delvStat; // Status
  String name1; // Name
  String name2; // Name
  String ort01; // Ort
  String pstlz; // Postleitzahl
  String stras; // Straße
  String hausn; // Hausnummer
  String land1; // Land
  String phone; // Telefon
  String email; // Mailadresse
  String hinweis; // Anlieferungs-Hinweis
  bool barkz; // Kennzeichen 'bar kassieren'
  bool akonto; // Differenzbetrag als akonto verbuchen
  double betrag; // Betrag Warenwert
  double pfand; // Betrag Pfand
  double total; // Gesamtbetrag
  double rueck; // Betrag für Rücknahme
  double zuschl; // Aufschlag, Zuschlag
  double mwst;  // Mehrwertsteuer
  double difference; // Überzahlung
  double payment; // Barbetrag erhalten 
  String waers; // Währung
  DateTime startTime; // Start
  DateTime endeTime;  // Ende
  String changeKz; // Änderungskennzeichen I,U,D + S=Sync
  int countItems; // Anzahl Positionen
  int openItems; // Anzahl der offenen Positionen 
  int closedItems; // Anzahl der bearbeiteten Positionen 
  String signDriverFile;
  bool signDriver;
  String signDriverChangeKz;
  String signCustomerFile;
  bool signCustomer;
  String signCustomerChangeKz;
  List<DelvItem> itemList;
  List<Leergut> lgutList;
  List<Images> imageList;

  Delivery({
    this.dlvno,
    this.sequ,
    this.delvStat,
    this.name1,
    this.name2,
    this.ort01,
    this.pstlz,
    this.stras,
    this.hausn,
    this.land1,
    this.phone,
    this.email,
    this.hinweis,
    this.barkz,
    this.akonto,
    this.betrag,
    this.pfand,
    this.total,
    this.mwst,
    this.difference,
    this.payment,
    this.rueck,
    this.zuschl,
    this.waers,
    this.startTime, 
    this.endeTime, 
    this.changeKz,
    this.countItems,
    this.openItems,
    this.closedItems,
    this.signDriverFile, 
    this.signDriver,
    this.signDriverChangeKz,
    this.signCustomerFile,
    this.signCustomer,
    this.signCustomerChangeKz,
    this.itemList,
    this.lgutList,
    this.imageList,
  });
  // ------------------------------------------------------------------------------- //
  // Lieferdaten aus JSON String aufbauen 
  // ------------------------------------------------------------------------------- //
  factory Delivery.fromJson(Map<String, dynamic> json) {
    List<DelvItem> itemList = new List<DelvItem>();
    List<Leergut> lgutList = new List<Leergut>();
    List<Images> imageList = new List<Images>();
    int cntOpen = 0;
    int cntItem = 0;
    int cntClosed = 0;

    try {
      json['item'].forEach((i) {
        itemList.add(new DelvItem.fromJson(i));
        if (itemList[cntItem].completed == false) {
          cntOpen++; 
        } else {
          cntClosed++;
        }
        cntItem++;
      });
    } catch (e) {
      itemList = [];
    }
    try {
      json['lgut'].forEach((i) {
        lgutList.add(new Leergut.fromJson(i));
      });
    } catch (e) {
      lgutList = [];
    }
    try {
      json['image'].forEach((i) {
        imageList.add(new Images.fromJson(i));
      });
    } catch (e) {
      imageList = [];
    }
    return new Delivery(
      dlvno: json['dlvno'] as String,
      sequ: json['sequ'] == null ? 0 : json['sequ'] as int,
      delvStat: json['delvstat'] == null ? '' : json['delvstat'] as String,
      name1: json['name1'] == null ? '' : json['name1'] as String,
      name2: json['name2'] == null ? '' : json['name2'] as String,
      ort01: json['ort01'] == null ? '' : json['ort01'] as String,
      pstlz: json['pstlz'] == null ? '' : json['pstlz'] as String,
      stras: json['stras'] == null ? '' : json['stras'] as String,
      hausn: json['hausn'] == null ? '' : json['hausn'] as String,
      land1: json['land1'] == null ? 'DE' : json['land1'] as String,
      phone: json['phone'] == null ? '' : json['phone'] as String,
      email: json['email'] == null ? '' : json['email'] as String,
      hinweis: json['hinweis'] == null ? '' : json['hinweis'] as String,
      barkz: json['barkz'] == null ? false : json['barkz'] as bool,
      akonto: json['akonto'] == null ? false : json['akonto'] as bool,
      betrag: json['betrag'] == null ? 0.0 : json['betrag'] as double,
      pfand: json['pfand'] == null ? 0.0 : json['pfand'] as double,
      total: json['total'] == null ? 0.0 : json['total'] as double,
      mwst: json['mwst'] == null ? 0.0 : json['mwst'] as double,
      rueck: json['rueck'] == null ? 0.0 : json['rueck'] as double,
      zuschl: json['zuschl'] == null ? 0.0 : json['zuschl'] as double,
      difference: json['difference'] == null ? 0.0 : json['difference'] as double,
      payment: json['payment'] == null ? 0.0 : json['payment'] as double,
      waers: json['waers'] == null ? '' : json['waers'] as String,
      startTime: json['starttime'] == null ? new DateTime(1900) : DateTime.parse(json['starttime']),
      endeTime: json['endetime'] == null ? new DateTime(1900) : DateTime.parse(json['endetime']),
      changeKz: json['changekz'] == null ? '' : json['changekz'] as String,
      signDriverChangeKz: json["signdriverchangekz"] as String,
      signDriver: json["signdriver"] == null ? false : json["signdriver"] as bool,
      signCustomerChangeKz: json["signcustomerchangekz"] as String,
      signCustomer: json["signcustomer"] == null ? false : json["signcustomer"] as bool,
      itemList: itemList,
      lgutList: lgutList,
      imageList: imageList,
      countItems: cntItem,
      openItems: cntOpen,
      closedItems: cntClosed,
    );
  }
  // ------------------------------------------------------------------------------- //
  // Lieferdaten mappen 
  // ------------------------------------------------------------------------------- //
  Map<String, dynamic> toJsonMap( Delivery delivery, {bool delta:false} ) {

    bool itemChanged = false;
    bool lgutChanged = false;
    bool imageChanged = false;

    var mapData = new Map<String, dynamic>();

    if (delivery.signDriverChangeKz == null) {
      delivery.signDriverChangeKz = '';
      delivery.signDriverFile = '';
    }
    if (delivery.signCustomerChangeKz == null) {
      delivery.signCustomerChangeKz = '';
      delivery.signCustomerFile = '';
    }

    mapData["dlvno"] = delivery.dlvno;
    mapData["sequ"] = delivery.sequ;
    mapData["delvstat"] = delivery.delvStat;
    if (delta == false) {
      mapData["name1"] = delivery.name1;
      mapData["name2"] = delivery.name2;
      mapData["stras"] = delivery.stras;
      mapData["hausn"] = delivery.hausn;
      mapData["ort01"] = delivery.ort01;
      mapData["pstlz"] = delivery.pstlz;
      mapData["land1"] = delivery.land1;
      mapData["phone"] = delivery.phone;
      mapData["email"] = delivery.email;
      mapData["hinweis"] = delivery.hinweis;
      mapData["barkz"] = delivery.barkz;
    }
    mapData["betrag"] = delivery.betrag;
    mapData["pfand"] = delivery.pfand;
    mapData["total"] = delivery.total;
    mapData["mwst"] = delivery.mwst;
    mapData["zuschl"] = delivery.zuschl;
    mapData["rueck"] = delivery.rueck;
    mapData["difference"] = delivery.difference;
    mapData["payment"] = delivery.payment;
    mapData["waers"] = delivery.waers;
    mapData["akonto"] = delivery.akonto;
    mapData["starttime"] = delivery.startTime.toIso8601String(); 
    mapData["endetime"] = delivery.endeTime.toIso8601String(); 
    mapData["changekz"] = delivery.changeKz;
    mapData["signdriverchangekz"] = delivery.signDriverChangeKz;
    mapData["signdriver"] = delivery.signDriver;
    mapData["signcustomerchangekz"] = delivery.signCustomerChangeKz;
    mapData["signcustomer"] = delivery.signCustomer;

    if (delivery.signCustomerFile == null) delivery.signCustomerFile = '';
    if (delivery.signDriverFile == null) delivery.signDriverFile = '';

    if (delivery.signDriverChangeKz != '' && delivery.signDriverFile != '') {
      try {
        final bytes = Io.File(delivery.signDriverFile).readAsBytesSync(); 
        String img64 = base64Encode(bytes);
        mapData["signdriverimage"] = img64;
      } catch (e) {
        print("file notfound: "+delivery.signDriverFile);
      }
    } else {
      mapData["signdriverimage"] = '';
    }

    if (delivery.signCustomerChangeKz != '' && delivery.signCustomerFile != '') {
      try {
        final bytes = Io.File(delivery.signCustomerFile).readAsBytesSync(); 
        String img64 = base64Encode(bytes);
        mapData["signcustomerimage"] = img64;
      } catch (e) {
        print("file notfound: "+delivery.signCustomerFile);
      }
    } else {
      mapData["signcustomerimage"] = '';
    }

    if (delivery.itemList != null) {
      DelvItem itemObj = new DelvItem();
      //List<Map<String, dynamic>> itemMap =
      //    delivery.itemList.map((item) => itemObj.toJsonMap(item,delta:delta)).toList();
      List<Map<String, dynamic>> itemMap = [];
      for (DelvItem item in delivery.itemList) {
        if(delta == false || item.changeKz != '') {
          itemMap.add(itemObj.toJsonMap(item,delta:delta));
        }
      }
      if (itemMap.length > 0) {
        mapData["item"] = itemMap;
        itemChanged = true;
      }
    } else {
      //mapData["item"] = null;
    }

    if (delivery.lgutList != null) {
      Leergut lgutObj = new Leergut();
      //List<Map<String, dynamic>> lgutMap =
      //    delivery.lgutList.map((lgut) => lgutObj.toJsonMap(lgut,delta:delta)).toList();
      List<Map<String, dynamic>> lgutMap = [];
      for (Leergut lgut in delivery.lgutList) {
        if(delta == false || lgut.changeKz != '') {
          lgutMap.add(lgutObj.toJsonMap(lgut,delta:delta));
        }
      }
      if (lgutMap != null && lgutMap.length > 0) {
        mapData["lgut"] = lgutMap;
        lgutChanged = true;
      }
    } else {
      //mapData["lgut"] = null;
    }

    if (delivery.imageList != null) {
      Images imageObj = new Images();
      //List<Map<String, dynamic>> imageMap =
      //    delivery.imageList.map((img) => imageObj.toJsonMap(img,delta:delta)).toList();
      List<Map<String, dynamic>> imageMap = [];
      for (Images image in delivery.imageList) {
        if(delta == false || image.changeKz != '') {
          imageMap.add(imageObj.toJsonMap(image,delta:delta));
        }
      }
      if (imageMap != null && imageMap.length > 0) {
        mapData["image"] = imageMap;
        imageChanged = true;
      }
    } else {
      //mapData["image"] = null;
    }

    return mapData;
  }
  // ------------------------------------------------------------------------------- //
  // Lieferdaten als JSON String serialiseren 
  // ------------------------------------------------------------------------------- //
  String toJson( Delivery delivery, { bool imageBinary:false } ) {

    var mapData = toJsonMap(delivery);
    String json = jsonEncode(mapData);
    return json;
  }
}

/* ****************************************************************************** */
// Class DelvItem                                                                 */
/* ****************************************************************************** */
class DelvItem {
  String posnr; // Lieferungs-Position
  String matnr; // Material-/Artikel-Nummer
  String abmes; // Abmessungen
  String maktx; // Artikel-Bezeichnung
  double menge; // Menge
  String meins; // Mengeneinheit
  int    decim; // Dezimalstellen der Einheit
  double lfimg; // Liefermenge in Verkaufsmengeneinheit
  String vrkme; // Verkaufsmengeneinheit
  int    vdeci; // Dezimalstellen der Verkaufsmengeneinheit 
  bool completed; // Position wurde ausgeliefert
  bool damaged;   // Komplett beschädigt
  bool shortage;  // Fehlt komplett
  double fmeng; // Fehlmenge
  String fmein; // Einheit Fehlmenge
  int    fdeci; // Dezimalstellen Einheit Fehlmenge
  double bmeng; // Bruchmenge
  String bmein; // Einheit Bruchmenge
  int    bdeci; // Dezimalstellen Einheit Bruchmenge
  int    images; // Anzahl Fotos
  int    imgmax; // Highest Number
  bool   mixed; // Mischpalette
  String changeKz; // I,U,D + S=Sync
  List<Units> unitsList;

  DelvItem({
    this.posnr,
    this.matnr,
    this.maktx,
    this.abmes,
    this.menge,
    this.meins,
    this.decim,
    this.lfimg, 
    this.vrkme,
    this.vdeci,
    this.completed,
    this.damaged,
    this.shortage,
    this.fmeng,
    this.fmein,
    this.fdeci,
    this.bmeng,
    this.bmein,
    this.bdeci,
    this.images,
    this.imgmax,
    this.mixed,
    this.changeKz,
    this.unitsList,
  });

  // ------------------------------------------------------------------------------- //
  // Liefer-Positionsdaten aus den JSON Daten aufbauen
  // ------------------------------------------------------------------------------- //
  factory DelvItem.fromJson(Map<String, dynamic> json) {
    List<Units> unitsList = new List<Units>();
    try {
      json['units'].forEach((i) {
        unitsList.add(new Units.fromJson(i));
      });
    } catch (e) {
      print(e);
    }
    return new DelvItem(
        posnr: json['posnr'] as String,
        matnr: json['matnr'] as String,
        maktx: json['maktx'] as String,
        abmes: json['abmes'] as String,
        menge: json['menge'] as double,
        meins: json['meins'] as String,
        decim: json['decim'] as int,
        lfimg: json['lfimg'] as double,
        vrkme: json['vrkme'] as String,
        vdeci: json['vdeci'] as int,
        completed: json['completed'] as bool,
        damaged: json['damaged'] as bool,
        shortage: json['shortage'] as bool,
        fmeng: json['fmeng'] as double,
        fmein: json['fmein'] as String,
        fdeci: json['fdeci'] as int,
        bmeng: json['bmeng'] as double,
        bmein: json['bmein'] as String,
        bdeci: json['bdeci'] as int,
        images: json['images'] as int,
        imgmax: json['imgmax'] as int,
        mixed: json['mixed'] as bool,
        changeKz: json['changeKz'] == null ? '' : json['changeKz'] as String,
        unitsList: unitsList);
  }
  // ------------------------------------------------------------------------------- //
  // Positionsdaten mappen 
  // ------------------------------------------------------------------------------- //
  Map<String, dynamic> toJsonMap( DelvItem delvItem, { bool delta:false } ) {
 
    var mapData = new Map<String, dynamic>();

    if(delvItem.changeKz == null || delvItem.changeKz == ' ')
      delvItem.changeKz = '';

    mapData["posnr"] = delvItem.posnr;
    mapData["matnr"] = delvItem.matnr;
    if (delta == false) {
      mapData["maktx"] = delvItem.maktx;
      mapData["abmes"] = delvItem.abmes;
    }
    mapData["menge"] = delvItem.menge;
    mapData["meins"] = delvItem.meins;
    mapData["decim"] = delvItem.decim;
    mapData["lfimg"] = delvItem.lfimg;
    mapData["vrkme"] = delvItem.vrkme;
    mapData["vdeci"] = delvItem.vdeci;
    mapData["completed"] = delvItem.completed;
    mapData["damaged"] = delvItem.damaged;
    mapData["shortage"] = delvItem.shortage;
    mapData["fmeng"] = delvItem.fmeng;
    mapData["fmein"] = delvItem.fmein;
    mapData["fdeci"] = delvItem.fdeci;
    mapData["bmeng"] = delvItem.bmeng;
    mapData["bmein"] = delvItem.bmein;
    mapData["bdeci"] = delvItem.bdeci;
    mapData["images"] = delvItem.images;
    mapData["imgmax"] = delvItem.imgmax;
    mapData["mixed"] = delvItem.mixed;
    mapData["changeKz"] = delvItem.changeKz;

    try {
      if (delvItem.unitsList != null && delta == false) {
        Units unitObj = new Units();
        List<Map<String, dynamic>> unitMap =
            delvItem.unitsList.map((unit) => unitObj.toJsonMap(unit)).toList();
        mapData["units"] = unitMap;
      } else {
        //mapData["units"] = null;
      }
    } catch (e) {
    }
    return mapData;
  }
  // ------------------------------------------------------------------------------- //
  // Positionsdaten serialisieren 
  // ------------------------------------------------------------------------------- //
  String toJson( DelvItem delvItem, { bool delta:false } ) {

    String json = '';
    var mapData = toJsonMap(delvItem,delta:delta);
    json = jsonEncode(mapData);

    return json;
  }
}

/* ****************************************************************************** */
// Class Images                                                                   */
/* ****************************************************************************** */
class Images {

  String posnr; // Lieferungs-Position ???
  int number; // laufende Nummer
  String fileName; // Pfad 
  String comment;  // Kommentare 
  String changeKz; // Änderungskennzeichen
  String img64; // encoded Image (Base64)

  Images ({this.posnr, this.number, this.fileName, this.comment, this.changeKz, this.img64});

  // ------------------------------------------------------------------------------- //
  // Bilddaten aus den JSON Daten aufbauen (Metadaten)
  // ------------------------------------------------------------------------------- //
  factory Images.fromJson(Map<String, dynamic> json) {

    return new Images(
      posnr:    json['posnr'] as String,
      number:   json['nummer'] as int,        /*   !!   */
      fileName: json['fileName'] as String,
      comment:  json['comm'] as String,       /*   !!   */
      changeKz: json['changeKz'] as String,
      img64:    json['img64'] as String
    );
  }

  Map<String, dynamic> toJsonMap(Images image, {bool delta:false}) {
    var mapData = new Map<String, dynamic>();
    mapData["posnr"] = image.posnr;
    mapData["nummer"] = image.number;         /*   !!   */
    mapData["fileName"] = image.fileName;
    mapData["comm"] = image.comment;          /*   !!   */
    mapData["changeKz"] = image.changeKz;
    if (delta == true && image.changeKz == 'I') {
      try {
        final bytes = Io.File(image.fileName).readAsBytesSync(); 
        String img64 = base64Encode(bytes);
        mapData["img64"] = img64;
      } catch (e) {
        print("file notfound: "+image.fileName);
      }
    } else {
      mapData["img64"] = '';
    }
    return mapData;
  }
  // ------------------------------------------------------------------------------- //
  // Bilddaten serialisieren 
  // ------------------------------------------------------------------------------- //  
  String toJson(Images image, {bool delta:false}) {

    var mapData = toJsonMap(image, delta:delta);
    String json = jsonEncode(mapData);
    return json;
  }
}

/* ****************************************************************************** */
// Class Leergut                                                                  */
/* ****************************************************************************** */
class Leergut {
  String matnr; // Materialnummer, Artikel-Nummer
  double menge; // Menge
  String meins; // Mengeneinheit
  String abmes; // Abmessungen
  String maktx; // Artikel-Bezeichnung
  double pfand; // Pfandwert
  String waers; // Währung (Pfand)
  String changeKz; 

  Leergut({
    this.matnr,
    this.maktx,
    this.abmes,
    this.menge,
    this.meins,
    this.pfand,
    this.waers,
    this.changeKz,
  });

  // ------------------------------------------------------------------------------- //
  // Leergut-Daten aus den JSON Daten aufbauen
  // ------------------------------------------------------------------------------- //
  factory Leergut.fromJson(Map<String, dynamic> json) {
    
    return new Leergut(
      matnr: json['matnr'] as String,
      maktx: json['maktx'] as String,
      abmes: json['abmes'] as String,
      menge: json['menge'] as double,
      meins: json['meins'] as String,
      pfand: json['pfand'] as double,
      waers: json['waers'] as String,
      changeKz: json['changeKz'] as String,
    );
  }
  Map<String, dynamic> toJsonMap( Leergut leergut, { bool delta:false } ) {

    var mapData = new Map<String, dynamic>();

    mapData["matnr"] = leergut.matnr;
    //if (delta == false) {
    mapData["maktx"] = leergut.maktx;
    mapData["abmes"] = leergut.abmes;
    //}
    mapData["menge"] = leergut.menge;
    mapData["meins"] = leergut.meins;
    mapData["pfand"] = leergut.pfand;
    mapData["waers"] = leergut.waers;
    mapData["changeKz"] = leergut.changeKz;
    return mapData;
  }

  String toJson(Leergut leergut, {bool delta:false}) {
    var mapData = toJsonMap(leergut, delta:delta);
    String json = jsonEncode(mapData);
    return json;
  }
}

/* ****************************************************************************** */
// Class StandardLeergut                                                          */
/* ****************************************************************************** */
class StandardLeergut {

  String matnr; // Materialnummer
  String maktx; // Materialbezeichnung
  String abmes; // Abmessungen
  double pfand; // Pfandwert
  String waers; // Währung (Pfand)
  String meins; // Mengeneinheit

  StandardLeergut({
    this.matnr,
    this.maktx,
    this.abmes,
    this.pfand,
    this.waers,
    this.meins,
  });

  // ------------------------------------------------------------------------------- //
  // Standard-Leergut (als Vorlage zur Auswahl)
  // ------------------------------------------------------------------------------- //
  factory StandardLeergut.fromJson(Map<String, dynamic> json) {

    return new StandardLeergut(
      matnr: json['matnr'] as String,
      maktx: json['maktx'] == null ? '' : json['maktx'] as String,
      abmes: json['abmes'] == null ? '' : json['abmes'] as String,
      pfand: json['pfand'] == null ? 0.0 : json['pfand'] as double,
      waers: json['waers'] == null ? '' : json['waers'] as String,
      meins: json['meins'] == null ? '' : json['meins'] as String,
    );
  }

  static Future<List<StandardLeergut>> getLeergut() async {

    final List<StandardLeergut> listData = [];
    String rawData = '';
    String fileName = 'leergut';

    // read data from local file 
    rawData = await Files.readFromFile(fileName);

    if(rawData == null || rawData == '') {
      return listData;
    } 

    // Decode JSON data
    final mapData = jsonDecode(rawData);
    StandardLeergut standardLeergut;
    for (Map i in mapData) {
      standardLeergut = StandardLeergut.fromJson(i);
      listData.add(standardLeergut);
    }
    return listData;
  }

  // ------------------------------------------------------------------------------- //
  // Lesen des Standard-Leerguts von SAP
  // ------------------------------------------------------------------------------- //
  static Future<void> getFromBackend() async {

    final List<StandardLeergut> listData = [];

    String rawData = '';
    String fileName = 'leergut';

    if (globals.demoModus == true) {
      // get JSON data from asset/file
      try {
        rawData = await _loadAsset();
      } catch (e) {
        print("getLeergut from asset/file failed");
      }
    } else {
      // get JSON data via HTTP (from SAP)
      SAP sap = new SAP();
      String json = '';
      await sap.requestToSAP("get_empties", "0", json);
      if (sap.returnCode == 0) rawData = sap.returnData;
    }
    // Save to local file
    int result = await Files.writeToFile(fileName, rawData);
  }

  // ------------------------------------------------------------------------------- //
  // Lesen lokal - für Demo-Tour
  // ------------------------------------------------------------------------------- //
  static Future<String> _loadAsset() async {
    return await rootBundle.loadString("resources/data/leergut.json");
  }
}

/* ****************************************************************************** */
// Class Fahrer                                                                   */
/* ****************************************************************************** */
class Fahrer {
  String nummer;
  String name;

  static List<Fahrer> buffer = [];
  static Map<String, String> driverMap = {};

  Fahrer({
    this.nummer,
    this.name,
  });

  factory Fahrer.fromJson(Map<String, dynamic> json) {
    return new Fahrer(
      nummer: json['nummer'] as String,
      name: json['name'] as String,
    );
  }

  static String getNameSync(String nummer) {
    String name = '';
    if (driverMap != null && driverMap != {}) {
      if (nummer != null && nummer != '') {
        name = driverMap[nummer];
      }
    }
    if (name == null) name = '';
    return name;
  }

  static Future<String> getName(String nummer) async {
    String name = '';
    if (driverMap == null || driverMap.isEmpty) {
      await getFahrerFromFile();
    }
    if (driverMap != null && driverMap.isNotEmpty) {
      if (nummer != null && nummer != '') {
        name = driverMap[nummer];
      }
    }
    if (name == null) name = '';
    return name;
  }

  // ------------------------------------------------------------------------------- //
  // Lesen der Fahrer-Daten aus der Sicherung (File)
  // ------------------------------------------------------------------------------- //
  static Future<void> getFahrerFromFile() async {
    final List<Fahrer> listData = [];

    String rawData = '';
    String fileName = 'drivers';

    // read data from local file 
    rawData = await Files.readFromFile(fileName);

    // Decode JSON data
    if (rawData == '') {
      return listData;
    }
    final mapData = jsonDecode(rawData);
    Fahrer fahrer;

    // Build list 
    for (Map i in mapData) {
      fahrer = Fahrer.fromJson(i);
      listData.add(fahrer);
    }
    // store in global map 
    _buildMap(listData);
    return listData;
  }

  // ------------------------------------------------------------------------------- //
  // Lesen der Fahrer-Daten vom Backend
  // ------------------------------------------------------------------------------- //
  static Future<void> getFromBackend() async {

    final List<Fahrer> listData = [];

    String rawData = '';
    String fileName = 'drivers';

    if (globals.demoModus == true) {
      // get JSON data from asset/file
      try {
        rawData = await _loadFromAsset();
      } catch (e) {
        print("getFahrer from asset/file failed");
      }
    } else {
      print("get data from SAP");
      // get JSON data via HTTP (from SAP)
      SAP sap = new SAP();
      String json = '';
      await sap.requestToSAP("get_drivers", "0", json);
      if (sap.returnCode == 0) rawData = sap.returnData;
    }
    // save to local file
    int result = await Files.writeToFile(fileName, rawData);

    // fill global map
    _buildMap(listData);
  }

  static void _buildMap(List<Fahrer> drivers) {
    drivers.forEach((fahrer) => driverMap[fahrer.nummer] = fahrer.name);
  }

  // ------------------------------------------------------------------------------- //
  // Lesen der Fahrerdaten für die Demo-Tour
  // ------------------------------------------------------------------------------- //
  static Future<String> _loadFromAsset() async {
    return await rootBundle.loadString("resources/data/fahrer.json");
  }
}

/* ****************************************************************************** */
// Class Events                                                                   */
/* ****************************************************************************** */
class Events {
  String event; 
  String delvno;
  String reason;
  String info;
  DateTime dateTime;
  double latitude;
  double longitude;
  String changeKz;

  Events({
    this.event, 
    this.delvno, 
    this.reason, 
    this.info,
    this.dateTime, 
    this.latitude, 
    this.longitude, 
    this.changeKz
    }); 

  // ------------------------------------------------------------------------------- //
  // Ereignisse aus den JSON Daten aufbauen
  // ------------------------------------------------------------------------------- //
  factory Events.fromJson(Map<String, dynamic> json) {
    return new Events(
      event:     json['event']    as String,
      reason:    json['reason']   == null ? '' : json['reason'] as String,
      delvno:    json['delvno']   == null ? '' : json['delvno'] as String,
      info:      json['info']     == null ? '' : json['info']   as String,
      dateTime:  json['datetime'] == null ? new DateTime(1900) : DateTime.parse(json['datetime']),
      latitude:  json['latitude']  as double,
      longitude: json['longitude'] as double,
      changeKz:  json['changekz']  as String,
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'event':     event,
      'reason':    reason,
      'delvno':    delvno,
      'info':      info,
      'datetime':  dateTime.toIso8601String(),
      'latitude':  latitude, 
      'longitude': longitude,
      'changekz':  changeKz,
    };
  }

  // ------------------------------------------------------------------------------- //
  // Bezeichnung zum Ereignis lesen 
  // ------------------------------------------------------------------------------- //
  static String getEventDescr(BuildContext context, event) {
    var eventMap = getEvents(context);
    return eventMap[event];
  }
  // ------------------------------------------------------------------------------- //
  // Bezeichnung des Unterbrechungsgrundes lesen 
  // ------------------------------------------------------------------------------- //
  static String getReasonDescr(BuildContext context, reason) {
    var reasonMap = getReasons(context);
    return reasonMap[reason];   
  }
  // ------------------------------------------------------------------------------- //
  // Daten für Eregnisse für die Anzeige des Tourverlauf aufbereiten 
  // ------------------------------------------------------------------------------- //
  static Map<String,String> getEvents(BuildContext context,) {
    String tourLabel  = H.getText(context, 'tour');
    String delvLabel  = H.getText(context, 'delivery');
    String breakLabel = H.getText(context, 'interrupt');
    return {
      globals.event_tour_start    : tourLabel + " " + H.getText(context, 'started'),
      globals.event_tour_reset    : tourLabel + " " + H.getText(context, 'resetted'),
      globals.event_tour_ende     : tourLabel + " " + H.getText(context, 'completed'),
      globals.event_tour_break    : tourLabel + " " + H.getText(context, 'interrupted'),
      globals.event_tour_continue : tourLabel + " " + H.getText(context, 'continued'),
      globals.event_delv_start    : delvLabel + " " + H.getText(context, 'started'),
      globals.event_delv_reset    : delvLabel + " " + H.getText(context, 'resetted'),
      globals.event_delv_ende     : delvLabel + " " + H.getText(context, 'completed'),
      globals.event_break_start   : breakLabel + " " + H.getText(context,'started'),
      globals.event_break_ende    : breakLabel + " " + H.getText(context,'completed'),
    };
  }
  static Map<String,String> getReasons(BuildContext context,) {
    return {
      globals.reason_break        : H.getText(context, 'break'),
      globals.reason_accident     : H.getText(context, 'accident'),
      globals.reason_emergency    : H.getText(context, 'emergency'),
      globals.reason_waiting      : H.getText(context, 'waiting'),
      globals.reason_traffic_jam  : H.getText(context, 'traffic_jam'),
    };
  }
}

/* ****************************************************************************** */
// Class RequestTour                                                              */
/* ****************************************************************************** */
class RequestTour {

  String routno; 
  String drivno; 

  RequestTour({this.routno, this.drivno});

  // ------------------------------------------------------------------------------- //
  // Strukturdaten für die Anforderung der Tourdaten vom Backend
  // ------------------------------------------------------------------------------- //
  factory RequestTour.fromJson(Map<String, dynamic> json) {
    return new RequestTour(
      routno: json['routno'] as String,
      drivno: json['drivno'] as String,
    );
  }
  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'routno': routno,
      'drivno': drivno,
    };
  }
}