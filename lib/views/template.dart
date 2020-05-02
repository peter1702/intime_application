import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart'; //permissions needed!!

import '../helpers/helpers.dart';
import '../models/template.dart';
import '../globals.dart' as globals;

class TemplatePage extends StatefulWidget {
  TemplatePage({Key key, this.title}) : super(key: key);
  final String title;

  @override
  _TemplatePageState createState() => new _TemplatePageState();
}

class _TemplatePageState extends State<TemplatePage> {
  final GlobalKey<ScaffoldState> _scaffoldKey = new GlobalKey<ScaffoldState>();

  bool isChanged;
  Template template = new Template();
  TextEditingController mengeController;
  bool mengeInvalid = false;
  String errorMessage;
  FocusNode mengeFocus = new FocusNode();

  final Geolocator geolocator = Geolocator()..forceAndroidLocationManager;
  Position _currentPosition;
  String _currentAddress;

  _initializeData() {}

  // Initialzation
  @override
  void initState() {
    super.initState();
    _initializeData();
    mengeController = new TextEditingController();
    _getCurrentLocation();
  }

  void _onChanged(String value) {
    setState(() => isChanged = true);
  }

  void _onSubmit(String value) {
    String _value = '';
    setState(() => _value = 'Submit: ${value}');
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
          automaticallyImplyLeading: false, // Don't show the leading button
          title: RichText(
            text: TextSpan(children: [
              TextSpan(
                  text: H.getText(context, 'temp_title'),
                  style: globals.styleHeaderTitle),
              TextSpan(text: "\n"),
              TextSpan(
                text: H.getText(context, 'material') + " " + "600-100",
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
                    onPressed: () => _submitForm(context),
                    child: Text(H.getText(context, 'post'),
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
        return Container(
          margin: EdgeInsets.fromLTRB(17.0, 10.0, 17.0, 10.0),
          color: Colors.white,
          child: Column(children: <Widget>[
            // Displayfield
            Row(children: <Widget>[
              Expanded(
                flex: 3,
                child: Text(H.getText(context, 'description'),
                    style: globals.styleLabelDisplay),
              ),
              SizedBox(height: globals.heightRow),
              Expanded(
                flex: 7,
                child: Text(
                  "Nagel",
                  textAlign: TextAlign.right,
                  style: globals.styleDisplayField,
                ),
              ),
            ]),
            Divider(height: 10, thickness: 0.5, color: Colors.grey),
            // Displayfield
            Row(children: <Widget>[
              Expanded(
                flex: 3,
                child: Text(H.getText(context, 'available'),
                    style: globals.styleLabelDisplay),
              ),
              SizedBox(height: globals.heightRow),
              Expanded(
                flex: 7,
                child: Text(
                  "570 kg",
                  textAlign: TextAlign.right,
                  style: globals.styleDisplayField,
                ),
              ),
            ]),
            Divider(height: 10, thickness: 0.5, color: Colors.grey),
            // Inputfield
            Row(children: <Widget>[
              Expanded(
                flex: 3,
                child: Text(H.getText(context, 'quantity') + " *",
                    style: globals.styleLabelTextField),
              ),
              Expanded(
                flex: 7,
                child: SizedBox(
                  height: globals.heightRow,
                  child: TextField(
                    autofocus: true,
                    controller: mengeController,
                    focusNode: mengeFocus,
                    decoration: InputDecoration(
                      hintText: H.getText(context, 'M001'),
                      suffixText: 'ST',
                      focusedBorder: UnderlineInputBorder(
                        borderSide: BorderSide(color: Colors.green, width: 2),
                      ),
                     // focusedBorder: OutlineInputBorder(
                     //   borderSide: BorderSide(color: Colors.green),
                     // ),
                      //border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(0.0))),
                      errorText: Helpers.isFloat(mengeController.text)
                          ? null
                          : H.getText(context, 'M002'),
                      suffixIcon: IconButton(
                          icon: Icon(Icons.cancel, size: 20, color: Colors.grey),
                          //icon: Icon(Icons.clear),
                          onPressed: () {
                            mengeController.clear();
                          }),
                    ),
                    style: TextStyle(
                      fontSize: 18.0,
                    ),
                    keyboardType: TextInputType.number,
                    onChanged: _onChanged,
                    onSubmitted: _onSubmit,
                  ),
                ),
              ),
            ]),
            Divider(height: 10, thickness: 0.5, color: Colors.grey),
          ]),
        );
      }),
    );
  }

  /*---------------------------------------------------------------------------*/
  // geolocator
  /*---------------------------------------------------------------------------*/
  _getAddressFromLatLng() async {
    try {
      List<Placemark> p = await geolocator.placemarkFromCoordinates(
          _currentPosition.latitude, _currentPosition.longitude);

      Placemark place = p[0];
      setState(() {
        _currentAddress =
            "${place.locality}, ${place.postalCode}, ${place.country}, ${place.thoroughfare}, ${place.subThoroughfare}";
        print(_currentAddress);
      });
    } catch (e) {
      print(e);
    }
  }

  _getCurrentLocation() async {
    //final Geolocator geolocator = Geolocator()..forceAndroidLocationManager;
    GeolocationStatus geolocationStatus =
        await geolocator.checkGeolocationPermissionStatus();
    if (geolocationStatus == GeolocationStatus.disabled) {
      print(">> geolocationStatus = disabled");
      return;
    } else {
      geolocator
          .getCurrentPosition(desiredAccuracy: LocationAccuracy.best)
          .then((Position position) {
        setState(() {
          _currentPosition = position;
        });
        print(
            "LAT: ${_currentPosition.latitude}, LNG: ${_currentPosition.longitude}");
        _getAddressFromLatLng();
      }).catchError((e) {
        print(e);
        return;
      });

      List<Placemark> placemark = await Geolocator()
          .placemarkFromAddress("Am Dinschelt 9, 66957 Vinningen, Germany");
      if (!placemark.isEmpty) {
        Placemark place = placemark[0];
                print(
            "LAT: ${place.position.latitude}, LNG: ${place.position.longitude}");

        double meters = await geolocator.distanceBetween(
          _currentPosition.latitude,
          _currentPosition.longitude, 
          place.position.latitude,
          place.position.longitude
        );
        meters = meters / 1000;
        print(">>> distance "+meters.toString()+" km");

        placemark = await geolocator.placemarkFromCoordinates(place.position.latitude, place.position.longitude);
        if (!placemark.isEmpty) {
          place = placemark[0];
          _currentPosition = place.position;
          _getAddressFromLatLng();
        }
      }
    }
  }

  /*---------------------------------------------------------------------------*/
  // Message ausgeben
  /*---------------------------------------------------------------------------*/
  void _showMessage(String message, [MaterialColor color = Colors.red]) {
    _scaffoldKey.currentState.showSnackBar(
        new SnackBar(backgroundColor: color, content: new Text(message)));
  }

  /*---------------------------------------------------------------------------*/
  // Prüfen & Buchen
  /*---------------------------------------------------------------------------*/
  void _submitForm(BuildContext context) {
    mengeInvalid = false;
    errorMessage = null;

    if (mengeController.text == "") {
      mengeInvalid = true;
      errorMessage = H.getText(context, 'M001');
      FocusScope.of(context).requestFocus(mengeFocus);
      //_showMessage(errorMessage);
      H.message(context, msgTy: 'E', msgId: 'M001');
      return;
    }
    if (!Helpers.isFloat(mengeController.text)) {
      mengeInvalid = true;
      errorMessage = H.getText(context, 'M002');
      FocusScope.of(context).requestFocus(mengeFocus);
      //_showMessage(errorMessage);
      H.message(context, msgTy: 'E', msgId: 'M002');
      return;
    }

    setState(() {
      //template.menge = double.parse(mengeController.text);
      template.menge = Helpers.string2Double(mengeController.text);
    });

    //_showMessage("Die Buchung war erfolgreich", Colors.green);
    //H.showToast(context, "Die Buchung war erfolgreich", color: Colors.green);
    H.message(context, msgTy: 'S', msgId: 'M004');
  }
}
