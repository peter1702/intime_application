import 'package:flutter/material.dart';
import 'package:progress_dialog/progress_dialog.dart';
import 'dart:convert';
import '../models/sap.dart';
import '../models/tour.dart';
import '../models/stock.dart';
import '../globals.dart' as globals;

class SAPConnect extends StatefulWidget {
  SAPConnect({Key key, this.title}) : super(key: key);
  final String title;
  @override
  _SAPConnectState createState() => new _SAPConnectState();
}

class _SAPConnectState extends State<SAPConnect> {
  final GlobalKey<ScaffoldState> _scaffoldKey = new GlobalKey<ScaffoldState>();

  String resultFromSAP = '';

  TextEditingController usrController = TextEditingController();
  TextEditingController pwdController = TextEditingController();

  ProgressDialog progressDialog;

  _initializeData() {
    usrController.text = 'schuster.p';
    pwdController.text = 'Brandt#1';
  }

  // Initialzation
  @override
  void initState() {
    super.initState();
    _initializeData();
  }

  @override
  Widget build(BuildContext context) {

      progressDialog = new ProgressDialog(context);
      progressDialog.style(
        message: 'connecting...',
        borderRadius: 10.0,
        backgroundColor: Colors.white,
        //progressWidget: CircularProgressIndicator(),
        progressWidget: LinearProgressIndicator(),
      );
    return new Scaffold(
      backgroundColor: Colors.white,
      key: _scaffoldKey,
      /* ---------- appBar ----------------------------------------------------------*/
      appBar: new AppBar(
        title: new Text("SAP Connection"),
      ),
      /*---------- body ----------------------------------------------------------------*/
      body: Builder(
          // Create an inner BuildContext so that the onPressed methods
          // can refer to the Scaffold with Scaffold.of().
          builder: (BuildContext context) {
        return Container(
          margin: EdgeInsets.fromLTRB(17.0, 10.0, 17.0, 10.0),
          color: Colors.white,
          child: Column(children: <Widget>[
            Container(
              padding: EdgeInsets.all(10),
              child: TextField(
                autofocus: true,
                maxLines: 1,
                controller: usrController,
                decoration: InputDecoration(
                  border: OutlineInputBorder(),
                  suffixIcon: Icon(Icons.person_outline),
                  labelText: 'UserName',
                ),
              ),
            ),
            Container(
              padding: EdgeInsets.all(10),
              child: TextField(
                obscureText: true,
                maxLines: 1,
                controller: pwdController,
                keyboardType: TextInputType.visiblePassword,
                decoration: InputDecoration(
                  border: OutlineInputBorder(),
                  suffixIcon: Icon(Icons.vpn_key),
                  labelText: 'Password',
                ),
              ),
            ),
            Container(
              height: 80,
              padding:EdgeInsets.all(10),
              child: 
                SizedBox.expand(child:
                RaisedButton(
                  textColor: Colors.white,
                  color: Colors.blue,
                  child: Text('Connect to SAP', style: TextStyle(fontSize: 18)),
                  onPressed: () async {
                    setState(() { resultFromSAP = '...connecting'; });
                    //progressDialog.show();
                    await _connectToSAP(context);
                    _connectToSAP(context);
                    //progressDialog.hide();
                  }),
                ),
            ),
            Expanded(child:
            Container(
              padding: EdgeInsets.all(10),
                child: Text(resultFromSAP, maxLines: 5,),
            ),
            ),
          ]),
        );
      }),
    );
  }

  Future<void> _connectToSAP(BuildContext context) async {
  //void _connectToSAP(BuildContext context) {
    String usr;
    String pwd;
    setState(() {
      usr = usrController.text;
      pwd = pwdController.text;
      resultFromSAP = '';
    });

    SAP sap = new SAP();
 
    /*
    String json =
      '[ { \"param1\": \"Test from Flutter\", \"param2\": \"Greetings\" } ]';
    await sap.requestToSAP("get_stock", "0", json, usr: usr, pwd: pwd);
    */

    /*
    List<Fahrer> drivers = []; 
    drivers = await Fahrer.getFahrer();
    Fahrer driver = drivers[0];
    if (driver != null) {
      sap.returnCode = 0;
      sap.returnStatus = '123';
      sap.returnData = 'Fahrer gelesen! '+driver.nummer;
    }
    */
    /*
    List<StandardLeergut> empties = [];
    empties = await StandardLeergut.getLeergut();
    StandardLeergut empty = empties[0];
    if (empty != null) {
      sap.returnCode = 0;
      sap.returnStatus = '123';
      sap.returnData = 'Leergut gelesen! '+empty.pfand.toString();
    }
    */

    //
    await sap.checkSecUserLogin('1001', '9876');
    UserParam userParam = new UserParam();
    //Decode JSON data
    final mapData = jsonDecode(sap.returnData);
    userParam = UserParam.fromJson(mapData);
    print("returned user: "+userParam.username);
    //
    /*
      RequestStock requestStock = new RequestStock();
      requestStock.matnr = 'EWMS4-20';
      requestStock.werks = '1710';
      if (requestStock.werks == null || requestStock.werks == '')
        requestStock.werks = globals.plant;
      if (requestStock.werks == null)
        requestStock.werks = '';
      
      String json = jsonEncode(requestStock.toJson());
      await sap.requestToSAP("get_stock", "0", json);   
    */


    setState(() {
      String _returnStatus = sap.returnStatus;
      String _returnData = sap.returnData;
      if(sap.returnData == null || sap.returnData == '') 
        _returnData = sap.returnMssg;
      resultFromSAP = "returnStatus: $_returnStatus; returnData: $_returnData";
    });
  }

  /*---------------------------------------------------------------------------*/
  // Message ausgeben
  /*---------------------------------------------------------------------------*/
  void _showMessage(String message, [MaterialColor color = Colors.red]) {
    _scaffoldKey.currentState.showSnackBar(
        new SnackBar(backgroundColor: color, content: new Text(message)));
  }
}
