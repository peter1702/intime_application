import 'package:preferences/preferences.dart';
import 'package:flutter/material.dart';
import 'package:progress_dialog/progress_dialog.dart';
import 'package:flutter/cupertino.dart';
import 'dart:io';
import 'package:intl/intl.dart';

import '../globals.dart' as globals;
import '../helpers/helpers.dart';
import '../views/impressum.dart';
import '../models/tour.dart';

import '../views/tour_page.dart'; // Tour Overview
import '../views/cust_page.dart'; // Settings

class StartPage extends StatefulWidget {
  static String tag = 'start-page';
  @override
  _StartPageState createState() => new _StartPageState();
}

class _StartPageState extends State<StartPage> {

  final GlobalKey<ScaffoldState> _scaffoldKey = new GlobalKey<ScaffoldState>();

  String buttonText = '';
  String buttonText2 = '';
  String bottomHint = '';
  bool activeTour = false;

  List<CustomPopupMenu> choices = [];
  CustomPopupMenu buttonChoice;

  Future<Null> getPrefs() async {
    await PrefService.init(prefix: 'set_');
    Helpers.loadGlobals();
  }

  @override
  void initState() {
    super.initState();
    getPrefs();
  }

  void _buildMenue() {
    choices = [];
    choices = <CustomPopupMenu>[
      CustomPopupMenu(
          title: H.getText(context, "transfer_stat"),
          icon: Icons.import_export,
          action: "stat")
    ];
    if (globals.toBeSynchronized == null || globals.toBeSynchronized == false) {
      globals.toBeSynchronized = false;
      bottomHint = '';
    } else {
      bottomHint = H.getText(context, "M026");
    }
  }

  void _selectPopupMenu(CustomPopupMenu choice) async {
    if (choice.disabled == false) {
      setState(() {
        switch (choice.action) {
          case "back":
            // Zurück
            Navigator.pop(context, true);
            break;
          case "stat":
            // Übermittlungsstatus anzeigen
            _showTransferStatus(context);
            break;
        }
      });
    }
  }

  Future<bool> _exitApp(BuildContext context) async {
    String title =  H.getText(context, "leave");
    String content =  H.getText(context, "M033");
    String answer = await H.confirmDialog(context, title, content);
    if (answer == 'Y') {
      Navigator.pop(context, true);
    }
  }

  /*---------------------------------------------------------------------------*/
  // Build View
  /*---------------------------------------------------------------------------*/
  @override
  Widget build(BuildContext context) {
    _initialize(context);
    _buildMenue();

    return new WillPopScope(
      onWillPop: () => _exitApp(context),
      child: new Scaffold(
      backgroundColor: Colors.white,
      key: _scaffoldKey,

      appBar: AppBar(
        backgroundColor: globals.primaryColor,
        title: //Text(H.getText(context, 'main_title')),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Container( 
            margin: EdgeInsets.only(top:14),
            child: Image(image: ExactAssetImage('lib/images/intime_white.png'),
                          fit: BoxFit.contain, height:95),
        ),
        ],),
        // PopupMenu
        actions: <Widget>[
          if (choices.isEmpty == false) popupMenu(),
        ],
      ),

      bottomNavigationBar: BottomAppBar(
        child: Container(
            width: double.infinity,
            color: Colors.black87,
            child: Text(
              bottomHint,
              style: TextStyle(color: Colors.orange),
            )),
      ),

      drawer: new Drawer(
        child: Column(
          children: <Widget>[
            Expanded(
              child: ListView(
                children: <Widget>[
                  DrawerHeader(
                    child: Text(''),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      image: DecorationImage(
                          //image: ExactAssetImage('lib/images/logo.png'),
                          image: ExactAssetImage('lib/images/intime_logo.png'),
                            fit: BoxFit.contain),
                    ),
                  ),
                  globals.demoModus
                      ? ListTile(
                          title: Text(H.getText(context, 'tour_reset')),
                          trailing: Icon(Icons.navigate_next),
                          onTap: () => _resetDemoTour(context),
                        )
                      : Container(),
                  /*
                  ListTile(
                      title: Text('Test Form Validation'),
                      trailing: Icon(Icons.navigate_next),
                      onTap: () {
                        Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (context) => ContactPage()));
                      }),
                  ListTile(
                      title: Text('Test SAP Connector'),
                      trailing: Icon(Icons.navigate_next),
                      onTap: () {
                        Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (context) => SAPConnect()));
                      }),
                  ListTile(
                      title: Text('Demo Warehouse-Management'),
                      trailing: Icon(Icons.navigate_next),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => MenuPage(
                                title: 'Warehouse-Management', menue: "LVS"),
                          ),
                        );
                      }),
                  */
                ],
              ),
            ),
            //
            Container(
              // This align moves the children to the bottom
              child: Align(
                alignment: FractionalOffset.bottomCenter,
                // This container holds all the children that will be aligned
                // on the bottom and should not scroll with the above ListView
                child: Container(
                  child: Column(
                    children: <Widget>[
                      Divider(
                        thickness: 1.5,
                      ),
                      ListTile(
                          leading: Icon(Icons.settings, color:globals.primaryColor),
                          trailing: Icon(Icons.navigate_next),
                          title: Text(H.getText(context, 'settings')),
                          onTap: () {
                            Navigator.push(
                                context,
                                MaterialPageRoute(
                                    //builder: (context) => SettingPage()));
                                    builder: (context) => Customizing()));
                          }),
                      ListTile(
                          leading: Icon(Icons.info_outline, color:globals.primaryColor),
                          trailing: Icon(Icons.navigate_next),
                          title: Text(H.getText(context, 'impressum')),
                          onTap: () {
                            Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (context) => Impressum()));
                          }),
                      ListTile(
                          leading: Icon(Icons.help_outline, color:globals.primaryColor),
                          trailing: Icon(Icons.navigate_next),
                          title: Text(H.getText(context, 'helping'))),
                      Divider(
                        thickness: 1.5,
                      ),
                      ListTile(
                          title: Text(H.getText(context, 'logout')),
                          leading: Icon(Icons.power_settings_new,
                              color: Colors.redAccent),
                          onTap: () {
                            exit(0);
                          }),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),

      /* --------------------------------------------------------------------- */
      body: new Container(
        child: new Center(
          child: new Column(
            children: <Widget>[
              InkWell(
                onTap: () {},
                child: Container(
                  padding: new EdgeInsets.fromLTRB(40.0, 17.0, 40.0, 17.0),
                  height: 350,
                  width: 350,
                  child: ClipRRect(
                    child: Image.asset('lib/images/transport.png',
                        fit: BoxFit.contain),
                  ),
                ),
              ),
              Container(
                height: 80,
                padding: EdgeInsets.fromLTRB(17, 20, 17, 0),
                child: SizedBox(
                  width: double.infinity,
                  child: RaisedButton(
                      shape: new RoundedRectangleBorder(
                          //side: BorderSide(color: Colors.red),,
                          borderRadius: new BorderRadius.circular(5.0)),
                      textColor: Colors.white,
                      color: globals.primaryColor,
                      child: Text(buttonText, style: TextStyle(fontSize: 18)),
                      onPressed: () async {
                        activeTour
                            ? _processCurrentTour(context)
                            : _determinateNextTour(context);
                      }),
                ),
              ),
              activeTour || globals.currentTourNo == ''
              ? Container()
              : Container(
                height: 80,
                padding: EdgeInsets.fromLTRB(17, 20, 17, 0),
                child: SizedBox(
                  width: double.infinity,
                  child: RaisedButton(
                      shape: new RoundedRectangleBorder(
                          //side: BorderSide(color: Colors.red),,
                          borderRadius: new BorderRadius.circular(5.0)),
                      textColor: Colors.white,
                      color: globals.primaryColor,
                      child: Text(buttonText2, style: TextStyle(fontSize: 18)),
                      onPressed: () async {
                        _displayLastTour(context);
                      }),
                ),
              ),
            ],
          ),
        ),
      ),
    ));
  }

  /*---------------------------------------------------------------------------*/
  // StartPage initialisieren
  /*---------------------------------------------------------------------------*/
  void _initialize(BuildContext context) {
    
    if ( globals.currentTourNo == null ) {
      globals.currentTourNo = '';
    }
    if ( globals.currentTourNo != '' &&
        ( globals.currentTourStat == globals.tourStat_started ||
          globals.currentTourStat == globals.tourStat_interrupted )) {
      buttonText = H.getText(context, 'cont_tour', v1: globals.currentTourNo);
      activeTour = true;
    } else {
      buttonText = H.getText(context, 'next_tour');
      activeTour = false;
    }
    if (globals.currentTourNo != '') {
      buttonText2 = H.getText(context, 'disp_tour', v1: globals.currentTourNo);
    }
  }
  /*---------------------------------------------------------------------------*/
  // Zurücksetzen der Demo Tour
  /*---------------------------------------------------------------------------*/
  void _resetDemoTour(BuildContext context) {

    String tourNo = '';
    String drivNo = '';
    tourNo = globals.currentTourNo;
    drivNo = globals.currentDrivNo;
    Tour.deleteTour(tourNo, drivNo, demo:true);
    setState(() {
      _initialize(context);
    });
    _showMessage("Demo Tour was resetted", Colors.orange);
  }

  /*---------------------------------------------------------------------------*/
  // Letzte Tour anzeigen
  /*---------------------------------------------------------------------------*/
  void _displayLastTour(BuildContext context) async {
    //
    _processCurrentTour(context);
  }

  /*---------------------------------------------------------------------------*/
  // Nächste Tour bestimmen
  /*---------------------------------------------------------------------------*/
  void _determinateNextTour(BuildContext context) async {

    String uname = ''; 
    uname = globals.userName; 
    if (uname == null || uname == '')
      uname = globals.loginName;

    Tour tourData = await Tour.getNextTour(uname);

    if (tourData == null) {
      _showMessage("Connection to SAP failed");
    } else if (tourData.returnCode != 0) {
      _showMessage(tourData.returnMssg);
    } else if (tourData.routno == null || tourData.routno == '') {
      _showMessage("no data found");
    } else {
      Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => TourListPage(tourData: tourData)))
          .then((value) {
        setState(() {
          _initialize(context);
        });
      });
    }
  }

  /*---------------------------------------------------------------------------*/
  // Aufrufen der aktuellen Tour
  /*---------------------------------------------------------------------------*/
  void _processCurrentTour(BuildContext context) async {

    Tour tourData =
        await Tour.getCurrentTour(globals.currentTourNo, globals.currentDrivNo);

    if (tourData == null) {
      _showMessage("Connection to SAP failed");
    } else if (tourData.returnCode != 0) {
      _showMessage(tourData.returnMssg);
    } else {
      Navigator.push(
            context, 
            MaterialPageRoute(builder: (context) => TourListPage(tourData: tourData)))
          .then((value) {
            setState(() {
              _initialize(context);
            });
          }
      );
    }
  }

  /*---------------------------------------------------------------------------*/
  // PopUpMenu
  /*---------------------------------------------------------------------------*/
  Widget popupMenu({bool bottom: false, bool enabled: true}) {

    Icon _icon = Icon(Icons.more_vert);
    if (bottom) _icon = Icon(Icons.menu);
    return PopupMenuButton<CustomPopupMenu>(
      offset: Offset(100, 100),
      onSelected: _selectPopupMenu,
      color: Colors.grey[200],
      elevation: 3.2,
      enabled: enabled,
      icon: _icon,
      itemBuilder: (BuildContext context) {
        return choices
            .where((cond) => !cond.invisible)
            .map((CustomPopupMenu choice) {
          return PopupMenuItem<CustomPopupMenu>(
            height: 10,
            value: choice,
            child: choice.divider
                ? Divider(thickness: 2, height: 3)
                : ListTile(
                    leading: Icon(choice.icon),
                    title: Text(choice.title),
                    enabled: !choice.disabled,
                  ),
          );
        }).toList();
      },
    );
  }

  /*---------------------------------------------------------------------------*/
  // Transferstatus anzeigen
  /*---------------------------------------------------------------------------*/
  void _showTransferStatus(context) {
    if (globals.currentTourNo == null)
      globals.currentTourNo = '';
    if (globals.currentDelvNo == null)
      globals.currentDelvNo = '';
    if (globals.lastReturnCode == null)
      globals.lastReturnCode = 0;
    if (globals.lastReturnMssg == null)
      globals.lastReturnMssg = '';
    if (globals.toBeSynchronized == null)
      globals.toBeSynchronized = false;
    if (globals.lastDateTime == null)
      globals.lastDateTime = '';
    if (globals.lastEvent == null)
      globals.lastEvent = '';

    ProgressDialog progressDialog = new ProgressDialog(context);
    progressDialog.style(
        message: 'connecting...',
        borderRadius: 10.0,
        backgroundColor: Colors.white,
        //progressWidget: CircularProgressIndicator(),
        progressWidget: LinearProgressIndicator(),
    );

    void _synchronize(BuildContext context) async {
      if (globals.currentTourNo != '' && globals.demoModus == false) {
        //Tour tourData = Tour.getBuffer(globals.currentTourNo, globals.currentDrivNo);
        Tour tourData = await Tour.readFromFile(globals.currentTourNo, globals.currentDrivNo);
        progressDialog.show();
        await Tour.syncTour(tourData);
        progressDialog.hide();
        setState(() {
          globals.toBeSynchronized = globals.toBeSynchronized;
          globals.lastReturnMssg = globals.lastReturnMssg;
          globals.lastReturnCode = globals.lastReturnCode;
          globals.lastDateTime = globals.lastDateTime;
        });
        if (globals.lastReturnCode == 0) {
          _showMessage(globals.lastReturnMssg, Colors.green);
        } else {
          _showMessage(globals.lastReturnMssg);
        }
      }
    }
    void _reload(BuildContext context) async {
      if (globals.currentTourNo != '' && globals.demoModus == false) {
        setState(() {
          globals.lastReturnMssg = '';
        });
        progressDialog.show();
        await Tour.getCurrentTour(globals.currentTourNo, globals.currentDrivNo, force:true);
        progressDialog.hide();
        setState(() {
          globals.toBeSynchronized = globals.toBeSynchronized;
          globals.lastReturnMssg = globals.lastReturnMssg;
          globals.lastReturnCode = globals.lastReturnCode;
          globals.lastDateTime = globals.lastDateTime;
          globals.lastDateTime = DateFormat('dd.MM.yyyy - hh:mm').format(DateTime.now());
        });
        if (globals.lastReturnCode == 0) {
          _showMessage(globals.lastReturnMssg, Colors.green);
        } else {
          _showMessage(globals.lastReturnMssg);
        }
      }
    }
    // set up the buttons
    Widget okButton = FlatButton(
      child: Text("OK"),
      onPressed: () { Navigator.of(context).pop(); }
      );
    Widget syncButton = globals.toBeSynchronized 
      ? FlatButton(
      child: Text(H.getText(context,'sync')),
      onPressed: () { 
        _synchronize(context); 
        setState(() {  });
        },
      )
      : FlatButton(
      child: Text(H.getText(context,'load')),
      onPressed: () { 
        _reload(context);
        setState(() {  });
        },
      );
    // set up the AlertDialog
    AlertDialog alert = new AlertDialog(
      title: Text(H.getText(context, "transfer_stat")),
      content: 
      SingleChildScrollView(child: 
        Column(children: <Widget>[
          Row(children: <Widget>[
            Expanded(child:
              Text(H.getText(context, 'demo_modus')), 
            ),
            Container(height: 30), 
            Text(globals.demoModus.toString()),
          ]),
          Row(children: <Widget>[
            Expanded(child:
              Text(H.getText(context, 'curr_tour')), 
            ),
            Container(height: 30), 
            Text(globals.currentTourNo),
          ]),
          Row(children: <Widget>[
            Expanded(child:
              Text(H.getText(context, 'curr_delivery')),
            ), 
            Container(height: 30), 
            Text(globals.currentDelvNo),
          ]),
          Row(children: <Widget>[
            Expanded(child:
              Text('Synchronization needed'), 
            ),
            Container(height: 30),
            Text(globals.toBeSynchronized.toString()),
          ]),
          Row(children: <Widget>[
            Expanded(child:
              Text('Last Return Code'), 
            ),
            Container(height: 30), 
            Text(globals.lastReturnCode.toString()),
          ]),
          Row(
            children: <Widget>[
            //Container(height: 30),
            Flexible(
            //Container( 
              child: Text(globals.lastReturnMssg, 
                textAlign: TextAlign.left, style: TextStyle(color: Colors.black54),),
            ),
          ]),
          Row(children: <Widget>[
            Expanded(child:
              Text('Last Time'), 
            ),
            Container(height: 30), 
            Text(globals.lastDateTime),
          ]),
        ]),
        ),
      actions: [
        syncButton,
        okButton,
      ],
    );
    // show the dialog
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return alert;
        });
      }
      ).then((val) {
         setState(() {});
        }
      );
  }

  /*---------------------------------------------------------------------------*/
  // Message ausgeben
  /*---------------------------------------------------------------------------*/
  void _showMessage(String message, [MaterialColor color = Colors.red]) {
    _scaffoldKey.currentState.showSnackBar(
        new SnackBar(backgroundColor: color, content: new Text(message)));
  }
}
