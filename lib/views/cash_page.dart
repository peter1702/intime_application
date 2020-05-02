import 'package:flutter/material.dart';
import 'package:signature/signature.dart';
import 'dart:io';

import '../models/tour.dart';
import '../helpers/helpers.dart';
import '../globals.dart' as globals;
import '../views/sign_page.dart';
import '../views/bill_page.dart';

class InkassoPage extends StatefulWidget {
  InkassoPage(
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
  _InkassoPageState createState() => new _InkassoPageState();
}

class _InkassoPageState extends State<InkassoPage> {
  final GlobalKey<ScaffoldState> _scaffoldKey = new GlobalKey<ScaffoldState>();

  Delivery delivery;
  Tour tourData;
  int currentTabIndex = 0;
  bool readonly;

  _initializeData() {
    //tourData = Tour.getBuffer(widget.routno, widget.drivno);
    tourData = widget.tourData;
    delivery = tourData.delvList[widget.dlvIndex];
    if (delivery.signDriver == null || delivery.signDriver == false) {
      delivery.signDriver = false;
      delivery.signDriverChangeKz = '';
      delivery.signDriverFile = '';
    }
    if (delivery.akonto == null) {
      delivery.akonto = false;
    }
    if (delivery.total == null) {
      delivery.total = 0;
    }
    if (delivery.difference == null) {
      delivery.difference = 0;
    }
    if (delivery.payment == null) {
      delivery.payment = 0;
    }
    if (globals.waers == null) {
      globals.waers = delivery.waers;
    }
    if (globals.waers == '') {
      globals.waers = '€';
    }
    if (delivery.signDriverFile == null) {
      delivery.signDriverFile = '';
    }
    readonly = widget.readonly;
    globals.changeData = false;
    globals.changeSign = false;
    delivery.signDriverFile = BuildInkasso.buildFileName(delivery.dlvno);
  }

  Future<bool> _exitApp(BuildContext context) async {
    //print("Exit App: -> data changed: " + globals.changeData.toString());
    //print("Exit App: signDriver = " + delivery.signDriver.toString());
    //print("Exit App: akonto = " + delivery.akonto.toString());
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
                    text: H.getText(context, 'cashbox'),
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

        /* ---------- body -------------------------------------------------*/
        body: SingleChildScrollView(
          child: Column(
            children: <Widget>[
              BuildInkasso(
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

}

/*---------------------------------------------------------------------------*/
// Inkasso Funktion für Barzahlung
/*---------------------------------------------------------------------------*/
class BuildInkasso extends StatelessWidget {
  BuildInkasso({
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
  bool isChanged = false;

  TextEditingController _textFieldController = new TextEditingController();
  FocusNode _focusNode = new FocusNode();

  final SignatureController _signController =
      new SignatureController(penStrokeWidth: 5, penColor: Colors.red);

  @override
  Widget build(BuildContext context) {
    if (delivery.payment == 0.00) {
      _textFieldController.text = '';
    } else {
      _textFieldController.text = Helpers.double2String(delivery.payment, decim:2);
    }
    _signController.addListener(() => {
      globals.changeSign = true
    });

    return StatefulBuilder(builder: (BuildContext ctxt, StateSetter setState) {
      //return SingleChildScrollView(
      return Container(
        margin: EdgeInsets.fromLTRB(7.0, 5.0, 7.0, 5.0),
        child: Column(children: <Widget>[
          // Aufstellung
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
                      H.getText(context, 'inkasso'),
                      style: globals.styleTextBigBold,
                    )),
                /*
                Container(
                    alignment: Alignment.topLeft,
                    height: 25,
                    child: Text(delivery.name1,
                      style: globals.styleTextNormalBold,
                    )),
                */
                // Betrag
                Row(children: <Widget>[
                  Expanded(
                      child: Text(H.getText(context, 'amount_total'),
                          style: globals.styleLabelTextField)),
                  Container(
                      height: 25,
                      child: Text(
                          Helpers.double2String(delivery.total, decim: 2) +
                              " " +
                              globals.waers,
                          style: globals.styleTableTextNormalBlue)),
                ]),
                // Kassiert
                Row(children: <Widget>[
                  Expanded(
                      child: Text(H.getText(context, 'amount_coll'),
                          style: globals.styleLabelTextField)),
                  Container(
                      height: 25,
                      child: Text(
                          Helpers.double2String(delivery.payment, decim: 2) +
                              " " +
                              globals.waers,
                          style: globals.styleTableTextNormalBlue)),
                ]),
                //
                Divider(
                  thickness: 2,
                ),
                // Differenzbetrag
                Row(children: <Widget>[
                  Expanded(
                      child: Text(H.getText(context, 'amount_diff'),
                          style: globals.styleTextNormalBold)),
                  Container(
                      height: 25,
                      child: Text(
                          Helpers.double2String(delivery.difference, decim: 2) +
                              " " +
                              globals.waers,
                          style: globals.styleTextNormalBoldBlue)),
                ]),
                // Switch "Akonto"
                Container(
                  height: 45,
                  alignment: Alignment.bottomLeft,
                  padding: EdgeInsets.fromLTRB(0.0, 10.0, 0.0, 0.0),
                  child: Row(children: <Widget>[
                    Text(H.getText(context, 'as_account'),
                        style: globals.styleTextNormal),
                    Switch(
                      value: delivery.akonto,
                      onChanged: (value) {
                        if (readonly == false) {
                          setState(() {
                            delivery.akonto = value;
                            delivery.changeKz = 'U';
                            globals.changeData = true;
                            isChanged = true;
                          });
                        }
                      },
                      activeColor: globals.primaryColor,
                    ),
                  ]),
                ),
              ]),
            ),
          ),

          // Erfassung Barbetrag
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
                    "Barbetrag",
                     style: globals.styleTextBigBold,
                )),
                */
                Container(
                  child: TextField(
                    //autofocus: true,
                    enabled: !readonly,
                    controller: _textFieldController,
                    focusNode: _focusNode,
                    decoration: InputDecoration(
                      labelText: H.getText(context, 'cash_recv'),
                      labelStyle: globals.styleTableTextNormalBlue,
                      border: OutlineInputBorder(
                        borderSide: BorderSide(width: 2),
                      ),
                      focusedBorder: OutlineInputBorder(),
                      errorText: Helpers.isFloat(_textFieldController.text)
                          ? null
                          : H.getText(context, 'M002'),
                      suffixIcon: Icon(Icons.euro_symbol,
                          size: 18, color: globals.primaryColor),
                      //suffixText: globals.waers,
                    ),
                    style: globals.styleInputField,
                    keyboardType: TextInputType.number,
                    onChanged: (val) => setState(() {
                      isChanged = true;
                    }),
                    onSubmitted: (val) => setState(() {
                      _onSubmit(val);
                    }),
                  ),
                ),
                //
              ]),
            ),
          ),

          // Erfassung der Unterschrift
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
                readonly == true || delivery.signDriver == true
                    ? delivery.signDriver == true &&
                            delivery.signDriverFile != ''
                        ? Image(
                            image: FileImage(File(delivery.signDriverFile)),
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
                              setState(() {
                                delivery.signDriver = delivery.signDriver;
                              });
                            }
                          }),
                      Expanded(
                        child: Text(H.getText(context, "sign_driv"),
                            style: globals.styleTextNormal),
                      ),
                      readonly || delivery.signDriver
                          ? Container()
                          : IconButton(
                              icon: const Icon(Icons.check),
                              onPressed: () async {
                                if (_signController.isNotEmpty) {
                                  await _saveSignature(context);
                                  setState(() {
                                    globals.changeSign = false;
                                    delivery.signDriver = true;
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
                                  //if (_signController.isNotEmpty) {
                                  globals.changeSign = false;
                                  delivery.signDriver = false;
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

  void _onSubmit(value) {
    delivery.payment = Helpers.string2Double(_textFieldController.text);
    delivery.difference = 8.88;

    delivery.changeKz = 'U';
    globals.changeData = true;
    isChanged = true;
  }

  /*-----------------------------------------------------------------------------------*/
  // Save Signature to File
  /*-----------------------------------------------------------------------------------*/
  Future<void> _saveSignature(BuildContext context, {var byteData}) async {

    String fileName = buildFileName(delivery.dlvno);

    final File imageFile = File(fileName);
    // zur Sicherheit vorher löschen
    /*
    try {
      await imageFile.delete();
    } catch (e) {
      //print(e);
    }
    */
    if (byteData == null || byteData == '') {
      byteData = await _signController.toPngBytes();
    }
    try {
      await imageFile.writeAsBytes(byteData, flush: true);
    } catch (e) {
      print(e);
    }

    delivery.signDriverFile = fileName;
    if (delivery.signDriverChangeKz == '') {
      delivery.signDriverChangeKz = 'I';
    } else {
      delivery.signDriverChangeKz = 'U';
    }
    delivery.signDriver = true;
    globals.changeData = true;
    globals.changeSign = false;
  }

  /*-----------------------------------------------------------------------------------*/
  // Build the Filename
  /*-----------------------------------------------------------------------------------*/
  static String buildFileName(dlvno) {

    String fileName = "sign_driver_" + dlvno + '.png';
    String pathName = '';
    //final directory = await getApplicationDocumentsDirectory();
    //pathName = directory.path;
    pathName = globals.appDocPath;
    fileName = '$pathName/$fileName';

    return fileName;
  }

  /*-----------------------------------------------------------------------------------*/
  // Delete Signatur from canvas & from file
  /*-----------------------------------------------------------------------------------*/
  Future<void> _deleteSignature(BuildContext context) async {

    if (delivery.signDriverFile != '') {
      File file = File(delivery.signDriverFile);
      try {
        await file.delete();
        imageCache.clear();
      } catch (e) {
        print(e);
      }
    }
    if (delivery.signDriverChangeKz == 'I') {
      delivery.signDriverFile = '';
      delivery.signDriverChangeKz = '';
    } else if (delivery.signDriverFile != '') {
      delivery.signDriverChangeKz = 'D';
      delivery.signDriverFile = '';
      globals.changeData = true;
    } else {
      delivery.signDriverChangeKz = '';
    }
    delivery.signDriver = false;
  }

  /*-----------------------------------------------------------------------------------*/
  // Navigation -> Signature  (voller Screen zur Erfassung der Unterschrift)
  /*-----------------------------------------------------------------------------------*/
  _getSignature(BuildContext context) {

    Navigator.push(context, MaterialPageRoute(builder: (context) => SignPage()))
        .then((val) {
        if (val != null && val != '') {
          if (delivery.signDriver = true) {
              imageCache.clear();
          }
          _saveSignature(context, byteData:val);
        }
      },
    );
  }

} // end class
