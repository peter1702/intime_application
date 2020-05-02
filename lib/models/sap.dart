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

  Future<void> checkSAPUserLogin (String usr, String pwd) async {
    String json  = '';
    LoginParam parm = new LoginParam();

    parm.username = usr;
    parm.password = pwd;
    json = jsonEncode(parm.toJson());

    await requestToSAP("check_user", "2", json, usr: usr, pwd: pwd);
  }

  Future<void> checkSecUserLogin (String usr, String pwd) async {
    String json  = '';
    LoginParam parm = new LoginParam();

    parm.username = usr;
    parm.password = pwd;
    json = jsonEncode(parm.toJson());

    await requestToSAP("check_user", "1", json);
  }

  Future<void> requestToSAP (String action, String step, String json, {String usr, String pwd}) async {

    String auth = buildAuthString(user:usr, password:pwd);
    String susr = '';
    Uri uri = buildURI ();
    int timeOut = 5;
    
    if (usr == null || usr == '')
      susr = globals.loginName;
    if (susr == '')
      susr = globals.userName;

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
      if (auth != null && auth.isNotEmpty)
        request.headers.add("Authorization", "Basic $auth");
      request.headers.add("Accept-Language", globals.loginLang);
      request.headers.add("Z-ACTION", action);
      request.headers.add("Z-STEP",   step);
      request.headers.add("Z-SUSER",  susr);
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

  }

  String buildAuthString ({String user='', String password=''}) {
    String sapAuthString;
    String usr; 
    String pwd;
    /*
    print("globals.usrSAP = " +globals.usrSAP);
    print("globals.loginName = " +globals.loginName);
    print("globals.loginSAP = "+ globals.loginSAP.toString());
    */
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

    //print("buildAuthString usr: $usr pwd: $pwd");
    return sapAuthString;
  }
  
  Uri buildURI () {
    String url = globals.hostSAP +
        ":" +
        globals.portSAP +
        "/" +
        globals.serviceSAP +
        "?" +
        "sap-client=" +
        globals.clientSAP +
        "&" +
        "sap-language=" +
        globals.loginLang;

    //Uri  uri  = Uri.parse('http://52.16.21.175:50000/sap/bc/zjsonconnect?sap-client=100');
    return Uri.parse(url);
  }

}

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