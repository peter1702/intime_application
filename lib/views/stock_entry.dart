import 'dart:async';
import 'package:barcode_scan/barcode_scan.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:modal_progress_hud/modal_progress_hud.dart';
import '../helpers/helpers.dart';
import '../models/stock.dart';
import '../views/stock_page.dart';
import '../globals.dart' as globals;

// iOS:
// in > ios > Runner > Info.plist
// <key>NSCameraUsageDescription</key>
// <string>Camera permission is required for barcode scanning.</string>
// Android:
// in > android > app > src > AndroidManifest.xml
// <uses-permission android:name="android.permission.CAMERA" />

class StockEntryPage extends StatefulWidget {
  StockEntryPage({Key key, this.title}) : super(key: key);
  final String title;

  @override
  _StockEntryPageState createState() => new _StockEntryPageState();
}

class _StockEntryPageState extends State<StockEntryPage> {
  final GlobalKey<ScaffoldState> _scaffoldKey = new GlobalKey<ScaffoldState>();

  bool _isInAsyncCall = false;

  bool isChanged;
  TextEditingController matnrController;
  bool matnrInvalid = false;
  String errorMessage = '';
  String barcode = '';
  FocusNode matnrFocus = new FocusNode();

  StockData stockData;

  _initializeData() {
    matnrController.text = globals.matnr;
  }

  // Initialization
  @override
  void initState() {
    super.initState();
    matnrController = new TextEditingController();
    _initializeData();
  }

  @override
  Widget build(BuildContext context) {
    return new Scaffold(
      backgroundColor: Colors.white,
      key: _scaffoldKey,
      /* ---------- appBar ----------------------------------------------------------*/
      appBar: PreferredSize(
        preferredSize: Size.fromHeight(70.0),
        child: AppBar(
          backgroundColor: globals.primaryColor,
          //automaticallyImplyLeading: false, // Don't show the leading button
          title: RichText(
            text: TextSpan(children: [
              TextSpan(
                  text: H.getText(context, 'stock_title'),
                  style: globals.styleHeaderTitle),
              TextSpan(text: "\n"),
              TextSpan(
                text: H.getText(context, 'material_entry'),
                style: globals.styleHeaderSubTitle,
              )
            ]),
          ),
          actions: <Widget>[
            new IconButton(
                icon: new Icon(Icons.more_vert),
                onPressed: () {
                  print("Button MORE pressed"); // handle onTap
                })
          ],
        ),
      ),
      /* ---------- bottomNavigatorBar ----------------------------------------------*/
      bottomNavigationBar: Builder(
          // Create an inner BuildContext so that the onPressed methods
          // can refer to the Scaffold with Scaffold.of().
          builder: (BuildContext context) {
        return BottomAppBar(
          child: new Row(
            mainAxisSize: MainAxisSize.max,
            children: <Widget>[
              Expanded(
                flex: 5,
                child: Container(
                  height: globals.heightBottomButton,
                  child: RaisedButton(
                    color: globals.primaryColor,
                    onPressed: () => Navigator.pop(context, true),
                    child: Text(H.getText(context, 'back'),
                        style: globals.styleBottomButton),
                  ),
                ),
              ),
              Padding(
                padding: EdgeInsets.fromLTRB(1, 0, 1, 0),
              ),
              Expanded(
                flex: 5,
                child: Container(
                  height: globals.heightBottomButton,
                  child: RaisedButton(
                    color: globals.primaryColor,
                    //onPressed: () => _submitForm(context),
                    onPressed: () async {
                      _checkEmpty(context);
                      if (matnrInvalid == false) {
                        _checkInput(context);
                      }
                    },
                    child: Text(H.getText(context, 'cont'),
                        style: globals.styleBottomButton),
                  ),
                ),
              )
            ],
          ),
        );
      }),
      /*---------- body ----------------------------------------------------------------*/
      body: Builder(
          // Create an inner BuildContext so that the onPressed methods
          // can refer to the Scaffold with Scaffold.of().
          builder: (BuildContext context) {
        return ModalProgressHUD(
          child: Container(
            margin: EdgeInsets.fromLTRB(17.0, 10.0, 17.0, 10.0),
            color: Colors.white,
            child: buildBody(context),
            ),
          inAsyncCall: _isInAsyncCall,
          opacity: 0.5,
          progressIndicator: CircularProgressIndicator(),
        );
      }),
    );
  }

  Widget buildBody(BuildContext context) {

    return Column(
      children: <Widget>[
        // Displayfield
        Container(
            alignment: Alignment.center,
            padding: EdgeInsets.all(10),
            child: Text(
              H.getText(context, 'material'),
              style: TextStyle(fontSize: 20),
            )),
        Container(
          padding: EdgeInsets.all(10),
          child: TextField(
            autofocus: true,
            maxLines: 1,
            controller: matnrController,
            focusNode: matnrFocus,
            onSubmitted: (value) async {
              if (matnrController.text != "") {
                setState(() {
                  matnrController.text = value;
                });
                _checkInput(context);
              }
            },
            decoration: InputDecoration(
              border: OutlineInputBorder(),
              labelText: H.getText(context, 'material'),
              labelStyle: TextStyle(color: globals.primaryColor),
              focusedBorder: OutlineInputBorder(
                borderSide: BorderSide(color: globals.primaryColor)),
              errorText: matnrInvalid ? errorMessage : null,
              suffixIcon: IconButton(
                  icon: Icon(Icons.cancel, size: 20, color: Colors.grey),
                  onPressed: () {
                    setState(() {
                      matnrController.clear();
                      errorMessage = '';
                      matnrInvalid = false;
                    });
                  }),
            ),
          ),
        ),
        Container(
          padding: EdgeInsets.all(10),
          child:
//            IconButton(
//            icon: Icon(Icons.camera_alt),
//            onPressed: () {
              GestureDetector(
                  child: Image.asset('lib/images/scann.png',
                      width: 70.0, height: 70.0),
                  onTap: () {
                    setState(() {
                      barcode = '';
                      matnrController.text = '';
                    });
                    scan();
                    setState(() {
                      matnrController.text = barcode;
                    });
                  }),
        ),
        Container(
          padding: EdgeInsets.all(10),
          child: Text(barcode),
        ),
      ],
    );
  }

  /*---------------------------------------------------------------------------*/
  // Prüfen & Buchen
  /*---------------------------------------------------------------------------*/
  void _checkEmpty(BuildContext context) {
    setState(() {
      matnrInvalid = false;
      errorMessage = null;
    });
    if (matnrController.text == "") {
      setState(() {
        matnrInvalid = true;
        errorMessage = H.getText(context, 'M008');
      });
      FocusScope.of(context).requestFocus(matnrFocus);
      //_showMessage(errorMessage);
      H.message(context, msgTy: 'E', msgId: 'M008');
      return;
    }
  }

  void _checkInput(BuildContext context) async {
    if (matnrController.text == "") {
      return;
    }
    setState(() {
      matnrInvalid = false;
      errorMessage = null;
      _isInAsyncCall = true;
    });
    String msgType = '';
    String msgText = '';

    stockData = await StockData.getStockData(matnrController.text);

    if (stockData.returnCode != null) {
      if (stockData.returnCode != 0) {
        msgType = 'E';
      } else {
        msgType = 'S';
      }
      setState(() {
        msgText = stockData.returnMssg;
      });
    }
    if (stockData.matnr == '' || stockData.returnCode != 0) {
      if ((msgType != 'E') || msgText == '') {
        setState(() {
          msgType = 'E';
          msgText = 'Fehler beim Ermitteln der Daten';
        });
      }
    }
    if (msgType == 'E') {
      setState(() {
        matnrInvalid = true;
        errorMessage = msgText;
        _isInAsyncCall = false;
      });
      FocusScope.of(context).requestFocus(matnrFocus);
      //_showMessage(errorMessage);
      if (errorMessage == null || errorMessage == '') {
        H.message(context, msgTy: 'E', msgId: 'M009', msgV1: matnrController.text);
      } else {
        H.showToast(context, errorMessage, color: Colors.red);
      }
      return;
    }
    //Alles okay
    setState(() {
      _isInAsyncCall = false;
      globals.matnr = matnrController.text;
    });
    Navigator.pushReplacement(
        context, MaterialPageRoute(builder: (context) => StockPage()));
  }

  Future scan() async {
    try {
      var result = await BarcodeScanner.scan();
      String barcode = result.rawContent;
      setState(() => this.barcode = barcode);
    } on PlatformException catch (e) {
      var result = ScanResult(
            type: ResultType.Error, 
            format: BarcodeFormat.unknown
      );
      if (e.code == BarcodeScanner.cameraAccessDenied) {
        setState(() {
          this.barcode = 'The user did not grant the camera permission!';
        });
      } else {
        setState(() => this.barcode = 'Unknown error: $e');
      }
    } on FormatException {
      setState(() => this.barcode =
          'null (User returned using the "back"-button before scanning anything. Result)');
    } catch (e) {
      setState(() => this.barcode = 'Unknown error: $e');
    }
  }
}
