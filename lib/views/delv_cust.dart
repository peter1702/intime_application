import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:maps_launcher/maps_launcher.dart';

import '../models/tour.dart';
import '../helpers/helpers.dart';
import '../globals.dart' as globals;

import '../views/delv_page.dart'; // Page mit Tabs
import '../views/delv_leer.dart'; // Leerguterfassung
import '../views/tour_page.dart'; // Tour-Übersicht
import '../views/delv_item.dart'; // Positionsrückmeldung
import '../views/bill_page.dart'; // Abrechnung
import '../views/cash_page.dart'; // Inkasso, Barzahlung
import '../views/gallery.dart';   // Anzeigen der Bilder
import '../views/bottom_bar.dart';  

class DeliveryCust extends StatefulWidget {
  DeliveryCust(
      {Key key,
      @required this.tourData,
      @required this.routno,
      @required this.drivno,
      @required this.delvno,
      @required this.dlvIndex})
      : super(key: key);

  final Tour tourData;
  final String routno;
  final String drivno;
  final String delvno;
  final int dlvIndex;

  @override
  _DeliveryCustState createState() => new _DeliveryCustState();
}

class _DeliveryCustState extends State<DeliveryCust> {
  final GlobalKey<ScaffoldState> _scaffoldKey = new GlobalKey<ScaffoldState>();

  Delivery delivery;

  int dlvIndex;
  Tour tourData;
  String delvno;

  List<CustomPopupMenu> choices = [];
  CustomPopupMenu buttonChoice;
  String bottomHint = '';
  String title = '';
  bool readonly = true;

  _initializeData() {
    tourData = widget.tourData;
    delivery = tourData.delvList[widget.dlvIndex];
    if (delivery.delvStat == null ||
        delivery.delvStat == '' ||
        delivery.delvStat == ' ') {
      delivery.delvStat = globals.delvStat_initial;
    }
    dlvIndex = widget.dlvIndex;
    delvno   = widget.delvno;
  }
  Future<bool> _exitApp(BuildContext context) {
    //print("Exit App -> data changed: " + globals.changeData.toString());
    if (readonly == false && globals.changeData == true) {
      Tour.saveDelivery(tourData, widget.dlvIndex);
      globals.currentDelvNo = delivery.dlvno;
      globals.currentDelvStat = delivery.delvStat;
      globals.changeData = false;
    } else {
      if (globals.currentDelvNo == delivery.dlvno) {
        globals.currentDelvStat = delivery.delvStat;
      }
    }
    Navigator.pop(context, true);
  }
  
  // Initialization
  @override
  void initState() {
    super.initState();
    _initializeData();
  }

  void _refreshDelivery() {
    delivery.openItems = 0;
    delivery.closedItems = 0;
    for (DelvItem item in delivery.itemList) {
      if (item.completed == true) {
        delivery.closedItems++;
      } else {
        delivery.openItems++;
      }
    }
  }

  void _buildMenue() {
    choices = [];
    title = '';
    bottomHint = '';
    buttonChoice = new CustomPopupMenu();
    buttonChoice.action = '';
    readonly = true;
    // 1) die Lieferung könnte gestartet werden
    if (tourData.tourStat == globals.tourStat_started) {
      if (delivery.delvStat == globals.delvStat_initial) {
        if (globals.currentDelvNo == '' ||
            globals.currentDelvStat != globals.delvStat_inProcess) {
          choices = <CustomPopupMenu>[
            CustomPopupMenu(
              title: H.getText(context,'delv_start'),
              icon: Icons.star,text:'Start',
              action: "start"),
            CustomPopupMenu(
              title: H.getText(context,'billing'),
              icon: Icons.account_balance,
              action: "bill"),
          ];
          // Action Button 
          buttonChoice = choices[0];
          // Titel
          title = H.getText(context, 'next_customer');
          // Hinweis
          bottomHint = H.getText(context, 'tour') + ' ' + H.getText(context, 'started');
        } else {
          // keine Menüeinträge 
          bottomHint =
              H.getText(context, 'curr_delivery', v1: globals.currentDelvNo);
        }
      }
      // 2) Lieferung ist bereits gestartet 
      if (delivery.delvStat == globals.delvStat_inProcess &&
          tourData.tourStat == globals.tourStat_started) {
        readonly = false;
        choices = <CustomPopupMenu>[
          CustomPopupMenu(
              title: H.getText(context,'unload'),
              icon: Icons.transfer_within_a_station,
              action: "proc"),
          CustomPopupMenu(
              title: H.getText(context,'delv_interrupt'), 
              icon: Icons.timer, 
              action: "stop"),
          CustomPopupMenu(
              title: H.getText(context,'billing'), 
              icon: Icons.account_balance, 
              action: "bill"),
          CustomPopupMenu(
              title: H.getText(context,'cashbox'), 
              icon: Icons.attach_money, 
              action: "cash"),
          CustomPopupMenu(
              title: H.getText(context,'delv_complete'), 
              icon: Icons.done_all, 
              action: "finish"),
          CustomPopupMenu(
              title: H.getText(context,'delv_reset'), 
              icon: Icons.block, 
              action: "reset"),
        ];
        // ActionButton 
        buttonChoice = choices[0];
        // Titel  
        title = H.getText(context, 'curr_customer');
        // Hinweis 
        bottomHint = H.getText(context, 'delivery') +
            ' ' +
            H.getText(context, 'started');
      }
      if (bottomHint == '') {
        bottomHint = H.getText(context, 'tour', v1: globals.currentTourNo) +
            ' ' +
            H.getText(context, 'started');
      }
    }
    if (delivery.delvStat == globals.delvStat_completed) {
      bottomHint = H.getText(context, 'delivery') +
          ' ' +
          H.getText(context, 'completed');
    }
    if (delivery.delvStat == globals.delvStat_postponed   ||
        tourData.tourStat == globals.tourStat_interrupted ) {
      readonly = false;
      choices = <CustomPopupMenu>[
        CustomPopupMenu(
          title: H.getText(context,'continue'),
          icon: Icons.update,
          action: "cont")
      ];
      bottomHint = H.getText(context, 'delivery') +
          ' ' +
           H.getText(context, 'interrupted');
    } else if (tourData.tourStat == globals.tourStat_interrupted) {
      bottomHint = H.getText(context, 'tour') +
          ' ' +
           H.getText(context, 'interrupted');
    }
    if (choices.isEmpty == false) {
      choices.add(CustomPopupMenu(divider: true));
    }
    // Back (Zurück) als letzten Eintrag 
    choices.add(CustomPopupMenu(
      title: H.getText(context, 'back'), 
      icon: Icons.home, 
      action: "back"));
    // Titel (Default) 
    if (title == '') { 
      title = H.getText(context, 'disp_customer');
    }
  }

  // Aufruf aus dem Popup-Menü
  void _selectPopupMenu(CustomPopupMenu choice) async {
    if (choice.disabled == false) {
      setState(() {
        _userCommand(choice.action);
      });
    }
  }
  void _userCommand(String action) {
        switch (action) {
          case "back":
            // Zurück
            Navigator.pop(context, true);
            break;
          case "start":
            // Entladung starten
            _startDelivery(context);
            break;
          case "proc":
            // Entladung bearbeiten
            _processDelivery(context);
            break;
          case "cash":
            // Barzahlungsdialog
            _displayInkasso(context);
            break;
          case "stop":
            // Entladung unterbrechen
            _interruptDelivery(context);
            break;
          case "cont":
            // Entladung fortsetzen (nach Unterbrechung)
            _continueDelivery(context);
            break;
          case "bill":
            // Lieferung abrechnen
            _billDelivery(context);
            break;
          case "finish":
            // Entladung abschließen
            _completeDelivery(context);
            break;
          case "reset":
            // Start der Lieferung zurücksetzen
            _resetDelivery(context);
            break;
        }
  }
  // Aufruf von Bottom Navigation
  void _selectedTab(String action) {
    setState(() {
      _userCommand(action);
    });
  }

  @override
  Widget build(BuildContext context) {
    
    _refreshDelivery();
    _buildMenue();

    return new WillPopScope(
      onWillPop: () => _exitApp(context),
      child: new Scaffold(
      backgroundColor: Colors.grey[100],
      key: _scaffoldKey,
      /* ---------- appBar ------------------------------------------------*/
      appBar: PreferredSize(
        preferredSize: Size.fromHeight(70.0),
        child: AppBar(
          backgroundColor: globals.primaryColor,
          //automaticallyImplyLeading: false, // Don't show the leading button
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
                text: H.getText(context, 'delivery', v1: delivery.dlvno),
                style: globals.styleHeaderSubTitle,
              )
            ]),
          ),
          // PopupMenü
          actions: <Widget>[
            if (choices.isEmpty == false) popupMenu(),
          ],
        ),
      ),
      /*--------- Action Button -----------------------------------------*/

      floatingActionButton: (buttonChoice.action != '')
        ? FloatingActionButton(
            onPressed: () {
              _selectPopupMenu(buttonChoice);
            },
            tooltip: buttonChoice.title,
            backgroundColor: globals.actionColor,
            child: buttonChoice.text != null &&  buttonChoice.text != ''
            ? Text(buttonChoice.text)
            : Icon(buttonChoice.icon),
            //child: popupMenu(bottom: true) // das geht auch
          )
        : Container(),

      bottomNavigationBar: 
      delivery.delvStat != globals.delvStat_inProcess || tourData.tourStat != globals.tourStat_started
      ? BottomAppBar(
          child: Container(
            width: double.infinity,
            color: Colors.black87,
            child: Text(
              bottomHint,
              style: TextStyle(color: Colors.orange),
            )),
        )
      : FABBottomAppBar(
          centerItemText: buttonChoice.title,
          color: Colors.grey,
          selectedColor: globals.primaryColor,
          notchedShape: CircularNotchedRectangle(),
          onTabSelected: _selectedTab,
          items: [
            FABBottomAppBarItem(
              iconData: Icons.timer, 
              text: H.getText(context,'delv_interrupt_s'),
              action: 'stop'),
            FABBottomAppBarItem(
              iconData: Icons.account_balance, 
              text: H.getText(context,'billing'),
              action: 'bill'),
            FABBottomAppBarItem(
              iconData: Icons.attach_money, 
              text: H.getText(context,'cashbox'),
              action: 'cash'),
            FABBottomAppBarItem(
              iconData: Icons.done_all, 
              text: H.getText(context,'delv_complete'),
              action: 'finish'),
          ],
        ),
      floatingActionButtonLocation: delivery.delvStat != globals.delvStat_inProcess
      ? FloatingActionButtonLocation.endFloat
      : FloatingActionButtonLocation.centerDocked,

      /*---------- body ------------------------------------------------*/
      body: SingleChildScrollView(
        child: SafeArea(
          child: Column(children: <Widget>[
            BuildAddress(
              tourData: tourData,
              delivery: delivery,
              routno: widget.routno,
              drivno: widget.drivno,
              dlvIndex: widget.dlvIndex,
              readonly: readonly,
              ),
            BuildDelivery(
              tourData: tourData,
              delivery: delivery,
              routno: widget.routno,
              drivno: widget.drivno,
              dlvIndex: widget.dlvIndex,
              readonly: readonly,
              onRefresh: () {
                setState(() {
                  _refreshDelivery();
                  _buildMenue();
                });
              }, 
            ),
          ]),
        ),
      ),
    ));
  }

  /*---------------------------------------------------------------------------*/
  // Message ausgeben
  /*---------------------------------------------------------------------------*/
  void _showMessage(String message, [MaterialColor color = Colors.red]) {

    _scaffoldKey.currentState.showSnackBar(
        new SnackBar(backgroundColor: color, content: new Text(message)));
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

  /*-----------------------------------------------------------------------------------*/
  // Entladung starten
  /*-----------------------------------------------------------------------------------*/
  void _startDelivery(BuildContext context) async {

    String title = H.getText(context, 'delv_start');

    await _startDeliveryDialog(context, title, 'M014').then((answer) {
      setState(() {
        if (answer == null) {
          answer = false;
        }
        if (answer == true) {
          delivery.delvStat = globals.delvStat_inProcess;
          globals.currentDelvNo   = delivery.dlvno;
          globals.currentDlvIndex = dlvIndex;
          globals.currentDelvStat = globals.delvStat_inProcess;

          // persistentes Speichern
          Tour.startDelivery(tourData,dlvIndex); 

          // Menü neu aufbauen 
          _refreshDelivery();
          _buildMenue();
        }
      });
    });
  }

  /*-----------------------------------------------------------------------------------*/
  // Start Dialog
  /*-----------------------------------------------------------------------------------*/
  Future<bool> _startDeliveryDialog(BuildContext context, String title, String msgNo, {bool ende:false}) {

    return showDialog(
          context: context,
          child: new AlertDialog(
            title: new Text(title),
            content: new Text(H.getText(context, msgNo, v1: delivery.dlvno)),
            actions: <Widget>[
              new FlatButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: new Text(H.getText(context, 'no'),
                    style: globals.styleTextBigBlue),
              ),
              new FlatButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: new Text(H.getText(context, 'yes'),
                    style: globals.styleTextBigBlue),
              ),
            ],
          ),
        ) ??
        false;
  }

  /*-----------------------------------------------------------------------------------*/
  // Entladung bearbeiten
  /*-----------------------------------------------------------------------------------*/
  void _processDelivery(BuildContext context) async {
    
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => DeliveryPage(
            tourData: tourData,
            routno: tourData.routno,
            drivno: tourData.drivno,
            dlvIndex: dlvIndex,
            readonly: readonly),
      ),
    ).then((val) {
      if (globals.currentDelvNo == delivery.dlvno) {
        tourData.delvList[dlvIndex].delvStat = delivery.delvStat = globals.currentDelvStat; 
      }
    });
    setState(() {
      _refreshDelivery();
      _buildMenue();
    });
  }

  /*-----------------------------------------------------------------------------------*/
  // Entladung unterbrechen
  /*-----------------------------------------------------------------------------------*/
  void _interruptDelivery(BuildContext context) async {

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

    await _interruptDeliveryDialog(context)
    .then((reason) {
      setState(() {
        if (reason != '') {
          // persistentes Speichern
          setState(() {
            tourData.tourStat = globals.tourStat_interrupted;
          });
          Tour.breakTour(tourData, reason, delvno: delivery.dlvno); 
          // Anzeige aktualisieren 
          setState(() {
            _refreshDelivery();
            _buildMenue();
          });

          status  = H.getText(context, "interrupted");
          message = H.getText(context, 'M031', v1: status);
          _showMessage(message, Colors.green);
        }
      });
    });

  }
  /*-----------------------------------------------------------------------------------*/
  // Tour / Lieferung fortsetzen nach Unterbrechung
  /*-----------------------------------------------------------------------------------*/
  void _continueDelivery(BuildContext context) async {

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
      Tour.continueTour(tourData, delvno: delivery.dlvno); 
      // Anzeige aktualisieren 
      setState(() {
        _refreshDelivery();
        _buildMenue();
      });

      status  = H.getText(context, "continued");
      message = H.getText(context, 'M031', v1: status);
      _showMessage(message, Colors.green);
    }
  }

  /*-----------------------------------------------------------------------------------*/
  // Unterbrechen -> Dialog starten
  /*-----------------------------------------------------------------------------------*/
  _interruptDeliveryDialog(BuildContext context, ) async {

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

  /*-----------------------------------------------------------------------------------*/
  // Start der Entladung zurücksetzen
  /*-----------------------------------------------------------------------------------*/
  void _resetDelivery(BuildContext context) async {

    String message = '';
    String title   = H.getText(context, "delv_reset");

    bool itemExists = false;
    bool lgutExists = false;

    for (DelvItem delvItem in delivery.itemList) {
      if (delvItem.completed == true) {
        itemExists = true; 
        break;
      }
    }
    for (Leergut leergut in delivery.lgutList) {
      if (leergut.menge > 0) {
        lgutExists = true; 
        break;
      }
    }
    if (itemExists || lgutExists) {
      message = H.getText(context, 'M018', v1: delivery.dlvno);
      //_showMessage(message, Colors.red);
      H.simpleAlert(context, title, message, "E");
      return;
    }

    //String answer = await H.confirmDialog(context, title, 'blabla'); -> Y or N

    await _startDeliveryDialog(context, title, 'M021').then((answer) {

      if (answer == true) {
        setState(() {
          delivery.delvStat = globals.delvStat_initial;
          globals.currentDelvNo   = '';
          globals.currentDlvIndex = 0;
          globals.currentDelvStat = globals.delvStat_initial;
        });

        // persistentes Speichern
        Tour.resetDelivery(tourData, delivery); 
    
        // Anzeige aktualisieren 
        _refreshDelivery();
        _buildMenue();

        // Success Info 
        message = H.getText(context, 'M020', v1: tourData.routno);
        _showMessage(message, Colors.green);
      }
    });
  }

  /*-----------------------------------------------------------------------------------*/
  // Entladung abschließen
  /*-----------------------------------------------------------------------------------*/
  void _completeDelivery(BuildContext context) async {

    String message = '';
    String title = H.getText(context, "delv_finish");

    // Wurden alle Positionen erfasst? 
    bool notCompleted = false;
    for (DelvItem item in delivery.itemList) {
      if (item.completed != true){
        notCompleted = true;
        break;
      }
    }
    if (notCompleted) {
      H.simpleAlert(context, title, H.getText(context, "M022"),"E");
      return;
    }
    // Abrechnung erfolgt?
    if (delivery.signCustomer != true) {
      H.simpleAlert(context, title, H.getText(context, "M023"),"E");
      return;      
    }
    // Bargeld kassiert?
    if (delivery.barkz == true && delivery.payment == 0.0) {
      H.simpleAlert(context, title, H.getText(context, "M024"),"E");
      return; 
    }

    await _startDeliveryDialog(context, title, 'M028', ende:true).then((answer) {

      if (answer == true) {
        // Okay
        setState(() {
          delivery.delvStat = globals.delvStat_completed;
          delivery.changeKz = 'U';
          //globals.currentDelvNo   = '';
          //globals.currentDlvIndex = 0;
          globals.currentDelvStat = globals.delvStat_completed;
        });

        // persistentes Speichern
        Tour.finishDelivery(tourData, dlvIndex); 
    
        // Anzeige aktualisieren 
        _refreshDelivery();
        _buildMenue();

        // Success Info 
        message = H.getText(context, 'M025', v1: tourData.routno);
        _showMessage(message, Colors.green);
      }
    });
  }

  /*-----------------------------------------------------------------------------------*/
  // -> Inkasso, Barzahlung 
  /*-----------------------------------------------------------------------------------*/
  void _displayInkasso(BuildContext context) async {

      Navigator.push(context, 
        MaterialPageRoute(builder: (context) => InkassoPage(
            tourData: tourData,
            routno: tourData.routno,
            drivno: tourData.drivno,
            dlvIndex: dlvIndex,
            readonly: readonly),
        ),
      );
  }

  /*-----------------------------------------------------------------------------------*/
  // -> Abrechnung 
  /*-----------------------------------------------------------------------------------*/
  void _billDelivery(BuildContext context) async {

    Navigator.push(context, 
        MaterialPageRoute(builder: (context) => BillingPage(
            tourData: tourData,
            routno: tourData.routno,
            drivno: tourData.drivno,
            dlvIndex: dlvIndex,
            readonly: readonly,
          ),
        ),
      );
  }

}
/*-------------------------------------------------------------------------------------*/
// Klasse Build Delivery (Anzeige Anzahl Vollgut/Leergut)
/*-------------------------------------------------------------------------------------*/
class BuildDelivery extends StatelessWidget {
  
  BuildDelivery({
      this.tourData,
      this.delivery,
      this.routno,
      this.drivno,
      this.dlvIndex,
      this.readonly: true,
      this.onRefresh,
    });

  Tour tourData;
  Delivery delivery;

  final String routno;
  final String drivno;
  final int dlvIndex;
  final bool readonly;
  final VoidCallback onRefresh;
//final Function(int) onRefresh;  (mit Return-Parametern)

  @override
  Widget build(BuildContext context) {
    return StatefulBuilder(builder: (innerContext, innerSetState) {
    return Container(
      margin: EdgeInsets.fromLTRB(10.0, 5.0, 10.0, 5.0),
      color: Colors.grey[100],
      child: Column(children: <Widget>[
        // Vollgut 
        Card(
          elevation: 5,
          child: Column(children: <Widget>[
            Container(
              alignment: Alignment.centerLeft,
              margin: EdgeInsets.fromLTRB(10.0, 20.0, 10.0, 10.0),
              //
              child: Row(
                children: <Widget>[
                  Expanded(
                    flex: 5,
                    child: Text(
                      H.getText(context, 'delivery') +
                          ' ' +
                          H.getText(context, 'filled'),
                      textAlign: TextAlign.left,
                      style: globals.styleTextBigBold,
                    ),
                  ),
                  Expanded(
                    flex: 5,
                    child: Text(
                          delivery.closedItems.toString() + 
                          " / "+
                          delivery.itemList.length.toString() +
                          " " +
                          H.getText(context, 'items'),
                        textAlign: TextAlign.right,
                        style: globals.styleTextNormal),
                  ),
                ],
              ),
            ),
            //
            Container(
              margin: EdgeInsets.fromLTRB(10.0, 10.0, 10.0, 10.0),
              alignment: Alignment.centerLeft,
              child: GestureDetector(
                onTap: () { 
                  innerSetState(() { 
                    _processVollgut(context); 
                  });
                },
                child: new Text(
                  readonly
                      ? H.getText(context, 'disp').toUpperCase()
                      : H.getText(context, 'proc').toUpperCase(),
                  textAlign: TextAlign.left,
                  style: globals.styleFlatButton,
                ),
              ),
            ),
            //
          ]),
        ),
        // Leergut 
        Card(
          elevation: 5,
          child: Column(children: <Widget>[
            Container(
              alignment: Alignment.centerLeft,
              margin: EdgeInsets.fromLTRB(10.0, 20.0, 10.0, 10.0),
              child: Row(
                children: <Widget>[
                  Expanded(
                    flex: 5,
                    child: Text(
                          H.getText(context, 'return') +
                          ' ' +
                          H.getText(context, 'empties'),
                      textAlign: TextAlign.left,
                      style: globals.styleTextBigBold,
                    ),
                  ),
                  Expanded(
                    flex: 5,
                    child: Text(
                          delivery.lgutList.length.toString() +
                          " " +
                          H.getText(context, 'items'),
                        textAlign: TextAlign.right,
                        style: globals.styleTextNormal),
                  ),
                ],
              ),
            ),
            Container(
              margin: EdgeInsets.fromLTRB(10.0, 10.0, 10.0, 10.0),
              alignment: Alignment.centerLeft,
              child: GestureDetector(
                onTap: () { 
                  innerSetState(() { 
                    _processLeergut(context); 
                  });
                },
                child: new Text(
                  readonly
                      ? H.getText(context, 'disp').toUpperCase()
                      : H.getText(context, 'proc').toUpperCase(),
                  textAlign: TextAlign.left,
                  style: globals.styleFlatButton,
                ),
              ),
            ),
          ]),
        ),
        /* Abrechnung 
        Card(
          elevation: 5,
          child: Column(children: <Widget>[
            Container(
              alignment: Alignment.centerLeft,
              margin: EdgeInsets.fromLTRB(10.0, 20.0, 10.0, 10.0),
              child: Row(
                children: <Widget>[
                  Expanded(
                    flex: 5,
                    child: Text(H.getText(context, 'billing'),
                      textAlign: TextAlign.left,
                      style: globals.styleTextBigBold,
                    ),
                  ),
                  Expanded(
                    flex: 5,
                    child: delivery.signCustomer
                    ? Icon(Icons.done, )
                    : Container(),
                  ),
                ],
              ),
            ),
            Container(
              margin: EdgeInsets.fromLTRB(10.0, 10.0, 10.0, 10.0),
              alignment: Alignment.centerLeft,
              child: GestureDetector(
                onTap: () { 
                  innerSetState(() { 
                    _billDelivery(context); 
                  });
                },
                child: new Text(
                  readonly
                  ? H.getText(context, 'disp').toUpperCase()
                  : H.getText(context, 'proc').toUpperCase(),
                  textAlign: TextAlign.left,
                  style: globals.styleFlatButton,
                ),
              ),
            ),
          ]),
        ),
      */
      ]),
    );
    });
  }
  /*-----------------------------------------------------------------------------------*/
  // Navigation zur Bearbeitung des Vollguts 
  /*-----------------------------------------------------------------------------------*/
  _processVollgut(BuildContext context) {

    Navigator.push(
        context,
        MaterialPageRoute(
            //builder: (context) => DeliveryPage(
            builder: (context) => VollgutPage(
                tourData: tourData,
                routno: routno,
                drivno: drivno,
                dlvIndex: dlvIndex,
                readonly: readonly)))
        .then((val) {
          if (globals.currentDelvNo == delivery.dlvno) {
            //delivery.delvStat = globals.currentDelvStat; 
          }   
          onRefresh();    // Callback
        });
  }
  /*-----------------------------------------------------------------------------------*/
  // Navigation zur Bearbeitung des Leerguts
  /*-----------------------------------------------------------------------------------*/
  _processLeergut(BuildContext context) {
    
    Navigator.push(context,
        MaterialPageRoute(
          builder: (context) => LeergutPage(
              tourData: tourData,
              routno: routno,
              drivno: drivno,
              dlvIndex: dlvIndex,
              readonly: readonly),
        )).then((val) {
          if (globals.currentDelvNo == delivery.dlvno) {
            //delivery.delvStat = globals.currentDelvStat; 
          }  
          onRefresh();      // Callback
        });
  }
  /*-----------------------------------------------------------------------------------*/
  // -> Abrechnung 
  /*-----------------------------------------------------------------------------------*/
  /*
  void _billDelivery(BuildContext context) async {

    Navigator.push(context, 
        MaterialPageRoute(builder: (context) => BillingPage(
            routno: routno,
            drivno: drivno,
            dlvIndex: dlvIndex,
            readonly: readonly),
        )).then((val) {
          if (globals.currentDelvNo == delivery.dlvno) {
            //delivery.delvStat = globals.currentDelvStat; 
        }  
        onRefresh();      // Callback
    });
  }
  */

}

/*-------------------------------------------------------------------------------------*/
// Klasse Build Addresss (Anzeige der Kundenadresse mit diversen Links )
/*-------------------------------------------------------------------------------------*/
class BuildAddress extends StatelessWidget {
  
  BuildAddress({
      this.tourData,
      this.delivery,
      this.routno,
      this.drivno,
      this.dlvIndex,
      this.readonly: true
    });

  Tour tourData;
  Delivery delivery;
  final String routno;
  final String drivno;
  final int dlvIndex;
  final bool readonly;

  int cntItem = 0;
  int cntOpen = 0;
  int cntImages = 0;

  @override
  Widget build(BuildContext context) {
    if (cntItem == 0) {
      for (DelvItem item in delivery.itemList) {
        cntItem++;
        if (item.completed == false) cntOpen++;
        cntImages = cntImages + item.images;
      }
    }
    return StatefulBuilder(builder: (innerContext, innerSetState) {
      return Container(
        margin: EdgeInsets.fromLTRB(10.0, 5.0, 10.0, 5.0),
        color: Colors.grey[100],
        child: Column(children: <Widget>[
          Card(
            elevation: 5,
            child: Column(children: <Widget>[
              Container(
                alignment: Alignment.centerLeft,
                margin: EdgeInsets.fromLTRB(10.0, 20.0, 10.0, 10.0),
                child: Column(children: <Widget>[
                  // Kundenname
                  Row(
                    children: <Widget>[
                      Expanded(
                        flex: 1,
                        child: GestureDetector(
                          child: Container(
                            alignment: Alignment.topLeft,
                            child: Icon(Icons.location_on),
                          ),
                          onTap: () async {
                            _launchMap();
                          },
                        ),
                      ),
                      SizedBox(height: 30),
                      Expanded(
                        flex: 8,
                        child: Text(delivery.name1,
                            textAlign: TextAlign.left,
                            style: globals.styleTextNormalBold),
                      ),
                      Expanded(
                        flex: 1,
                        child: (delivery.delvStat == globals.delvStat_inProcess)
                        ? Icon(Icons.star, color: Colors.green)
                        : (delivery.delvStat == globals.delvStat_completed)
                          ? Icon(Icons.done, color: Colors.green)
                          :Container(),
                      ),
                    ],
                  ),

                  // Straße
                  Row(
                    children: <Widget>[
                      Expanded(
                        flex: 1,
                        child: Container(),
                      ),
                      SizedBox(height: 30),
                      Expanded(
                        flex: 9,
                        child: Text(delivery.stras + " " + delivery.hausn,
                            textAlign: TextAlign.left,
                            style: globals.styleTextNormal),
                      ),
                    ],
                  ),

                  // Ort
                  Row(
                    children: <Widget>[
                      Expanded(
                        flex: 1,
                        child: Container(),
                      ),
                      SizedBox(height: 30),
                      Expanded(
                        flex: 9,
                        child: Text(delivery.pstlz + " " + delivery.ort01,
                            textAlign: TextAlign.left,
                            style: globals.styleTextNormal),
                      ),
                    ],
                  ),

                  // Telefon
                  Row(
                    children: <Widget>[
                      Expanded(
                        flex: 1,
                        child: GestureDetector(
                          child: Container(
                            alignment: Alignment.topLeft,
                            child: Icon(Icons.phone),
                          ),
                          onTap: () async {
                            _makePhoneCall("tel:" + delivery.phone);
                          },
                        ),
                      ),
                      SizedBox(height: 35),
                      Expanded(
                        flex: 8,
                        child: GestureDetector(
                          child: Container(
                            alignment: Alignment.topLeft,
                            child: Text(delivery.phone,
                                textAlign: TextAlign.left,
                                style: globals.styleTextNormalBlue),
                          ),
                          onTap: () async {
                            _makePhoneCall("tel:" + delivery.phone);
                          },
                        ),
                      ),
                      Expanded(
                        flex: 1,
                        child: cntImages > 0
                        ? GestureDetector(
                          child: Container(
                            alignment: Alignment.topLeft,
                            child: Icon(Icons.camera_alt),
                          ),
                          onTap: () {
                            _displayGallery(context);
                          },
                        )                     
                        : Container(),
                      ),
                    ],
                  ),

                  // Mailadresse
                  if (delivery.email != null && delivery.email != "")
                    Row(
                      children: <Widget>[
                        Expanded(
                          flex: 1,
                          child: GestureDetector(
                            child: Container(
                              alignment: Alignment.topLeft,
                              child: Icon(Icons.mail_outline),
                            ),
                            onTap: () async {
                              _makePhoneCall("mailto:" + delivery.phone);
                            },
                          ),
                        ),
                        SizedBox(height: 35),
                        Expanded(
                          flex: 9,
                          child: Text(delivery.email,
                              textAlign: TextAlign.left,
                              style: globals.styleTextNormal),
                        ),
                      ],
                    ),

                  // Trenner
                  Divider(height: 10, thickness: 0.5, color: Colors.grey),

                  // Hinweis
                  Row(
                    children: <Widget>[
                      Expanded(
                        flex: 1,
                        child: Container(
                          alignment: Alignment.topLeft,
                          child: Icon(Icons.error_outline),
                        ),
                      ),
                      SizedBox(height: 35),
                      Expanded(
                        flex: 9,
                        child: Text(delivery.hinweis,
                            textAlign: TextAlign.left,
                            style: globals.styleTextNormal),
                      ),
                    ],
                  ),
                  // Barzahler & Fotos
                  Row(
                    children: <Widget>[
                      Expanded(
                        flex: 1,
                        child: GestureDetector(
                        child: Container(
                          alignment: Alignment.topLeft,
                          child: Icon(Icons.attach_money),
                        ),
                        onTap: () {
                            _displayInkasso(context);
                          },
                        ),
                      ),
                      SizedBox(height: 35),
                      Expanded(
                        flex: 4,
                        child: Row(children: <Widget>[
                          delivery.barkz
                            ? Text(H.getText(context, 'cash_payer'),
                                textAlign: TextAlign.left,
                                style: globals.styleTextNormal)
                            : Container(),
                          delivery.barkz && delivery.signDriver && delivery.payment > 0.0
                            ? Icon(Icons.done, )
                            : Container(),
                        ]),
                      ),
                      Expanded(
                        flex: 1,
                        child: GestureDetector(
                          child: Container(
                            alignment: Alignment.topLeft,
                            child: Icon(Icons.account_balance),
                          ),
                          onTap: () {
                            _displayBilling(context);;
                          },
                        ),
                      ),
                      Expanded(
                        flex: 4,
                        child: Row(children: <Widget>[
                          Text(H.getText(context, 'billing'),
                              textAlign: TextAlign.left,
                              style: globals.styleTextNormal),
                          delivery.signCustomer
                            ? Icon(Icons.done, )
                            : Container(),
                        ]),
                      ),
                    ],
                  ),
                ]),
              ),
            ]),
          ),
        ]),
      );
    });
  }

  /*---------------------------------------------------------------------------*/
  // Bilder anzeigen 
  /*---------------------------------------------------------------------------*/
  _displayGallery(BuildContext context) {

    Navigator.push(context, 
      MaterialPageRoute(builder: (context) => GalleryPage(
        delivery: delivery),),);
  }
  
  /*-----------------------------------------------------------------------------------*/
  // -> Abrechnung 
  /*-----------------------------------------------------------------------------------*/
  void _displayBilling(BuildContext context) async {

      Navigator.push(context, 
        MaterialPageRoute(builder: (context) => BillingPage(
            tourData: tourData,
            routno: routno,
            drivno: drivno,
            dlvIndex: dlvIndex,
            readonly: readonly),
        ),);
  }
  /*-----------------------------------------------------------------------------------*/
  // -> Inkasso, Barzahlung 
  /*-----------------------------------------------------------------------------------*/
  void _displayInkasso(BuildContext context) async {

      Navigator.push(context, 
        MaterialPageRoute(builder: (context) => InkassoPage(
            tourData: tourData,
            routno: routno,
            drivno: drivno,
            dlvIndex: dlvIndex,
            readonly: readonly),
        ),);
  }
  /*---------------------------------------------------------------------------*/
  // URL Launcher
  /*---------------------------------------------------------------------------*/
  Future<void> _makePhoneCall(String url) async {
    if (await canLaunch(url)) {
      await launch(url);
    } else {
      throw 'Could not launch $url';
    }
  }

  /*---------------------------------------------------------------------------*/
  // Launch Google Maps
  /*---------------------------------------------------------------------------*/
  _launchMap({String lat = "47.6", String long = "-122.3"}) async {

    String land1;
    land1 = delivery.land1;
    if (land1 == '' || land1 == 'DE') land1 = "Germany";

    String address = delivery.stras +
        " " +
        delivery.hausn +
        ", " +
        delivery.pstlz +
        " " +
        delivery.ort01 +
        ", " +
        land1;

    MapsLauncher.launchQuery(address);
    return;

    /*
    MapsLauncher.launchCoordinates(
        37.4220041, -122.0862462, 'Google Headquarters are here');

    List<Placemark> placemark =
        await Geolocator().placemarkFromAddress(address);

    if (!placemark.isEmpty) {
      Placemark place = placemark[0];

      lat = place.position.latitude.toString();
      long = place.position.longitude.toString();

      // var mapSchema = 'geo:$lat,$long';  // oder:
      final mapSchema =
          'https://www.google.com/maps/search/?api=1&query=$lat,$long';

      if (await canLaunch(mapSchema)) {
        await launch(mapSchema);
      } else {
        throw 'Could not launch $mapSchema';
      }
    }
    */

  }
}
