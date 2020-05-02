import 'package:flutter/material.dart';
import 'package:signature/signature.dart';
import 'dart:io';

import '../models/tour.dart';
import '../helpers/helpers.dart';
import '../globals.dart' as globals;
import '../views/sign_page.dart';
import '../views/cash_page.dart';

class BillingPage extends StatefulWidget {
  BillingPage(
      {Key key,
      @required this.tourData,
      @required this.routno,
      @required this.drivno,
      @required this.dlvIndex,
      this.readonly: true})
      : super(key: key);

  final Tour tourData;
  final String routno;
  final String drivno;
  final int dlvIndex;
  final bool readonly;

  @override
  _BillingPageState createState() => new _BillingPageState();
}

class _BillingPageState extends State<BillingPage> {
  final GlobalKey<ScaffoldState> _scaffoldKey = new GlobalKey<ScaffoldState>();

  Tour tourData;
  Delivery delivery;
  int currentTabIndex = 0;
  bool readonly;

  _initializeData() {
    //tourData = Tour.getBuffer(widget.routno, widget.drivno);
    tourData = widget.tourData;
    delivery = tourData.delvList[widget.dlvIndex];
    if (delivery.signCustomer == null || delivery.signCustomer == false) {
      delivery.signCustomer = false;
      delivery.signCustomerChangeKz = '';
      delivery.signCustomerFile = '';
    }
    if (globals.waers == null) {
      globals.waers = delivery.waers;
    }
    if (globals.waers == '') {
      globals.waers = '€';
    }
    readonly = widget.readonly;
    globals.changeData = false;
    globals.changeSign = false;
    delivery.signCustomerFile = BuildSignature.buildFileName(delivery.dlvno);
  }

  Future<bool> _exitApp(BuildContext context) async {
    if (readonly == false && globals.changeSign == true) {
      if (delivery.signDriver == false) {
        String _title = H.getText(context, "leave");
        String _content = H.getText(context, "M029");
        String _answer = await H.confirmDialog(context, _title, _content);
        if (_answer != 'Y') {
          return false;
        }
      }
    }
    print("Exit App -> data changed: " + globals.changeData.toString());
    if (readonly == false && globals.changeData == true) {
      tourData.delvList[widget.dlvIndex] = delivery;
      Tour.saveDelivery(tourData, widget.dlvIndex);
      globals.changeData = false;
    }
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
    return new WillPopScope(
      onWillPop: () => _exitApp(context),
      child: new Scaffold(
        backgroundColor: Colors.grey[100],
        key: _scaffoldKey,
        /* ---------- appBar -----------------------------------------------*/
        appBar: PreferredSize(
          preferredSize: Size.fromHeight(70.0),
          child: AppBar(
            backgroundColor: globals.primaryColor,
            leading: new IconButton(
                icon: new Icon(Icons.arrow_back_ios),
                onPressed: () {
                  _exitApp(context);
                }),
            title: RichText(
              text: TextSpan(children: [
                TextSpan(
                    text: H.getText(context, 'billing'),
                    style: globals.styleHeaderTitle),
                TextSpan(text: "\n"),
                TextSpan(
                  text: H.getText(context, 'delivery', v1: delivery.dlvno),
                  style: globals.styleHeaderSubTitle,
                )
              ]),
            ),
          ),
        ),
        /* ---------- bottomNavigationBar -----------------------------------*/
        /*
            bottomNavigationBar: BottomNavigationBar(
              onTap: (index) {
                setState(() {
                  _onNavigationBarTapped(context, index);
                });
              },
              //currentIndex: 0, // this will be set when a new tab is tapped
              items: [
                BottomNavigationBarItem(
                  icon: new Icon(Icons.exit_to_app),
                  //icon: new Icon(Icons.arrow_back_ios),
                  title: Text(""),
                ),
                BottomNavigationBarItem(
                  icon: new Icon(Icons.border_color),
                  title: Text(""),
                ),
                BottomNavigationBarItem(
                  icon: new Icon(Icons.print),
                  title: Text(""),
                ),
              ],
            ),
            */
        /* ---------- body -------------------------------------------------*/
        body: SingleChildScrollView(
          child: Column(
            children: <Widget>[
              BuildBilling(
                  delivery: delivery,
                  routno: widget.routno,
                  drivno: widget.drivno,
                  dlvIndex: widget.dlvIndex,
                  readonly: readonly),
              BuildPrinting(
                  delivery: delivery,
                  routno: widget.routno,
                  drivno: widget.drivno,
                  dlvIndex: widget.dlvIndex,
                  readonly: readonly),
              BuildSignature(
                  delivery: delivery,
                  routno: widget.routno,
                  drivno: widget.drivno,
                  dlvIndex: widget.dlvIndex,
                  readonly: readonly),
            ],
          ),
        ),
      ),
    );
  }

  /*-------------------------------------------------------------------------*/
  // Bottom Navigation Bar auswerten
  /*-------------------------------------------------------------------------*/
  void _onNavigationBarTapped(BuildContext context, int index) async {
    switch (index) {
      case 0: // Exit
        Navigator.pop(context, true);
        break;
      case 1: // Signature
        break;
      case 2: // Drucken
        break;
    }
  }
}

/*---------------------------------------------------------------------------*/
// Abrechnung
/*---------------------------------------------------------------------------*/
class BuildBilling extends StatelessWidget {

  BuildBilling({
      this.tourData,
      this.delivery,
      this.routno,
      this.drivno,
      this.dlvIndex,
      this.readonly: true});

  Tour tourData;
  Delivery delivery;

  final String routno;
  final String drivno;
  final int dlvIndex;
  final bool readonly;

  @override
  Widget build(BuildContext context) {
    print("readonly: "+readonly.toString());
    return StatefulBuilder(builder: (BuildContext ctxt, StateSetter setState) {
      //return SingleChildScrollView(
      return Container(
        margin: EdgeInsets.fromLTRB(7.0, 5.0, 7.0, 5.0),
        child: Column(children: <Widget>[
          // Abrechnung
          Card(
              elevation: 5,
              child: Padding(
                padding: EdgeInsets.fromLTRB(12.0, 10.0, 12.0, 15.0),
                child: Column(children: <Widget>[
                  //
                  Container(
                      height: 40,
                      alignment: Alignment.centerLeft,
                      child: Text(
                        H.getText(context, "billing"),
                        style: globals.styleTextBigBold,
                      )),
                  // Warenwert
                  Row(children: <Widget>[
                    Expanded(
                        child: Text(H.getText(context, "amount_goods"),
                            style: globals.styleLabelTextField)),
                    Container(
                        height: 25,
                        child: Text(
                            Helpers.double2String(delivery.betrag, decim: 2) +
                                " €",
                            style: globals.styleTableTextNormalBlue)),
                  ]),
                  // Pfand
                  Row(children: <Widget>[
                    Expanded(
                        child: Text(H.getText(context, "amount_pawn"),
                            style: globals.styleLabelTextField)),
                    Container(
                        height: 25,
                        child: Text(
                            Helpers.double2String(delivery.pfand, decim: 2) +
                                " €",
                            style: globals.styleTableTextNormalBlue)),
                  ]),
                  // Aufgeld
                  Row(children: <Widget>[
                    Expanded(
                        child: Text(H.getText(context, "surcharge"),
                            style: globals.styleLabelTextField)),
                    Container(
                        height: 25,
                        child: Text(
                            Helpers.double2String(delivery.pfand, decim: 2) +
                                " €",
                            style: globals.styleTableTextNormalBlue)),
                  ]),
                  // Mehrwertsteuer
                  Row(children: <Widget>[
                    Expanded(
                        child: Text(H.getText(context, "mwst"),
                            style: globals.styleLabelTextField)),
                    Container(
                        height: 25,
                        child: Text(
                            Helpers.double2String(-50.3, decim: 2) + " €",
                            style: globals.styleTableTextNormalBlue)),
                  ]),
                  //
                  Divider(
                    thickness: 2,
                  ),
                  // Gesamtbetrag
                  Row(children: <Widget>[
                    Expanded(
                      child: Text(H.getText(context, "amount_total"),
                          style: globals.styleTextNormalBold),
                    ),
                    Container(
                        child: Text(
                            Helpers.double2String(delivery.betrag, decim: 2) +
                                " €",
                            style: globals.styleTextNormalBoldBlue)),
                  ]),
                  //
                ]),
              )),
        ]),
      );
    });
  }
} // end class

/*---------------------------------------------------------------------------*/
// Kontrolldruck
/*---------------------------------------------------------------------------*/
class BuildPrinting extends StatelessWidget {

  BuildPrinting(
      {this.delivery,
      this.routno,
      this.drivno,
      this.dlvIndex,
      this.readonly: true});

  Delivery delivery;

  final String routno;
  final String drivno;
  final int dlvIndex;
  final bool readonly;

  @override
  Widget build(BuildContext context) {
    return StatefulBuilder(builder: (BuildContext ctxt, StateSetter setState) {
      //return SingleChildScrollView(
      return Container(
          margin: EdgeInsets.fromLTRB(7.0, 5.0, 7.0, 5.0),
          child: Column(children: <Widget>[
            // Kontrolldruck
            Card(
                elevation: 5,
                child: Padding(
                  padding: EdgeInsets.fromLTRB(12.0, 10.0, 12.0, 15.0),
                  child: Column(children: <Widget>[
                    //
                    Container(
                        height: 40,
                        alignment: Alignment.centerLeft,
                        child: Text(
                          H.getText(context, "printout"),
                          style: globals.styleTextBigBold,
                        )),
                    //
                    Container(
                        height: 35,
                        alignment: Alignment.topLeft,
                        child: Text(
                          H.getText(context, "printout_exec"),
                          style: globals.styleTextNormal,
                        )),
                    //
                    Container(
                      //margin: EdgeInsets.fromLTRB(10.0, 10.0, 10.0, 10.0),
                      margin: EdgeInsets.fromLTRB(0.0, 15.0, 0.0, 0.0),
                      alignment: Alignment.centerLeft,
                      child: GestureDetector(
                          onTap: () {
                            setState(() {
                              _printout(ctxt);
                            });
                          },
                          child: readonly
                              ? new Container()
                              : new Row(
                                  children: <Widget>[
                                    //IconButton(icon: Icon(Icons.print, color: globals.primaryColor)),
                                    Icon(Icons.print,
                                        color: globals.primaryColor),
                                    Text(" "),
                                    Text(
                                      H.getText(context, 'prin').toUpperCase(),
                                      textAlign: TextAlign.left,
                                      style: globals.styleFlatButton,
                                    ),
                                  ],
                                )),
                    ),
                    //
                  ]),
                )),
          ]),);
    });
  }

  void _printout(BuildContext context) {
    //todo
  }
} // end class

/*---------------------------------------------------------------------------*/
// Unterschrift erfassen
/*---------------------------------------------------------------------------*/
class BuildSignature extends StatelessWidget {

  BuildSignature({
      this.delivery,
      this.routno,
      this.drivno,
      this.dlvIndex,
      this.readonly: true
      });

  Delivery delivery;

  final String routno;
  final String drivno;
  final int dlvIndex;
  final bool readonly;
 
  final SignatureController _signController =
      new SignatureController(penStrokeWidth: 5, penColor: Colors.blue);

  @override
  Widget build(BuildContext context) {

    _signController.addListener(() => {
      globals.changeSign = true
    });

    return StatefulBuilder(builder: (BuildContext ctxt, StateSetter setState) {
      //return SingleChildScrollView(
      return Container(
        margin: EdgeInsets.fromLTRB(7.0, 5.0, 7.0, 5.0),
        child: Column(children: <Widget>[
          // Erfassung Unterschrift
          Card(
            elevation: 5,
            child: Padding(
              padding: EdgeInsets.fromLTRB(12.0, 10.0, 12.0, 15.0),
              child: Column(children: <Widget>[
                /*
                Container(
                  height: 40,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    "Unterschrift",
                    style: globals.styleTextBigBold,
                  )),
                */
                readonly || delivery.signCustomer == true
                    ? delivery.signCustomerFile != ''
                        ? new Image(
                            image: new FileImage(File(delivery.signCustomerFile)),
                            fit: BoxFit.contain)
                        : Container(height: 200)
                    : Signature(
                        controller: _signController,
                        height: 150,
                        backgroundColor: Colors.grey[200]),
                //
                Container(
                  height: 40,
                  alignment: Alignment.centerLeft,
                  child: Row(
                    children: <Widget>[
                      IconButton(
                          icon: const Icon(Icons.edit),
                          onPressed: () async {
                            if (!readonly) {
                              _getSignature(context);
                            }
                          }),
                      Expanded(
                        child: Text(H.getText(context, "sign_cust"),
                            style: globals.styleTextNormal),
                      ),
                      readonly || delivery.signCustomer
                          ? Container()
                          : IconButton(
                              icon: const Icon(Icons.check),
                              onPressed: () async {
                                if (_signController.isNotEmpty) {
                                  await _saveSignature(context);
                                  setState(() {
                                    globals.changeSign = false;
                                    delivery.signCustomer = true;
                                  });
                                }
                              }),
                      readonly
                          ? Container()
                          : IconButton(
                              icon: const Icon(Icons.clear),
                              onPressed: () async {
                                _signController.clear();
                                await _deleteSignature(context);
                                setState(() {
                                  globals.changeSign = false;
                                  delivery.signCustomer = false;
                                });
                              },
                            ),
                    ],
                  ),
                ),
                //
              ]),
            ),
          ),
        ]),
      );
    });
  }

  /*-----------------------------------------------------------------------------------*/
  // Navigation -> Signature (voller Screen zum Erfassen der Unterschrift)
  /*-----------------------------------------------------------------------------------*/
  _getSignature(BuildContext context) {

    Navigator.push(context, MaterialPageRoute(builder: (context) => SignPage()))
        .then((val) {
        if (val != null && val != '') {
          if (delivery.signCustomer = true) {
            imageCache.clear();
          }
          _saveSignature(context, byteData:val);
        }
      },
    );
  }

  /*-----------------------------------------------------------------------------------*/
  // Check changes
  /*-----------------------------------------------------------------------------------*/
  Future<void> checkChanges(BuildContext context) async {
    if (readonly == false && _signController.isNotEmpty) {
      await _saveSignature(context);
    }
  }

  /*-----------------------------------------------------------------------------------*/
  // Save Signature to File
  /*-----------------------------------------------------------------------------------*/
  Future<void> _saveSignature(BuildContext context, {var byteData}) async {

    String fileName = buildFileName(delivery.dlvno);

    final File imageFile = File(fileName);
    if (byteData == null || byteData == '') {
      byteData = await _signController.toPngBytes();
    }
    try {
      //await imageFile.writeAsBytes(byteData, flush: true);
      imageFile.writeAsBytesSync(byteData, flush: true);
    } catch (e) {
      print(e);
    }

    delivery.signCustomerFile = fileName;
    if (delivery.signCustomerChangeKz == '') {
      delivery.signCustomerChangeKz = 'I';
    } else {
      delivery.signCustomerChangeKz = 'U';
    }
    delivery.signCustomer = true;
    globals.changeData = true;
    globals.changeSign = false;
  }

  /*-----------------------------------------------------------------------------------*/
  // Build the Filename
  /*-----------------------------------------------------------------------------------*/
  static String buildFileName(dlvno) {

    String fileName = "sign_customer_" + dlvno + '.png';
    String pathName = '';
    //final directory = await getApplicationDocumentsDirectory();
    //pathName = directory.path;
    pathName = globals.appDocPath;
    fileName = '$pathName/$fileName';

    return fileName;
  }

  /*-----------------------------------------------------------------------------------*/
  // Delete Signature from Canvas & from file
  /*-----------------------------------------------------------------------------------*/
  Future<void> _deleteSignature(BuildContext context) async {

    if (delivery.signCustomerFile != '') {
      File file = File(delivery.signCustomerFile);
      try {
        await file.delete();
        imageCache.clear();
      } catch (e) {
        print(e);
      }
    }
    if (delivery.signCustomerChangeKz == 'I') {
      delivery.signCustomerFile = '';
      delivery.signCustomerChangeKz = '';
    } else if (delivery.signCustomerFile != '') {
      delivery.signCustomerChangeKz = 'D';
      delivery.signCustomerFile = '';
      globals.changeData = true;
    } else {
      delivery.signCustomerChangeKz = '';
    }
    delivery.signCustomer = false;
  }

} // end class
