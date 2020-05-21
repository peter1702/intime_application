import 'dart:async';
import 'dart:io';
import 'dart:convert';
import '../globals.dart' as globals;

class SAP {
  int returnCode = 0;
  String returnMssg   = '';
  String returnStatus = '';
  String returnData   = '';

  SAP({this.returnCode, this.returnMssg, this.returnStatus, this.returnData});

  // ------------------------------------------------------------------------------- //
  // Prüfen im SAP, ob der Benutzer gültig ist 
  // In diesem Fall muss es sich um einen 'echten' SAP-User handeln 
  // ------------------------------------------------------------------------------- //
  Future<void> checkSAPUserLogin (String usr, String pwd) async {
    String json  = '';
    LoginParam parm = new LoginParam();

    parm.username = usr;
    parm.password = pwd;
    json = jsonEncode(parm.toJson());

    await requestToSAP("check_user", "2", json, usr: usr, pwd: pwd);
  }
  // ------------------------------------------------------------------------------- //
  // Prüfen im SAP, ob der Benutzer gültig ist 
  // Bei "sekundärem" User wird gegen die Tabelle /BUP/MOB_USER geprüft 
  // ------------------------------------------------------------------------------- //
  Future<void> checkSecUserLogin (String usr, String pwd) async {
    String json  = '';
    LoginParam parm = new LoginParam();

    parm.username = usr;
    parm.password = pwd;
    json = jsonEncode(parm.toJson());

    await requestToSAP("check_user", "1", json);
  }
  // ------------------------------------------------------------------------------- //
  // Aufruf von SAP 
  // Der Aufruf kann direkt zum SAP gehen. Dann müssen alle SAP-Anmeldedaten
  // gefüllt sein. Oder der Aufruf geht zuerst an einen HTTP-Server. Dann muss
  // der Hostname und der Port des HTTP-Servers gefüllt sein. Die Anmeldedaten 
  // werden beim HTTP-Server abgelegt. 
  // Meldet sich der User mit einem "sekundären" User an, ist auch SAP-User und 
  // SAP-Kennwort auf dem HTTP-Server.  
  // ------------------------------------------------------------------------------- //
  Future<void> requestToSAP (String action, String step, String json, {String usr, String pwd}) async {

    String auth = buildAuthString(user:usr, password:pwd);
    String susr = '';
    String spwd = '';
    Uri uri = buildURI ();
    int timeOut = 5;
    
    if (usr == null || usr == '')
      susr = globals.loginName;
    if (susr == '')
      susr = globals.userName;
    if (pwd == null || pwd == '')
      spwd = globals.loginPwd;

    final client = new HttpClient();
    if (timeOut != null) {
      client.connectionTimeout = Duration(seconds: timeOut);
    }
    try {
      final body = utf8.encode(json);
      final request = await client.postUrl(uri);

      // Build Header
      request.headers.add("Content-Length", body.length);
      request.headers.add("Content-Type", "application/json");
      if (auth != null && auth.isNotEmpty) {
        request.headers.add("Authorization", "Basic $auth");
      }
      request.headers.add("Accept-Language", globals.loginLang);
      request.headers.add("Z-ACTION", action);
      request.headers.add("Z-STEP",   step);
      request.headers.add("Z-SUSER",  susr);
      request.headers.add("Z-SPASS",  spwd);
      request.headers.add("Z-DEVICE", globals.deviceId);
      //request.cookies.addAll(cookie.loadForRequest(uri)); // Must be before filling the body 
      request.add(body);

      final response = await request.close();
      print("...request.close / response.statusCode="+response.statusCode.toString());

      //cookie.saveFromResponse(uri, response.cookies);
      returnCode = 0;
      returnData = '';

      if (response.statusCode >= 400) {
        returnStatus = response.statusCode.toString();
        switch (response.statusCode) {
          case 401:
            returnCode = 1;
            returnMssg = 'The username or password you entered is incorrect';
            break;
          case 403:
            returnCode = 1;
            returnMssg = 'User can not be logged in';
            break;
          default:
            if (response.statusCode < 500) {
              returnCode = 1;
              returnMssg = 'Error in the data on the side of the mobile application';
            } else {
              returnCode = 1;
              if (returnMssg == null || returnMssg == '')
                returnMssg = 'Internal server error';
            }
            break;
        }
      } else {
        //print(response.headers);
        returnStatus = response.headers.value('Z-STATUS');
        returnMssg   = response.headers.value('Z-RMESS');

        returnData = await response.transform(Utf8Decoder()).join();

        if (returnStatus == null || returnStatus.isEmpty) {
          returnStatus = '901'; //PostStatus.Error;
          returnCode   = 1;
          if(returnMssg == '')
            returnMssg   = 'Invalid answer from SAP HTTP requestor';
        }
        if (returnStatus != '900') {
          returnCode = 1;
        }
        print(">>> ReturnStatus...$returnStatus");
        print(">>> ReturnCode....."+returnCode.toString());
        print(">>> ReturnMssg.....$returnMssg");
        print(">>> ReturnData.len."+returnData.length.toString());
        //print(">>> ReturnData.....$returnData");
      }
    } on TimeoutException catch (e) {
        returnMssg   = e.message;
        if (returnMssg == null || returnMssg == '' )
          returnMssg = 'timeout';
        returnCode   = 1;
        returnStatus = '778';   
    } on SocketException catch (e) {
        returnMssg   = e.message;
        if (returnMssg == null || returnMssg == '' )
          returnMssg = 'socket exception';
        returnCode   = 1;
        returnStatus = '779'; 
    } catch (e) {
      String msg;
      try {
        msg = e.message;
      } catch (me) {
        msg = "";
      }
      if (msg == null || msg.isEmpty) {
        if (e is SocketException)
          msg = 'Connection error - Post error processing';
        else
          msg = e.toString();
      }
      returnMssg   = msg;
      returnCode   = 1;
      returnStatus = '777';
    }
    if (returnCode != 0) {
      print("ReturnCode..... "+returnCode.toString());
      print("ReturnStatus... "+returnStatus);
      print("ReturnMssg..... "+returnMssg);
    }

  }
  // ------------------------------------------------------------------------------- //
  // User-Kennung und Passwort in einen String.
  // Benutzer und Passwort werden abhängig vom Anmeldeverfahren ermittelt. 
  // Bei einer Anmeldung mit einem "sekundären" Benutzer, wird der SAP-User vom admin
  // in den Parametern hinterlegt. Bei Nutzung eines HTTP-Servers können die 
  // Anmeldedaten auch dort zentral hinterlegt werden. 
  // ------------------------------------------------------------------------------- //
  String buildAuthString ({String user='', String password=''}) {
    String sapAuthString;
    String usr; 
    String pwd;
    
    if (globals.usrSAP == null) globals.usrSAP = '';
    if (globals.pwdSAP == null) globals.pwdSAP = '';
    if (globals.loginSAP == null) globals.loginSAP = false;
    if (globals.sapAnonym == null) globals.sapAnonym = false;
    if (globals.loginName == null) globals.loginName = '';
    if (user == null) user = '';
    if (password == null) password = '';

    print("globals.usrSAP = " +globals.usrSAP);
    print("globals.loginName = " +globals.loginName);
    print("globals.loginSAP = "+ globals.loginSAP.toString());
    
    // Prüfen, wie die Anmeldung an SAP erfolgen soll
    if (globals.loginSAP) {
      // der Login-Name entspricht dem SAP-Benutzer
      usr = globals.loginName;
      pwd = globals.loginPwd;
      if(user != null && user != '') {
        usr = user;
        if(password != null && password != '') {
          pwd = password;
        }
      }
      usr = usr.trim();
      pwd = pwd.trim();
      //print("usr:$usr:$pwd");
      sapAuthString = base64Encode(utf8.encode('$usr:$pwd'));

    } else if (globals.sapAnonym) {
      // die Anmeldung erfolgt anonym (Benutzer im Service hinterlegt)
      sapAuthString = '';

    } else {
      // die Anmeldung erfolgt mit dem lokal hinterlegten Benutzer 
      if (user == null || user == '') {
        usr = globals.usrSAP;
      } else {
        usr = user;
      }
      if (password == null || password == '') {
        pwd = globals.pwdSAP;
      } else {
        pwd = password;
      }
      usr = usr.trim();
      pwd = pwd.trim();
      // optional könnte man hier noch das Passwort über Dialog abfragen
      sapAuthString = base64Encode(utf8.encode('$usr:$pwd'));
    }
    if (usr == '') {
      print("buildAuthString usr: $usr pwd: $pwd");
    }
    return sapAuthString;
  }
  // ------------------------------------------------------------------------------- //
  // Bilden der URI
  // Bei einer Anmeldung am HTTP-Server keinen Service hinterlegen! 
  // ------------------------------------------------------------------------------- //
  Uri buildURI () {

    if (globals.hostSAP == null) globals.hostSAP = '';
    if (globals.portSAP == null) globals.portSAP = '';
    if (globals.serviceSAP == null) globals.serviceSAP = '';
    if (globals.clientSAP == null) globals.clientSAP = '';

    globals.hostSAP = globals.hostSAP.trim();
    globals.serviceSAP = globals.serviceSAP.trim();

    String url = globals.hostSAP +
        ":" +
        globals.portSAP; 

    if (globals.serviceSAP != null && globals.serviceSAP != '') {
      url = url +
        "/" +
        globals.serviceSAP +
        "?" +
        "sap-client=" +
        globals.clientSAP +
        "&" +
        "sap-language=" +
        globals.loginLang;
    }
    //print("url: "+url);

    return Uri.parse(url);
  }

}
// ------------------------------------------------------------------------------- //
// Struktur für die Login-Parameter 
// ------------------------------------------------------------------------------- //
class LoginParam {
  String username; 
  String password; 

  LoginParam({this.username, this.password});

  factory LoginParam.fromJson(Map<String, dynamic> json) {
    return new LoginParam(
      username: json['username'] as String,
      password: json['password'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'username': username,
      'password': password,
    };
  }
}
// ------------------------------------------------------------------------------- //
// Struktur für die zurückgegebenen User-Daten aus SAP 
// ------------------------------------------------------------------------------- //
class UserParam {
  String username; 
  String password; 
  bool   isvalid;
  String language;
  String name1;
  String bereich; 
  String menue; 
  String lgnum; 

  UserParam({this.username, 
             this.password, 
             this.isvalid, 
             this.language, 
             this.name1,
             this.bereich,
             this.menue,
             this.lgnum,
            });

  factory UserParam.fromJson(Map<String, dynamic> json) {
    return new UserParam(
      username: json['username'] as String,
      password: json['password'] as String,
      isvalid:  json['isvalid']  as bool,
      language: json['language'] as String,
      name1:    json['name1']    as String,
      bereich:  json['bereich']  as String,
      menue:    json['menue']    as String,
      lgnum:    json['lgnum']    as String,
    );
  }
}