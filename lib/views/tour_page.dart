import 'package:flutter/material.dart';

import '../globals.dart' as globals;
import '../helpers/helpers.dart';
import '../models/tour.dart';

import '../views/delv_cust.dart';
import '../views/delv_page.dart';
import '../views/evnt_page.dart';

class TourListPage extends StatefulWidget {
  TourListPage({Key key, this.tourData, this.routno, this.drivno}) : super(key: key);

  Tour tourData;
  final String routno;
  final String drivno;

  @override
  _TourListPageState createState() => new _TourListPageState();
}

class _TourListPageState extends State<TourListPage> {
  GlobalKey<ScaffoldState> _scaffoldKey = new GlobalKey<ScaffoldState>();

  Tour tourData;
  bool _filter = false;
  String title = '';
  String bottomHint  = ' ';
  String driverName  = '';
  String driver2Name = '';

  List<CustomPopupMenu> choices;
  CustomPopupMenu buttonChoice;

  void _getTourData() {
    tourData = widget.tourData;
    if (tourData.tourStat == '' || tourData.tourStat == ' ')
      tourData.tourStat = globals.tourStat_initial;
    if (tourData.tourStat == globals.tourStat_started) 
      _filter = true;
    //globals.currentTourStat = tourData.tourStat;

    tourData.delvList.sort((a, b) => a.sequ.compareTo(b.sequ));
  }

  void _getDriver() async {
    driverName = '';
    driver2Name = '';
    if (tourData.driver != null && tourData.driver != '')
      driverName = await Fahrer.getName(tourData.driver);
    if (tourData.driver2 != null && tourData.driver2 != '')
      driver2Name = await Fahrer.getName(tourData.driver2);
  }

  void _buildTitle() {
    if (tourData.tourStat == null) 
      tourData.tourStat = globals.tourStat_initial;
    switch (tourData.tourStat) {
      case globals.tourStat_initial:
        title = H.getText(context, 'tour_preview');
        bottomHint = ' ';
        break;
      case globals.tourStat_started:
        title = H.getText(context, 'tour_in_process');
        bottomHint = H.getText(context, 'tour')+' '+H.getText(context,'started');
        break;
      case globals.tourStat_completed:
        title = H.getText(context, 'tour_overview');
        bottomHint = H.getText(context, 'tour')+' '+H.getText(context,'completed');
        break;
      case globals.tourStat_interrupted:
        title = H.getText(context, 'tour_overview');
        bottomHint = H.getText(context, 'tour')+' '+H.getText(context,'interrupted');
        break;
      default:
        title = H.getText(context, 'tour_overview');
        bottomHint = ' ';
    }
    setState(() {
      title = title;
    });
  }

  void _buildMenue() {
    buttonChoice = new CustomPopupMenu();
    buttonChoice.action = '';

    if (tourData.tourStat == globals.tourStat_initial ||
        tourData.tourStat == globals.tourStat_scheduled) {
      choices = <CustomPopupMenu>[
        CustomPopupMenu(
            title: H.getText(context, 'tour_start'),
            icon: Icons.star,
            action: "start"),
        CustomPopupMenu(divider: true),
        CustomPopupMenu(
            title: H.getText(context, 'back'), 
            icon: Icons.home, 
            action: "back")
      ];
      buttonChoice = choices[0]; 

    } else if (tourData.tourStat == globals.tourStat_started) {
      choices = <CustomPopupMenu>[
        CustomPopupMenu(
            title: H.getText(context, 'next_customer'),
            icon: Icons.fast_forward,
            action: "next"),
        CustomPopupMenu(
            title: H.getText(context, 'fini_tour'),
            icon: Icons.done_all,
            action: "finish"),
        CustomPopupMenu(
            title: H.getText(context, 'tour_interrupt'),
            icon: Icons.timer,
            action: "break"),
        CustomPopupMenu(
            title: H.getText(context, 'tour_history'),
            icon: Icons.history,
            action: "hist"),
        CustomPopupMenu(
            title: H.getText(context, 'tour_reset'),
            icon: Icons.block,
            action: "reset"),
        CustomPopupMenu(divider: true), 
        CustomPopupMenu(
          title: H.getText(context, 'all_deliveries'),
          icon: Icons.filter_list,
          disabled: !_filter,
          action: "filt_all"),
        CustomPopupMenu(
          title: H.getText(context, 'open_deliveries'),
          icon: Icons.filter_list,
          disabled: _filter,
          action: "filt_open"),
        CustomPopupMenu(divider: true),
        CustomPopupMenu(
            title: H.getText(context, 'back'), 
            icon: Icons.home, 
            action: "back")
      ];
      buttonChoice = choices[0];

    } else if (tourData.tourStat == globals.tourStat_interrupted) {
      choices = <CustomPopupMenu>[
        CustomPopupMenu(
            title: H.getText(context, 'tour_cont'),
            icon: Icons.update,
            action: "cont"),
        CustomPopupMenu(
            title: H.getText(context, 'tour_history'),
            icon: Icons.history,
            action: "hist"),
        CustomPopupMenu(divider: true),
        CustomPopupMenu(
            title: H.getText(context, 'back'), 
            icon: Icons.home, 
            action: "back")
      ];
      buttonChoice = choices[0];

    } else { //if (tourData.tourStat == globals.tourStat_completed) {
      choices = <CustomPopupMenu>[
        CustomPopupMenu(
            title: H.getText(context, 'tour_history'),
            icon: Icons.history,
            action: "hist"),
        CustomPopupMenu(
            title: H.getText(context, 'back'), 
            icon: Icons.home, 
            action: "back")
      ];
      buttonChoice = CustomPopupMenu(
          title: H.getText(context, 'back'), 
          icon: Icons.home, 
          action: "back");
    }
  }

  void _selectPopupMenu(CustomPopupMenu choice) async {
    if (choice.disabled == false) {
      setState(() {
        switch (choice.action) {
          case "back":        // Zurück
            Navigator.pop(context, true);
            break;
          case "start":      // Tour starten
            _startTour(context);
            break;
          case "reset":      // Tourstart zurücksetzen
            _resetTour(context);
            break;
          case "finish":     // Tour abschließen
            _completeTour(context);
            break;
          case "break":      // Tour unterbrechen
            _interruptTour(context);
            break;
          case "cont":       // Tour fortsetzen
            _continueTour(context);
            break;
          case "hist":       // Tourverlauf (Ereignisse) anzeigen
            _displayTourHistory(context);
            break;
          case "next":       // Nächste Lieferung
            _nextDelivery(context);
            break;
          case "filt_open":  // Filter: nur offene Lieferungen
            setState(() {
              _filter = true;
            });
            break;
          case "filt_all":   // Filter zurücksetzen
            setState(() {
              _filter = false;
            });
            break;
        }
      });
    }
  }

  // Initialzation
  @override
  void initState() {
    super.initState();
    _getTourData();
    _getDriver();
  }

  void _refreshTour() {
    tourData.openDelv = 0;
    tourData.closedDelv = 0;
    for (Delivery delv in tourData.delvList) {
      if (delv.delvStat == globals.delvStat_completed) {
        tourData.closedDelv++;
      } else if (delv.delvStat == '') {
        tourData.openDelv++;
      }
    }
  }

  Future<bool> _exitApp(BuildContext context) {
    Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    _refreshTour();
    _buildTitle();
    _buildMenue();

    return Scaffold(
      key: _scaffoldKey,
      appBar: PreferredSize(
        preferredSize: Size.fromHeight(70.0),
        child: AppBar(
          backgroundColor: globals.primaryColor,
          //automaticallyImplyLeading: false, 

          leading: new IconButton(
            icon: new Icon(Icons.arrow_back_ios),
            onPressed: () {
              _exitApp(context);
            }),

          title: RichText(
            text: TextSpan(children: [
              TextSpan(text: title, style: globals.styleHeaderTitle),
              TextSpan(text: "\n"),
              TextSpan(
                text: H.getText(context, 'tour') +
                    " " +
                    tourData.routno +
                    " - " +
                    H.getText(context, 'drive') +
                    " " +
                    tourData.drivno,
                style: globals.styleHeaderSubTitle,
              )
            ]),
          ),

          actions: <Widget>[
            if (choices.isEmpty == false) popupMenu(),
          ],
        ),
      ),

      /*--------- Action Button --------------------------------------*/
      floatingActionButton:
          (buttonChoice.action != '')
              ? FloatingActionButton(
                  onPressed: () {
                    _selectPopupMenu(buttonChoice);
                  },
                  tooltip: buttonChoice.title,
                  backgroundColor: globals.actionColor,
                  child: Icon(buttonChoice.icon),
                  //child: popupMenu(bottom: true)
                )
              : FloatingActionButton(
                  backgroundColor: globals.actionColor,
                  onPressed: () {
                    Navigator.pop(context, true);
                  },
                  child: Icon(Icons.home),
                ),

      /*---------- bottomNavigationBar ---------------------------------*/
      bottomNavigationBar: BottomAppBar(
        child: Container(width: double.infinity, color: Colors.black87, 
          child: Text(bottomHint, style: TextStyle(color: Colors.orange),)  
        ), 
      ),

      /*---------- body ------------------------------------------------*/
      body: bodyWidget(context),
    );
  }

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
                    ));
        }).toList();
      },
    );
  }

  Widget bodyWidget(BuildContext context) {
    return Builder(
      builder: (context) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[

            ExpansionTile(
                backgroundColor: Colors.grey[100],
                title: Container(
                  margin: const EdgeInsets.only(
                      top: 0.0, left: 0.0, right: 0.0, bottom: 0.0),
                  child: _filter
                      ? Text(H.getText(context, "open_deliveries"),
                          style: globals.styleTextNormalBoldBlue)
                      : Text(H.getText(context, "all_deliveries"),
                          style: globals.styleTextNormalBoldBlue),
                ),
                children: <Widget>[
                  Container(
                    margin: const EdgeInsets.only(
                        top: 0.0, left: 17.0, right: 17.0, bottom: 5.0),
                    child: Row(children: <Widget>[
                      Expanded(
                        flex: 3,
                        child: Text(H.getText(context, 'driver'),
                            style: globals.styleTextNormal),
                      ),
                      SizedBox(height: 20),
                      Expanded(
                        flex: 7,
                        child: Text(tourData.driver + " - " + driverName,
                            style: globals.styleTextNormal),
                      ),
                    ]),
                  ),
                  Container(
                    margin: const EdgeInsets.only(
                        top: 0.0, left: 17.0, right: 17.0, bottom: 5.0),
                    child: Row(children: <Widget>[
                      Expanded(
                        flex: 3,
                        child: Text(H.getText(context, 'driver2'),
                            style: globals.styleTextNormal),
                      ),
                      SizedBox(height: 20),
                      Expanded(
                        flex: 7,
                        child: Text(tourData.driver2 + " - " + driver2Name,
                            style: globals.styleTextNormal),
                      ),
                    ]),
                  ),
                  Container(
                    margin: const EdgeInsets.only(
                        top: 0.0, left: 17.0, right: 17.0, bottom: 5.0),
                    child: Row(children: <Widget>[
                      Expanded(
                        flex: 3,
                        child: Text(
                            //H.getText(context, 'number_of') +
                            H.getText(context, 'deliveries'),
                            style: globals.styleTextNormal),
                      ),
                      SizedBox(height: 20),
                      Expanded(
                        flex: 7,
                        child: Text(
                            tourData.closedDelv.toString() + " / " +
                            tourData.countDelv.toString(),
                            style: globals.styleTextNormal),
                      ),
                    ]),
                  ),
                  //Divider(color: Colors.grey),
                ],
                onExpansionChanged: (value) {
                  if (value == true) {
                    if (tourData.driver != '' && driverName  == '') {
                      driverName  = Fahrer.getNameSync(tourData.driver);
                    }
                    if (tourData.driver2 != '' && driver2Name == '') {
                      driver2Name = Fahrer.getNameSync(tourData.driver2);
                    }
                    setState(() {
                      driverName  = driverName;
                      driver2Name = driver2Name;
                    });
                  }
                }
                ),

            Expanded(
              child: BuildTourList(
                  tourData: tourData,
                  routno:   widget.routno,
                  drivno:   widget.drivno,
                  filter:   _filter, 
                  onRefresh: () {
                    setState(() {
                      _refreshTour();
                    });
                  },
                ),
            ),
          ],
        );
      });
  }

  /*-----------------------------------------------------------------------------------*/
  // Tour starten
  /*-----------------------------------------------------------------------------------*/
  void _startTour(BuildContext context) async {

    // die Daten der vorigen Tour müssen noch an SAP übertragen werden
    if(globals.toBeSynchronized == true && globals.demoModus == false) {
      H.simpleAlert(context, title, H.getText(context, "M026"),"E");
      return;
    }

    // Abfrage des Kilometerstands
    await _startTourDialog(context)
    .then((val) {
      setState(() {
        if (val == 'OK') {
          // persistentes Speichern & Übertragen an SAP
          setState(() {
            tourData.tourStat     = globals.tourStat_started;
            tourData.startKM      = globals.passKmStand;
          });
          Tour.startTour(tourData); 
          // Anzeige aktualisieren 
          _filter = true;
          _buildMenue();
          _buildTitle();
        }
      });
    });
  }
  /*-----------------------------------------------------------------------------------*/
  // Tour abschließen 
  /*-----------------------------------------------------------------------------------*/
  void _completeTour(BuildContext context) async {

    String message = '';
    String title = H.getText(context, "fini_tour");

    // Alle Lieferungen abgeschlossen?
    bool notCompleted = false;
    for (Delivery delivery in tourData.delvList) {
      if (delivery.delvStat != globals.delvStat_completed){
        notCompleted = true;
        break;
      }
    }
    if (notCompleted) {
      H.simpleAlert(context, title, H.getText(context, "M027"),"E");
      return;
    }

    await _startTourDialog(context, ende:true)
    .then((val) {
      setState(() {
        if (val == 'OK') {
          // persistentes Speichern
          setState(() {
            tourData.tourStat     = globals.tourStat_completed;
            tourData.endeKM       = globals.passKmStand;
          });
          Tour.finishTour(tourData); 
          // Anzeige aktualisieren 
          _filter = true;
          _buildMenue();
          _buildTitle();
        }
      });
    });

  }
  /*-----------------------------------------------------------------------------------*/
  // Tourstart zurücksetzen 
  /*-----------------------------------------------------------------------------------*/
  void _resetTour(BuildContext context) {

    bool delvExists = false;
    String message = '';
    for (Delivery delivery in tourData.delvList) {
      if (delivery.delvStat != '') {
        delvExists = true; 
        break;
      }
    }
    if (delvExists) {
      message = H.getText(context, 'M017', v1: tourData.routno);
      _showMessage(message, Colors.red);
      return;
    }
    setState(() {
      tourData.tourStat  = globals.tourStat_initial;
      tourData.startKM   = 0;
    });
    Tour.resetTour(tourData); 
    // Anzeige aktualisieren 
    setState(() {
       tourData.tourStat = globals.currentTourStat = globals.tourStat_initial;
    });
    _buildMenue();
    _buildTitle();
    message = H.getText(context, 'M019', v1: tourData.routno);
    _showMessage(message, Colors.green);
  }

  /*-----------------------------------------------------------------------------------*/
  // Tour unterbrechen  
  /*-----------------------------------------------------------------------------------*/
  void _interruptTour(BuildContext context) async {

    String message = '';
    String status  = '';
    String title = H.getText(context, "tour_interrupt");

    if (tourData.tourStat != globals.tourStat_started) {
      status = H.getText(context, 'started');
      message = H.getText(context, 'M030', v1: status);
      //_showMessage(message, Colors.red);
      H.simpleAlert(context, title, message, "E");
      return;
    }

    await _breakTourDialog(context)
    .then((reason) {
      setState(() {
        if (reason != '') {
          // persistentes Speichern
          setState(() {
            tourData.tourStat     = globals.tourStat_interrupted;
          });
          Tour.breakTour(tourData, reason); 
          // Anzeige aktualisieren 
          _buildMenue();
          _buildTitle();

          status  = H.getText(context, "interrupted");
          message = H.getText(context, 'M031', v1: status);
          _showMessage(message, Colors.green);
        }
      });
    });

  }

  /*-----------------------------------------------------------------------------------*/
  // Tour fortsetzen 
  /*-----------------------------------------------------------------------------------*/
  void _continueTour(BuildContext context) async {

    String message = '';
    String status  = '';
    String title   = H.getText(context, "tour_cont");

    if (tourData.tourStat != globals.tourStat_interrupted) {
      status = H.getText(context, 'interrupted');
      message = H.getText(context, 'M030', v1: status);
      //_showMessage(message, Colors.red);
      H.simpleAlert(context, title, message, "E");
      return;
    }
    message = H.getText(context, 'M032');
    String answer = await H.confirmDialog(context, title, message);

    if (answer == 'Y') {
      // persistentes Speichern
      setState(() {
        tourData.tourStat     = globals.tourStat_started;
      });
      Tour.continueTour(tourData); 
      // Anzeige aktualisieren 
      _buildMenue();
      _buildTitle();

      status  = H.getText(context, "continued");
      message = H.getText(context, 'M031', v1: status);
      _showMessage(message, Colors.green);
    }
  }

  /*-----------------------------------------------------------------------------------*/
  // Nächste Lieferung ermitteln und aufrufen 
  /*-----------------------------------------------------------------------------------*/
  void _nextDelivery(BuildContext context) {

    int _dlvIndex = 0;
    String _dlvno = '';
    Delivery _delivery;

    if (globals.currentDelvNo == '' || 
        globals.currentDlvIndex == null) {
      globals.currentDelvNo = '';
      for (Delivery delivery in tourData.delvList) {
        if (delivery.delvStat == '' || 
            delivery.delvStat == ' ' ||
            delivery.delvStat == globals.delvStat_initial) {
          delivery.delvStat = globals.delvStat_initial;
          //globals.currentDelvNo   = delivery.dlvno;
          //globals.currentDelvStat = delivery.delvStat;
          //globals.currentDlvIndex = dlvIndex;
          _dlvno = delivery.dlvno;
          _delivery = delivery;
          _dlvIndex = tourData.delvList.indexOf(delivery);
          break;
        }
        _dlvIndex++;
      }
      if (_dlvno == '') {
        //H.message(context, msgId: 'M013', msgV1: tourData.routno);
        String msg = H.getText(context, 'M013', v1: tourData.routno);
        _showMessage(msg);
        return;
      }
    } else {
      _dlvno    = globals.currentDelvNo; 
      _dlvIndex = globals.currentDlvIndex;
      for (Delivery delivery in tourData.delvList) {
        if (delivery.dlvno == _dlvno) {
          _dlvno = delivery.dlvno;
          _delivery = delivery;
          _dlvIndex = tourData.delvList.indexOf(delivery);
          break;
        }
        _dlvIndex++; 
      }
    }
    _processDelivery(context, _dlvno, _dlvIndex);
  }
  /*-----------------------------------------------------------------------------------*/
  // Tourverlauf anzeigen 
  /*-----------------------------------------------------------------------------------*/
  void _displayTourHistory(BuildContext context) {

    Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => EventPage(
              tourData: tourData,
        ))
    );
  }
  /*-----------------------------------------------------------------------------------*/
  // Lieferung bearbeiten 
  /*-----------------------------------------------------------------------------------*/
  void _processDelivery(BuildContext context, String dlvno, int dlvIndex) {

    Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => DeliveryCust(
              tourData: tourData,
              routno:   tourData.routno,
              drivno:   tourData.drivno,
              delvno:   dlvno,
              dlvIndex: dlvIndex),
        ))
      .then((value) {
        setState(() {
          if (globals.currentDelvNo == dlvno) {
            tourData.delvList[dlvIndex].delvStat = globals.currentDelvStat; 
          }
        });
      });
  }

  /*-----------------------------------------------------------------------------------*/
  // Start Dialog
  /*-----------------------------------------------------------------------------------*/
  _startTourDialog(BuildContext context, {bool ende: false}) async {

    String title; 
    if (ende == true) {
      title = H.getText(context, 'fini_tour');
    } else {
      title = H.getText(context, 'tour_start');
    }

    return showDialog(
      context: context,
      builder: ((BuildContext context) {
        return StartTourDialog(
            ende: ende,
            title: title, 
            routno: tourData.routno, 
            drivno: tourData.drivno);
      }),
    );
  }

  /*-----------------------------------------------------------------------------------*/
  // Unterbrechen -> Dialog starten
  /*-----------------------------------------------------------------------------------*/
  _breakTourDialog(BuildContext context, ) async {

    String title; 
    title = H.getText(context, 'tour_interrupt');

    return showDialog(
      context: context,
      builder: ((BuildContext context) {
        return BreakTourDialog(
            title: title, 
            routno: tourData.routno, 
            drivno: tourData.drivno);
      }),
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

class BuildTourList extends StatelessWidget {

  BuildTourList({
    this.tourData, 
    this.routno, 
    this.drivno, 
    this.filter,
    this.onRefresh,
    });

  Tour tourData;

  final String routno;
  final String drivno;
  final bool filter;
  final VoidCallback onRefresh;
//final Function(int) onRefresh;  (mit Return-Parametern)

  @override
  Widget build(BuildContext context) {

    return StatefulBuilder(builder: (innerContext, innerSetState) {
      return ListView.builder(
        itemCount: tourData.delvList.length,
        itemBuilder: (context, index) {
        return (filter &&
                tourData.delvList[index].delvStat == globals.delvStat_completed)
            ? Container()
            : Card(
                elevation: 5,
                child: Container(
                  margin: EdgeInsets.fromLTRB(0.0, 10.0, 0.0, 10.0),
                  child: InkWell(
                    onTap: () {
                      innerSetState(() {
                        _processDelivery(context, tourData.delvList[index].dlvno, index);
                      });
                    },
                    child: Row(children: <Widget>[
                      Expanded(
                          flex: 2,
                          child: Column(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              mainAxisAlignment: MainAxisAlignment.start,
                              children: <Widget>[
                                if (tourData.delvList[index].barkz == true)
                                  Container(
                                    child: Text(H.getText(context,'cash')+'!',
                                      style: TextStyle(
                                          fontSize: 18, color: Colors.white),
                                    ),
                                    padding:
                                        EdgeInsets.only(left: 10, right: 10),
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(8),
                                      color: globals.primaryColor,
                                    ),
                                    height: 20,
                                  )
                              ])),
                      Expanded(
                        flex: 7,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            Text(tourData.delvList[index].name1,
                                style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    height: 1.3,
                                    fontSize: 18)),
                            Text(
                                tourData.delvList[index].stras +
                                    ' ' +
                                    tourData.delvList[index].hausn,
                                style: TextStyle(
                                    fontWeight: FontWeight.normal,
                                    height: 1.3,
                                    fontSize: 18)),
                            Text(
                                tourData.delvList[index].pstlz +
                                    ' ' +
                                    tourData.delvList[index].ort01,
                                style: TextStyle(
                                    fontWeight: FontWeight.normal,
                                    height: 1.3,
                                    fontSize: 18)),
                            if (tourData.delvList[index].hinweis != "")
                              Text(tourData.delvList[index].hinweis,
                                  style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      height: 1.6,
                                      fontSize: 18)),
                          ],
                        ),
                      ),
                      Expanded(
                        flex: 1,
                        child: Column(
                          children: <Widget>[
                            (tourData.delvList[index].delvStat ==
                                    globals.delvStat_completed)
                                ? new Icon(Icons.done, color: Colors.green)
                                : (tourData.delvList[index].delvStat ==
                                    globals.delvStat_inProcess)
                                  ? new Icon(Icons.star, color: Colors.green)
                                  : new Container(),
                          ],
                        ),
                      ),
                    ]),
                  ),
                ),
              );
      },
    );
    });
  }

  void _processDelivery(BuildContext context, String dlvno, int dlvIndex) {
    Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => DeliveryCust(
              tourData: tourData,
              routno:   tourData.routno,
              drivno:   tourData.drivno,
              delvno:   dlvno,
              dlvIndex: dlvIndex),
        ))
      .then((value) {
        /*
          if (globals.currentDelvNo == dlvno) {
            tourData.delvList[dlvIndex].delvStat = globals.currentDelvStat; 
          }
        */
        onRefresh();    // Callback
      }
    );
  }

}

/*-----------------------------------------------------------------------------------*/
// Dialog zum Starten der Tour
/*-----------------------------------------------------------------------------------*/
class StartTourDialog extends StatefulWidget {

  StartTourDialog({this.ende, this.title, this.routno, this.drivno});

  final bool ende;
  final String title;
  final String routno;
  final String drivno;

  @override
  _StartTourDialogState createState() => _StartTourDialogState();
}

class _StartTourDialogState extends State<StartTourDialog> {

  String _title;
  String _routno;
  String _drivno;
  bool _ende; 

  TextEditingController _controller = TextEditingController();
  FocusNode _focusNode = FocusNode();
  bool   _invalid = false;
  String _errMsg = '';

  @override
  void initState() {
    super.initState();
    _title = widget.title;
    _routno = widget.routno;
    _drivno = widget.drivno;
    _ende = widget.ende;
    _controller.clear();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(_title),
      actions: <Widget>[
        new FlatButton(
          child: new Text(H.getText(context, 'conf')),
          color: globals.primaryColor,
          textColor: Colors.white,
          shape: new RoundedRectangleBorder(
            borderRadius: new BorderRadius.circular(5.0)),
          onPressed: () {
            _checkKmStand(context);
            setState(() {
              if (_invalid == false) {
                globals.passKmStand = int.parse(_controller.text);
                Navigator.of(context).pop('OK');
              }
            });
          },
        ),
        new FlatButton(
          child: new Text(H.getText(context, 'canc')),
          color: globals.primaryColor,
          textColor: Colors.white,
          shape: new RoundedRectangleBorder(
            borderRadius: new BorderRadius.circular(5.0)),
          onPressed: () {
            Navigator.of(context).pop('');
          },
        )
      ],
      content: Container(
          height: 130,
          child: Column(
            children: <Widget>[
              Text(H.getText(context, "M015")),
              SizedBox(height: 20),
              TextField(
                controller: _controller,
                focusNode: _focusNode,
                autofocus: true,
                onSubmitted: (value) {
                  if (_controller.text != '') {
                    _checkKmStand(context);
                  }
                },
                decoration: InputDecoration(
                    labelStyle: TextStyle(color: globals.primaryColor),
                    labelText: H.getText(context, "odometer"),
                    errorText: _invalid ? _errMsg : null,
                    hintText: 'km',
                    //border: InputBorder.none,
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.all(Radius.circular(5.0)),
                      borderSide: BorderSide(color: globals.primaryColor)),
                    filled: true,
                    contentPadding:
                      EdgeInsets.only(bottom: 10.0, left: 10.0, right: 10.0),
                ),
              ),
            ],
          )),
    );
  }

  void _checkKmStand(context) {
    setState(() {
      _invalid = false;
      _controller.text = _controller.text.trim();
      _errMsg = '';
    });
    if (_controller.text == '') {
      setState(() {
        _invalid = true;
        _errMsg = H.getText(context, "M015");
      });
    } else if (!Helpers.isInt(_controller.text)) {
      _invalid = true;
      _errMsg = H.getText(context, "M002");
    } else if (int.parse(_controller.text) > 999999) {
      _invalid = true;
      _errMsg = H.getText(context, "M016");
    } else if (_ende = true) {
      //End-Kilometerstand prüfen 

    }
  }
}

/*-----------------------------------------------------------------------------------*/
// Dialog zum Unterbrechen der Tour
/*-----------------------------------------------------------------------------------*/
class BreakTourDialog extends StatefulWidget {

  BreakTourDialog({this.title, this.routno, this.drivno});

  final String title;
  final String routno;
  final String drivno;

  @override
  _BreakTourDialogState createState() => _BreakTourDialogState();
}

class _BreakTourDialogState extends State<BreakTourDialog> {
  String _title;
  String _routno;
  String _drivno;

  TextEditingController _controller = TextEditingController();
  FocusNode _focusNode = FocusNode();
  bool _invalid = false;
  List<Parameter> reasonList = [];

  @override
  void initState() {
    super.initState();
    _title = widget.title;
    _routno = widget.routno;
    _drivno = widget.drivno;
    _controller.clear();
  }

  @override
  Widget build(BuildContext context) {
    
    var reasonMap = Events.getReasons(context);
    reasonMap.forEach((key, value) => reasonList.add(Parameter(key, value)));
    
    return AlertDialog(
      title: Text(_title),
      actions: <Widget>[
        new FlatButton(
          child: new Text(H.getText(context, 'canc')),
          color: globals.primaryColor,
          textColor: Colors.white,
          shape: new RoundedRectangleBorder(
            borderRadius: new BorderRadius.circular(5.0)),
          onPressed: () {
            Navigator.of(context).pop('');
          },
        )
      ],
      content: 
      Container(
        height: 300, 
        width: 250, 
        child: ListView.builder(
          shrinkWrap: true,
          itemCount: reasonList.length,
          itemBuilder: (context, index) {
          return Container(
            margin: EdgeInsets.fromLTRB(10.0, 5.0, 10.0, 0.0),
            child: RaisedButton(
              //splashColor: Colors.blueGrey,
              color: globals.primaryColor,
              textColor: Colors.white,
              shape: new RoundedRectangleBorder(
                borderRadius: new BorderRadius.circular(5.0)),
              onPressed: () {
                setState(() {
                  Navigator.of(context).pop(reasonList[index].key);
                });
              },
              child: Text(reasonList[index].val,  
                style: TextStyle(color: Colors.white, fontSize:16)),
            ),
          );
          },
        ),
      
      ),
    );
  }
  
}
