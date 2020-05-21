import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/cupertino.dart';
import 'dart:convert';
import 'package:modal_progress_hud/modal_progress_hud.dart';

import '../helpers/helpers.dart';
import '../models/sap.dart';
import '../globals.dart' as globals;

import '../views/start_page.dart';
import '../views/menu_page.dart';

class LoginPage extends StatefulWidget {
  LoginPage({Key key, this.title}) : super(key: key);
  final String title;
  static String tag = 'login-page';

  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  // manage state of modal progress HUD widget
  bool _isInAsyncCall = false;

  bool usr_invalid = false;
  bool pwd_invalid = false;
  bool initialized = false;
  bool abbruch = false;

  String lastUsername = ''; //letzter angemeldeter User
  String lastPassword = ''; //letztes verwendetes Passwort
  String userPassword = ''; //letztes verifiziertes Passwort
  String passKey = ''; //Preference-Key für userPassword
  String error_message;
  bool refreshPassword = false;

  bool _login_with_sap = false;
  bool _login_with_sec = false;
  bool _login_with_loc = false;
  String _valid_user1 = '';
  String _valid_user2 = '';

  TextEditingController nameController = TextEditingController();
  TextEditingController passController = TextEditingController();

  // Initialize outside the build method
  FocusNode nameFocus = FocusNode();
  FocusNode passFocus = FocusNode();

  // Globalization of Preferences
  SharedPreferences prefs;

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    _loadPreferences();
    _refresh();
    
    return Scaffold(
      appBar: AppBar(
        backgroundColor: globals.primaryColor,
        //title: Text(H.getText(context, 'main_title')),
        title: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Container( 
            margin: EdgeInsets.only(top:14),
            child: Image(image: ExactAssetImage('lib/images/intime_white.png'),
                          fit: BoxFit.contain, height:95),
        ),
        ],),
      ),

      body: ModalProgressHUD(
        child: Container(
          padding: const EdgeInsets.all(10.0),
            child: buildLoginForm(context),
        ),
        inAsyncCall: _isInAsyncCall,
        opacity: 0.5,
        progressIndicator: CircularProgressIndicator(),
      ),
    );
  }

  Widget buildLoginForm(BuildContext context) {
    return ListView(
      children: <Widget>[
        Container(
            alignment: Alignment.center,
            padding: EdgeInsets.all(10),
            child: Text(
              H.getText(context, 'main_title'),
              style: TextStyle(
                  color: globals.primaryColor,
                  fontWeight: FontWeight.w500,
                  fontSize: 30),
            )),
        Container(
            alignment: Alignment.center,
            padding: EdgeInsets.all(10),
            child: Text(
              H.getText(context, 'login'),
              style: TextStyle(
                color: globals.primaryColor,
                fontSize: 20),
            )),
        // Username
        Container(
          padding: EdgeInsets.all(10),
          child: TextField(
              autofocus: true,
              controller: nameController,
              focusNode: nameFocus,
              keyboardType: TextInputType.text,
              decoration: InputDecoration(
                border: OutlineInputBorder(),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.all(Radius.circular(5.0)),
                  borderSide: BorderSide(color: globals.primaryColor)),
                filled: true,
                focusColor: globals.primaryColor,
                labelStyle: TextStyle(color: globals.primaryColor),
                labelText: H.getText(context, 'user'),
                errorText: usr_invalid ? error_message : null,
                suffixIcon: IconButton(
                  icon: Icon(Icons.person_outline, color: globals.primaryColor),
                  onPressed: () {
                    setState(() {
                      nameController.clear();
                      error_message = '';
                      usr_invalid   = false;
                    });
                  }),
              ),
              onSubmitted: (value) async {
                if (nameController.text != '' && passController.text != '') {
                  _login(context);
                }
              }),
        ),
        // Password
        Container(
          padding: EdgeInsets.fromLTRB(10, 10, 10, 0),
          child: TextField(
              obscureText: true,
              controller: passController,
              focusNode: passFocus,
              keyboardType: TextInputType.visiblePassword,
              decoration: InputDecoration(
                border: OutlineInputBorder(),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.all(Radius.circular(5.0)),
                  borderSide: BorderSide(color: globals.primaryColor)),
                filled: true,
                focusColor: globals.primaryColor,
                labelStyle: TextStyle(color: globals.primaryColor),
                labelText: H.getText(context, 'password'),
                suffixIcon: IconButton(
                  icon: Icon(Icons.vpn_key, color: globals.primaryColor),
                  onPressed: () {
                    setState(() {
                      passController.clear();
                      error_message = '';
                      pwd_invalid   = false;
                    });
                  }),
                errorText: pwd_invalid ? error_message : null,
              ),
              onSubmitted: (value) async {
                if (nameController.text != '' && passController.text != '') {
                  _login(context);
                }
              }),
        ),
        // Change Password
        FlatButton(
          onPressed: ()
              //User want to change his password
              async { _passwordChange(context); },
          textColor: globals.primaryColor,
          child: Text(H.getText(context, 'pwd_change')),
        ),
        // Login Button
        Container(
          height: 80,
          padding: EdgeInsets.fromLTRB(10, 20, 10, 0),
          child: RaisedButton(
              textColor: Colors.white,
              shape: new RoundedRectangleBorder(
                borderRadius: new BorderRadius.circular(5.0)),
              color: globals.primaryColor,
              child: Text(H.getText(context, 'login'),
                  style: TextStyle(fontSize: 18)),
              onPressed: () async {
                _login(context);
              }),
        ),
      ],
    );
  }
  /*-----------------------------------------------------------------------------------*/
  // Login 
  /*-----------------------------------------------------------------------------------*/
  _login(BuildContext context, {bool nocheck: false}) async {

    if (!nocheck) {
      await _checkCredentials(context);
    }

    if (!usr_invalid && !pwd_invalid && !abbruch) {
      setState(() {
        if (prefs != null) {
          passKey = nameController.text + 'PWD';
          prefs.setString('USR', nameController.text);
          prefs.setString('PWD', passController.text);
          prefs.setString(passKey, passController.text);
        }
        globals.isLoggedIn = true;
        globals.loginName  = nameController.text;
        globals.loginPwd   = passController.text;
        globals.loginDate  = DateTime.now();
      });
      // Entweder in das Menü (LVS) oder in die Tourenbearbeitung 
      setState(() {
        if (prefs != null) {
          globals.currentTourNo = prefs.getString('currentTourNo');
          globals.currentDrivNo = prefs.getString('currentDrivNo');
          globals.currentTourStat = prefs.getString('currentTourStat'); 
          if (globals.currentTourNo != null && globals.currentTourNo != '') {
            globals.toBeSynchronized = prefs.getBool('toBeSynchronized');
            globals.currentDelvNo = prefs.getString('currentDelvNo');
            globals.currentDlvIndex = prefs.getInt('currentDlvIndex');
            globals.lastReturnCode = prefs.getInt('lastReturnCode');
            globals.lastReturnMssg = prefs.getString('lastReturnMssg');
          } else {
            globals.currentDelvNo   = '';
            globals.currentDlvIndex = 0;
            globals.toBeSynchronized = false;
            globals.lastReturnCode  = 0;
            globals.lastReturnMssg  = '';
          }
        }
      });
      //Navigator.pushReplacementNamed(context, StartPage.tag);
      if (globals.loginName.toLowerCase() == 'demo1'  ||
          globals.loginName.toLowerCase() == 'admin1' ) {
        String menue = 'LVS';
        String myTitle = 'Warehouse-Management';
        refreshPassword = true;
       // Navigator.pushReplacement(
        Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => MenuPage(title:myTitle, menue:menue)));
      } else {
        Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => StartPage()));
      }
    }
  }
  /*-----------------------------------------------------------------------------------*/
  // Bei Wiedereinstieg Passwort zurücksetzen 
  /*-----------------------------------------------------------------------------------*/
  _refresh() {
    if (refreshPassword == true) {
      refreshPassword = false;
      passController.clear();
      FocusScope.of(context).requestFocus(passFocus);
    }
  }
  /*-----------------------------------------------------------------------------------*/
  // Prüfen Benutzer & Kennwort
  /*-----------------------------------------------------------------------------------*/
  _checkCredentials(BuildContext context) async {

    String usr;
    String pwd;
    bool checkLastUser = false;

    setState(() {
      usr_invalid = false;
      pwd_invalid = false;
      abbruch = false;
      error_message = "";
      usr = nameController.text = nameController.text.trim();
      pwd = passController.text = passController.text.trim();
    });
    // Username darf nicht leer sein 
    if (nameController.text.isEmpty) {
      usr_invalid = true;
      error_message = H.getText(context, 'M005');
      FocusScope.of(context).requestFocus(nameFocus);
      return;
    }
    // Passwort darf nicht leer sein 
    if (passController.text.isEmpty) {
      pwd_invalid = true;
      error_message = H.getText(context, 'M006');
      FocusScope.of(context).requestFocus(passFocus);
      return;
    }

    // Check Username
    if (nameController.text.toLowerCase() == "admin"   ||
        nameController.text.toLowerCase() == "demo1"  ||
        nameController.text.toLowerCase() == "admin1" ||
        nameController.text.toLowerCase() == "demo") {
      checkLastUser = true;
     
    } else if (_login_with_sap) {
      // der Username muss ein SAP-User sein - die Prüfung erfolgt remote
      SAP sap = new SAP();
      setState(() {
        _isInAsyncCall = true;
      });

      await sap.checkSAPUserLogin(usr, pwd);

      setState(() {
        _isInAsyncCall = false;
      });

      if (sap.returnCode != 0) {
        print("Anmeldung mit SAP-Kennwort - returnStatus = "+sap.returnStatus);
        if (sap.returnStatus == '002') {
          // 002 = Kennwort-Fehler
          pwd_invalid = true;
          if (sap.returnMssg != '') {
            error_message = sap.returnMssg;
          } else {
            error_message = H.getText(context, 'M010', v1: nameController.text);
          }
          FocusScope.of(context).requestFocus(passFocus);
          return;
        } else if (sap.returnStatus == '778' || sap.returnStatus == '779') {
          // 778, 779 = timeout
          error_message = sap.returnMssg;
          usr_invalid = true;
          checkLastUser = true;
        } else {
          usr_invalid = true;
          if (sap.returnMssg != '') {
            error_message = sap.returnMssg;
          } else {
            error_message = H.getText(context, 'M007', v1: nameController.text);
          }
          FocusScope.of(context).requestFocus(nameFocus);
          return;
        }
      } else {
        // Prüfung war erfolgreich
        UserParam userParam = new UserParam();
        //Decode JSON data
        final mapData = jsonDecode(sap.returnData);
        userParam = UserParam.fromJson(mapData);
        return;
      }
      
    } else if (_login_with_sec) {
      // der Username ist ein Sekundär-User (SAP-Tabelle) - die Prüfung erfolgt im SAP
      SAP sap = new SAP();
      setState(() {
        _isInAsyncCall = true;
      });

      await sap.checkSecUserLogin(usr, pwd);

      setState(() {
        _isInAsyncCall = false;
      });

      if (sap.returnCode != 0) {
        print("Anmeldung mit Sekundär-User - returnStatus = "+sap.returnStatus);
        if (sap.returnStatus == '002') {
          // 002 = Kennwort-Fehler
          pwd_invalid = true;
          if (sap.returnMssg != '') {
            error_message = sap.returnMssg;
          } else {
            error_message = H.getText(context, 'M010', v1: nameController.text);
          }
          FocusScope.of(context).requestFocus(passFocus);
          return;
        } else if (sap.returnStatus == '778' || sap.returnStatus == '779') {
          // 778, 779 = timeout
          error_message = sap.returnMssg;
          usr_invalid = true;
          checkLastUser = true;
        } else {
          usr_invalid = true;
          if (sap.returnMssg != '') {
            error_message = sap.returnMssg;
          } else {
            error_message = H.getText(context, 'M007', v1: nameController.text);
          }
          FocusScope.of(context).requestFocus(nameFocus);
          return;
        }
      } else {
        // Prüfung war erfolgreich
        UserParam userParam = new UserParam();
        //Decode JSON data
        final mapData = jsonDecode(sap.returnData);
        userParam = UserParam.fromJson(mapData);
        return;
      }
    } else if (_login_with_loc) {
      checkLastUser = true;
      // der User wird vom Admin im Gerät hinterlegt und lokal geprüft
      if (nameController.text != _valid_user1 &&
          nameController.text != _valid_user2) {
        usr_invalid = true;
        error_message = H.getText(context, 'M007', v1: nameController.text);
        FocusScope.of(context).requestFocus(nameFocus);
        return;
      }
    } else {
      checkLastUser = true;
      // freie Wahl des Benutzers
    }

    // Check if user = 'demo'
    if (nameController.text.toLowerCase() == "demo" &&
        passController.text.toLowerCase() == "demo") {
      return;
    }
    // Check if user = 'demorf'
    if (nameController.text.toLowerCase() == "demo1" &&
        passController.text.toLowerCase() == "demo1") {
      return;
    }
    // Check last verified Password
    passKey = nameController.text + 'PWD';
    if (prefs != null) {
      userPassword = prefs.getString(passKey);
    }
    if (userPassword == null || userPassword == 'init') {
      userPassword = '';
    }
    //print(">>> last verified userPassword: " + userPassword + " " + passController.text);
    if (userPassword != '' && checkLastUser == true) {
      if (passController.text == userPassword) {
        setState(() {
          usr_invalid = pwd_invalid = false;
          error_message = '';
        });
        return;
      }
    }

    // Check if password is initial and have to be changed
    if ((nameController.text.toLowerCase() == "admin" &&
            userPassword == '' &&
            passController.text.toLowerCase() == "admin")   ||
        (nameController.text.toLowerCase() != "admin1" &&
            userPassword == '' &&
            passController.text.toLowerCase() == "admin1") ||
        (nameController.text.toLowerCase() != "admin" &&
            userPassword == '' &&
            passController.text.toLowerCase() == "init") ||
        (nameController.text.toLowerCase() != "admin1" &&
            userPassword == '' &&
            passController.text.toLowerCase() == "init")) {
      //
      await _passwordDialog(context, pwdInit: true).then((val) {
        setState(() {
          if (val == null) val = '';
          if (val == '') {
            abbruch = true;
            return;
          } else {
            passController.text = val;
            userPassword = val;
            return;
          }
        });
      });
    } else if (error_message == '') {
      if (error_message == '' || usr_invalid == true) {
        setState(() {
          pwd_invalid = true;
          error_message = H.getText(context, 'M010');
          passController.text = '';
        });
        FocusScope.of(context).requestFocus(passFocus);
      }
      return;
    }
  }
  /*-----------------------------------------------------------------------------------*/
  // Änderung des Kennworts (nur bei lokalem Benutzer) 
  /*-----------------------------------------------------------------------------------*/
  _passwordChange(BuildContext context) async {
    if (userPassword == null) userPassword = '';
    setState(() {
      pwd_invalid = usr_invalid = abbruch = false;
      if (userPassword == null ||
          userPassword == '' ||
          userPassword == 'init') {
        pwd_invalid = true;
        error_message = H.getText(context, 'M012', v1: nameController.text);
        FocusScope.of(context).requestFocus(passFocus);
        return;
      }
      passController.text = '';
    });

    if (pwd_invalid == false) {
      await _passwordDialog(context, pwdInit: false).then((val) {
        setState(() {
          if (val == null) val = '';
          if (val == '') {
            abbruch = true;
            return;
          } else {
            passController.text = val;
            userPassword = val;
            _login(context, nocheck: true);
          }
        });
      });
    }
  }
  /*-----------------------------------------------------------------------------------*/
  // Start Dialog zum Ändern des Kennworts
  /*-----------------------------------------------------------------------------------*/
  _passwordDialog(BuildContext context, {bool pwdInit = false}) async {
    return showDialog(
      context: context,
      builder: ((BuildContext context) {
        return PasswordDialog(
            title: H.getText(context, 'pwd_change'),
            pwdInit: pwdInit,
            oldPassword: userPassword);
      }),
    );
  }
  /*-----------------------------------------------------------------------------------*/
  // Preferences lesen 
  /*-----------------------------------------------------------------------------------*/
  _loadPreferences() async {
  
    prefs = await SharedPreferences.getInstance();

    if (!initialized) {
      initialized = true;
      setState(
        () {
          if (prefs != null) {
            lastUsername = prefs.getString('USR');
            nameController.text = lastUsername;
            lastPassword = prefs.getString('PWD');
            //passController.text = lastPassword;

            globals.loginLang = prefs.getString('LNG');
            if (globals.loginLang == null) {
              globals.loginLang = 'DE';
            }
            if (globals.userLang == null || globals.userLang == "") {
              globals.userLang = globals.loginLang;
            }
            globals.hostSAP = prefs.getString('sap_host');
            globals.portSAP = prefs.getString('sap_port');
            globals.serviceSAP = prefs.getString('sap_service');
            globals.clientSAP = prefs.getString('sap_mandant');
            globals.usrSAP = prefs.getString('sap_user');
            globals.pwdSAP = prefs.getString('sap_password');
            if (globals.hostSAP == null) {
              globals.hostSAP = globals.portSAP = globals.serviceSAP = '';
              globals.usrSAP = globals.pwdSAP = '';
            }

            _login_with_sap = prefs.getBool('login_with_sap');
            _login_with_sec = prefs.getBool('login_with_sec');
            _login_with_loc = prefs.getBool('login_with_loc');
            _valid_user1 = prefs.getString('local_user1');
            _valid_user2 = prefs.getString('local_user2');

            if (_login_with_sap == null) _login_with_sap = false;
            if (_login_with_sec == null) _login_with_sec = false;
            if (_login_with_loc == null) _login_with_loc = false;
            if (_valid_user1 == null) _valid_user1 = '';
            if (_valid_user2 == null) _valid_user2 = '';
          }
        },
      );
    }
  }
}
/*-----------------------------------------------------------------------------------*/
// Dialog zum Ändern des Passworts 
/*-----------------------------------------------------------------------------------*/
class PasswordDialog extends StatefulWidget {

  PasswordDialog({this.title, this.pwdInit, this.oldPassword});

  final String title;
  final String oldPassword;
  final bool pwdInit;

  @override
  _PasswordDialogState createState() => _PasswordDialogState();
}

class _PasswordDialogState extends State<PasswordDialog> {

  String _title;
  String _oldPassword;
  bool _pwdInit;

  TextEditingController pwd0Controller = TextEditingController();
  TextEditingController pwd1Controller = TextEditingController();
  TextEditingController pwd2Controller = TextEditingController();

  FocusNode pwd0Focus = FocusNode();
  FocusNode pwd1Focus = FocusNode();
  FocusNode pwd2Focus = FocusNode();

  bool pwd0_invalid = false;
  bool pwd1_invalid = false;
  bool pwd2_invalid = false;
  String errMsg = '';

  @override
  void initState() {
    super.initState();
    _title = widget.title;
    _pwdInit = widget.pwdInit;
    _oldPassword = widget.oldPassword;
    pwd0Controller.clear();
    pwd1Controller.clear();
    pwd2Controller.clear();
  }

  @override
  Widget build(BuildContext context) {
    if (_pwdInit) {
      FocusScope.of(context).requestFocus(pwd1Focus);
    } else {
      FocusScope.of(context).requestFocus(pwd0Focus);
    }
    return AlertDialog(
      title: Text(_title),
      actions: <Widget>[
        new FlatButton(
          child: new Text(H.getText(context, 'conf')),
          onPressed: () {
            _checkNewPassword(context);
          },
        ),
        new FlatButton(
          child: new Text(H.getText(context, 'canc')),
          onPressed: () {
            Navigator.of(context).pop('');
          },
        )
      ],

      content: SingleChildScrollView(
        child: Column(
          children: <Widget>[
            TextField(
                controller: pwd0Controller,
                readOnly: widget.pwdInit,
                focusNode: pwd0Focus,
                obscureText: true,
                decoration: InputDecoration(
                    labelText: H.getText(context, 'pwd_old'),
                    suffixIcon: Icon(Icons.vpn_key),
                    errorText: pwd0_invalid ? errMsg : null,
                    hintText: H.getText(context, 'pwd_old')),
                onSubmitted: (value) {
                  setState(() {
                    pwd0_invalid = false;
                    if (pwd0Controller.text != _oldPassword &&
                        _pwdInit == false) {
                      pwd0_invalid = true;
                      FocusScope.of(context).requestFocus(pwd0Focus);
                      //Kennwort ist ungültig
                      errMsg = H.getText(context, 'M010');
                    }
                  });
                }),
            TextField(
              controller: pwd1Controller,
              focusNode: pwd1Focus,
              obscureText: true,
              decoration: InputDecoration(
                  labelText: H.getText(context, 'pwd_new'),
                  suffixIcon: Icon(Icons.vpn_key),
                  errorText: pwd1_invalid ? errMsg : null,
                  hintText: H.getText(context, 'pwd_new')),
            ),
            TextField(
                controller: pwd2Controller,
                obscureText: true,
                focusNode: pwd2Focus,
                decoration: InputDecoration(
                    labelText: H.getText(context, 'pwd_repeat'),
                    suffixIcon: Icon(Icons.vpn_key),
                    errorText: pwd2_invalid ? errMsg : null,
                    hintText: H.getText(context, 'pwd_repeat')),
                onSubmitted: (value) {
                  if (pwd1Controller.text != '' && pwd2Controller.text != '') {
                    _checkNewPassword(context);
                  }
                }),
            Padding(padding: EdgeInsets.only(top: 20)),
            Text(errMsg, style: TextStyle(color: Colors.red)),
          ],
        ),
      ),
    );
  }

  _checkNewPassword(BuildContext context) {
    setState(() {
      pwd1_invalid = pwd2_invalid = pwd0_invalid = false;
      pwd0Controller.text = pwd0Controller.text.trim();
      pwd1Controller.text = pwd1Controller.text.trim();
      pwd2Controller.text = pwd2Controller.text.trim();
    });
    if (pwd0Controller.text == '' && _pwdInit == false) {
      setState(() {
        pwd0_invalid = true;
        FocusScope.of(context).requestFocus(pwd0Focus);
        //Bitte Kennwort eingeben
        errMsg = H.getText(context, 'M006');
      });
    } else if (pwd0Controller.text != _oldPassword && _pwdInit == false) {
      setState(() {
        pwd0_invalid = true;
        FocusScope.of(context).requestFocus(pwd0Focus);
        //Kennwort ungültig
        errMsg = H.getText(context, 'M010');
      });
    } else if (pwd1Controller.text == '') {
      setState(() {
        pwd1_invalid = true;
        FocusScope.of(context).requestFocus(pwd1Focus);
        //Bitte Kennwort eingeben
        errMsg = H.getText(context, 'M006');
      });
    } else if (pwd1Controller.text != pwd2Controller.text) {
      setState(() {
        pwd2_invalid = true;
        pwd2Controller.text = '';
        FocusScope.of(context).requestFocus(pwd2Focus);
        //die Kennworte müssen gleich sein
        errMsg = H.getText(context, 'M011');
      });
    } else {
      // okay
      setState(() {});
      Navigator.of(context).pop(pwd1Controller.text);
    }
  }
}
