import 'package:flutter/material.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';

import '../models/tour.dart';
import '../models/units.dart';
import '../helpers/helpers.dart';
import '../globals.dart' as globals;

class VollgutPage extends StatefulWidget {
  VollgutPage(
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
  _VollgutPageState createState() => new _VollgutPageState();
}

class _VollgutPageState extends State<VollgutPage> {
  final GlobalKey<ScaffoldState> _scaffoldKey = new GlobalKey<ScaffoldState>();

  Delivery delivery;
  Tour tourData;
  int currentTabIndex = 0;
  bool readonly;

  _initializeData() {
    //tourData = Tour.getBuffer(widget.routno, widget.drivno);
    tourData = widget.tourData;
    print("start delivery item - tour: "+tourData.routno);
    delivery = tourData.delvList[widget.dlvIndex];
    if (delivery.itemList == null) {
      delivery.itemList = [];
    }
    if (delivery.lgutList == null) {
      delivery.lgutList = [];
    }
    globals.changeData = false;
    readonly = widget.readonly;
  }

  Future<bool> _exitApp(BuildContext context) {
    print("Exit App -> data changed: " + globals.changeData.toString());
    if (readonly == false && globals.changeData == true) {
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
          /* ---------- appBar --------------------------------------------------*/
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
                  TextSpan(
                      text: readonly
                          ? H.getText(context, 'filled') +
                              " - " +
                              H.getText(context, 'disp')
                          : H.getText(context, 'filled') +
                              " - " +
                              H.getText(context, 'proc'),
                      style: globals.styleHeaderTitle),
                  TextSpan(text: "\n"),
                  TextSpan(
                    text: H.getText(context, 'delivery') + ' ' + delivery.dlvno,
                    style: globals.styleHeaderSubTitle,
                  )
                ]),
              ),
            ),
          ),
          /*
          floatingActionButton: FloatingActionButton(
            onPressed: () async {},
            backgroundColor: globals.actionColor,
            child: Icon(Icons.add),
          ),
          */
          body: BuildFilledList(
              delivery: delivery,
              routno: widget.routno,
              drivno: widget.drivno,
              dlvIndex: widget.dlvIndex,
              readonly: readonly),
        ));
  }
}

/*---------------------------------------------------------------------------*/
// Liste mit Vollgut
/*---------------------------------------------------------------------------*/
class BuildFilledList extends StatelessWidget {
  BuildFilledList(
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

  String _getHint(context, DelvItem item) {
    String str = '';
    if (item.shortage || item.fmeng > 0) {
      str = H.getText(context, 'shortage');
      str = str + '!';
    }
    if (item.damaged || item.bmeng > 0) {
      str = H.getText(context, 'breakage');
      str = str + '!';
    }
    return str;
  }

  @override
  Widget build(BuildContext context) {
    return StatefulBuilder(builder: (BuildContext ctxt, StateSetter setState) {
      return (delivery.itemList.length == 0)
          ? Container()
          : ListView.builder(
              itemCount: delivery.itemList.length,
              itemBuilder: (context, index) {
                return Card(
                  elevation: 5,
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(0, 10, 10, 15),
                    child: Column(children: <Widget>[
                      //margin: EdgeInsets.fromLTRB(10.0, 10.0, 0.0, 10.0),
                      Row(children: <Widget>[
                        Expanded(
                          flex: 1,
                          child: Column(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: <Widget>[
                                Container(
                                  /*
                                  margin: EdgeInsets.all(0),
                                  padding: EdgeInsets.all(0),
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(100),
                                    border: Border.all(width: 2, color: Colors.grey),
                                  ),  
                                  */
                                  child: IconButton(
                                    icon: Icon(Icons.more_horiz,
                                        color: globals.primaryColor),
                                    onPressed: () async {
                                      final ItemDetail detail = new ItemDetail(
                                          context: context, readonly: readonly);
                                      //DelvItem item = new DelvItem();
                                      //item = await detail.HandleItem(
                                      await detail.HandleItem(
                                          delivery, delivery.itemList[index]);
                                      setState(() {
                                        //delivery.itemList[index] = item;
                                      });
                                    },
                                  ),
                                ),
                              ]),
                        ),
                        SizedBox(height: 55, width: 10),
                        Expanded(
                          flex: 8,
                          child: Column(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              mainAxisAlignment: MainAxisAlignment.start,
                              children: <Widget>[
                                // Artikel
                                Container(
                                  alignment: Alignment.topLeft,
                                  padding: EdgeInsets.only(top: 5.0),
                                  child: Text(
                                      H.getText(context,"article",suffix:": ")+
                                          delivery.itemList[index].matnr,
                                      style: globals.styleTextBigBold),
                                ),
                                // Bezeichnung
                                Container(
                                  alignment: Alignment.topLeft,
                                  padding: EdgeInsets.only(top: 5.0),
                                  child: Text(delivery.itemList[index].maktx,
                                      style: globals.styleTextBigBold),
                                ),
                                // Abmessungen
                                Container(
                                  alignment: Alignment.topLeft,
                                  padding: EdgeInsets.only(top: 5.0),
                                  child: Text(delivery.itemList[index].abmes,
                                      style: globals.styleTableTextNormal),
                                ),
                                // Menge
                                Container(
                                    alignment: Alignment.topLeft,
                                    padding:
                                        EdgeInsets.only(top: 5.0, right: 10.0),
                                    child: Row(
                                      children: <Widget>[
                                        Expanded(
                                          flex: 3,
                                          child: Text(
                                              H.getText(context,"quantity",suffix:": "),
                                              style: globals.styleTextNormal),
                                        ),
                                        Expanded(
                                          flex: 3,
                                          child: Text(
                                              Helpers.double2String(
                                                      delivery.itemList[index]
                                                          .lfimg,
                                                      decim: delivery
                                                          .itemList[index]
                                                          .vdeci) +
                                                  " " +
                                                  delivery
                                                      .itemList[index].vrkme,
                                              textAlign: TextAlign.right,
                                              style: globals.styleTextBigBold),
                                        ),
                                        Expanded(
                                          flex: 4,
                                          child: Text(
                                              _getHint(context,
                                                  delivery.itemList[index]),
                                              textAlign: TextAlign.right,
                                              style: TextStyle(
                                                  fontSize: 18,
                                                  color: Colors.red)),
                                        ),
                                      ],
                                    )),
                              ]),
                        ),
                        Expanded(
                          flex: 1,
                          child: Column(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              mainAxisAlignment: MainAxisAlignment.start,
                              children: <Widget>[
                                new Checkbox(
                                  activeColor: readonly
                                      ? Colors.grey
                                      : globals.primaryColor,
                                  value: delivery.itemList[index].completed,
                                  onChanged: (bool value) {
                                    setState(() {
                                      if (readonly == false)
                                        _checkboxChanged(value, index);
                                    });
                                  },
                                ),
                              ]),
                        ),
                      ]),
                    ]),
                  ),
                );
              });
    });
  }

  _checkboxChanged(bool value, int index) {
    //print(index);
    delivery.itemList[index].completed = value;
    if (delivery.itemList[index].changeKz == '')
      delivery.itemList[index].changeKz = 'U';
    delivery.changeKz = 'U';
    globals.changeData = true;
  }
}

/*---------------------------------------------------------------------------*/
// Positionsdetail (Erfassung Bruch, Fehlmenge, Fotos)
/*---------------------------------------------------------------------------*/
class ItemDetail {
  ItemDetail({this.context, this.readonly: true});
  BuildContext context;
  bool readonly;

  String detail_title = '';

  double orgmenge = 0.0;
  String orgmeins = '';
  int orgdecim = 0;

  Future<DelvItem> HandleItem(Delivery delivery, DelvItem delvItem) async {
    //
    TextEditingController bmengController = TextEditingController();
    TextEditingController fmengController = TextEditingController();

    bool isChanged = false;
    bool bmengInvalid = false;
    bool fmengInvalid = false;
    String errorMessage = '';

    orgmenge = delvItem.lfimg; //menge;
    orgmeins = delvItem.vrkme; //meins
    orgdecim = delvItem.vdeci; //decim;

    //
    if (delvItem.bmeng == 0) {
      bmengController.text = '';
    } else {
      bmengController.text =
          Helpers.double2String(delvItem.bmeng, decim: delvItem.decim);
    }
    if (delvItem.fmeng == 0) {
      fmengController.text = '';
    } else {
      fmengController.text =
          Helpers.double2String(delvItem.fmeng, decim: delvItem.decim);
    }
    FocusNode fmengFocus = new FocusNode();
    FocusNode bmengFocus = new FocusNode();
    if (delvItem.bmein == '') delvItem.bmein = delvItem.meins;
    if (delvItem.fmein == '') delvItem.fmein = delvItem.meins;
    if (delvItem.vrkme == '') delvItem.vrkme = delvItem.meins;
    if (delvItem.lfimg == 0.0) delvItem.lfimg = delvItem.menge;

    detail_title =
        H.getText(context, 'item') + " " + H.getText(context, 'detail');
    if (readonly) {
      detail_title = detail_title + " - " + H.getText(context, 'disp');
    } else {
      detail_title = detail_title + " - " + H.getText(context, 'proc');
    }

    /*-------------------------------------------------------------------------*/
    // Prüfen der Eingaben (Bruchmenge, Fehlmenge)
    /*-------------------------------------------------------------------------*/
    bool _checkInput() {
      double d;
      bmengInvalid = false;
      fmengInvalid = false;
      if (fmengController.text != '') {
        d = Helpers.string2Double(fmengController.text);
        if (delvItem.fmein == null || delvItem.fmein == '') {
          delvItem.fmein = delvItem.meins;
        }
        if (delvItem.fmein != delvItem.meins) {
          Units unit = delvItem.unitsList
              .where((el) => el.meins == delvItem.fmein)
              .toList()[0];
          if (unit != null &&
              unit.umrez != 0 &&
              unit.umrez > 0 &&
              unit.umren > 0) {
            delvItem.fdeci = unit.decim;
            d = d * unit.umrez / unit.umren;
            print("Menge in " + delvItem.fmein + " = " + d.toString());
          }
        }
        print("checkInput " + d.toString() + " > " + delvItem.menge.toString());
        if (d > delvItem.menge) {
          fmengInvalid = true;
          errorMessage = 'größer als Gesamtmenge';
          fmengFocus.requestFocus();
          return false;
        }
      }
      if (bmengController.text != '') {
        d = Helpers.string2Double(bmengController.text);
        if (delvItem.bmein == null || delvItem.bmein == '') {
          delvItem.bmein = delvItem.meins;
        }
        if (delvItem.bmein != delvItem.meins) {
          Units unit = delvItem.unitsList
              .where((el) => el.meins == delvItem.bmein)
              .toList()[0];
          if (unit != null &&
              unit.umrez != 0 &&
              unit.umrez > 0 &&
              unit.umren > 0) {
            delvItem.bdeci = unit.decim;
            d = d * unit.umrez / unit.umren;
            print("Menge in " + delvItem.bmein + " = " + d.toString());
          }
        }
        if (d > delvItem.menge) {
          bmengInvalid = true;
          errorMessage = 'größer als Gesamtmenge';
          bmengFocus.requestFocus();
          return false;
        }
      }
      return true;
    }

    /*-------------------------------------------------------------------------*/
    // Modal Bottom Sheet -> Menü von unten hochpoppen
    /*-------------------------------------------------------------------------*/
    String _selected = '';
    List<String> _items = ['Foto aufnehmen', 'Foto aus Gallerie'];

    void _showModalSheet(context) async {
      var index = await showModalBottomSheet(
        context: context,
        builder: (context) {
          return Container(
            padding: EdgeInsets.all(8),
            height: 100,
            alignment: Alignment.center,
            child: ListView.separated(
              itemCount: _items.length,
              separatorBuilder: (context, int) {
                return Divider();
              },
              itemBuilder: (context, index) {
                return GestureDetector(
                    child: Text(_items[index]),
                    onTap: () {
                      //setState(() {
                      _selected = _items[index];
                      //});
                      Navigator.of(context).pop(index);
                    });
              },
            ),
          );
        },
      );
      print("index: " + index.toString()); // null - when closed
    }

    /*-------------------------------------------------------------------------*/
    // Bottom Navigation Bar auswerten
    /*-------------------------------------------------------------------------*/
    void _onNavigationBarTapped(BuildContext context, int index) async {
      switch (index) {
        case 0: // Exit
          bool okay = _checkInput();
          if (okay) Navigator.pop(context, true);
          break;
        case 1: // Foto hinzufügen
          //_showModalSheet(context); // -> wartet nicht!!
          _addPhoto(context, delivery, delvItem, gallery: false);
          break;
        case 2: // Fotos anzeigen
          _displayGallery(context, delivery, delvItem);
          break;
      }
    }

    /*-------------------------------------------------------------------------*/
    // Prüfungen nach Eingabe
    /*-------------------------------------------------------------------------*/
    void _onSubmit(String value) {
      bool okay = _checkInput();
      print("_onSubmit - okay: " + okay.toString());
    }

    /*-------------------------------------------------------------------------*/
    // Prüfungen nach Drücken der Back-Taste
    /*-------------------------------------------------------------------------*/
    Future<bool> _willPopCallback() async {
      print("_willPopCallback - changed: " + isChanged.toString());
      return _checkInput();
    }

    /*-------------------------------------------------------------------------*/
    // Select Unit
    /*-------------------------------------------------------------------------*/
    Future<String> _selectUnit(
        BuildContext context, DelvItem delvItem, String uom, int decim) async {
      String selectTitle = H.getText(context, 'unitOfMeasure');
      String currentValue = uom;

      List<Parameter> valueList = [];
      delvItem.unitsList
          .forEach((unit) => valueList.add(Parameter(unit.meins, unit.bezei)));

      if (valueList.length == 0) valueList.add(Parameter(uom, uom));

      String newUom =
          await _selectValue(context, selectTitle, valueList, currentValue);
      if (newUom != null && newUom != '') {
        return newUom;
      } else {
        return uom;
      }
    }
    /*-------------------------------------------------------------------------*/
    // angezeigte Menge umrechnen nach Änderung der Mengeneinheit
    /*-------------------------------------------------------------------------*/
    void _mengeUmrechnen() {
      if (orgmeins == delvItem.meins) {
        orgmenge = delvItem.menge;
        orgmeins = delvItem.meins;
        orgdecim = delvItem.decim;
        return;
      }
      if (orgmeins == delvItem.vrkme) {
        orgmenge = delvItem.lfimg;
        orgmeins = delvItem.vrkme;
        orgdecim = delvItem.vdeci;
        return;
      }
      Units unit =
          delvItem.unitsList.where((el) => el.meins == orgmeins).toList()[0];
      if (unit != null && unit.umrez != 0 && unit.umrez > 0 && unit.umren > 0) {
        orgdecim = unit.decim;
        orgmenge = delvItem.menge * unit.umren / unit.umrez;
      }
    }

    /*-------------------------------------------------------------------------*/
    // Dialog zum Anzeigen/Ändern der Position
    /*-------------------------------------------------------------------------*/
    await showGeneralDialog(
      context: context,
      pageBuilder: (BuildContext context, Animation<double> animation,
          Animation<double> secondaryAnimation) {
        return StatefulBuilder(
            builder: (BuildContext context, StateSetter setState) {
          return WillPopScope(
            onWillPop: _willPopCallback,
            child: Scaffold(
              appBar: new AppBar(
                title: new Text(detail_title),
                backgroundColor: globals.primaryColor,
                automaticallyImplyLeading: false,
              ),
              bottomNavigationBar: BottomNavigationBar(
                onTap: (index) {
                  setState(() {
                    _onNavigationBarTapped(context, index);
                  });
                },
                //currentIndex: 0, // this will be set when a new tab is tapped
                items: [
                  BottomNavigationBarItem(
                    //icon: new Icon(Icons.arrow_back_ios),
                    icon: new Icon(Icons.exit_to_app),
                    title: new Text(H.getText(context, "back")),
                  ),
                  BottomNavigationBarItem(
                    icon: new Icon(Icons.add_a_photo), //select_all
                    title: new Text(
                        H.getText(context, H.getText(context, "add_photo"))),
                  ),
                  BottomNavigationBarItem(
                    icon: new Icon(Icons.photo_library),
                    //icon: new Icon(Icons.crop_original),
                    title: new Text(
                        H.getText(context, H.getText(context, "show_photo"))),
                  )
                ],
              ),
              body: Padding(
                padding: EdgeInsets.all(17),
                child: SingleChildScrollView(
                  child: Column(children: <Widget>[
                    // Artikel-Nummer
                    Row(children: <Widget>[
                      Expanded(
                        flex: 3,
                        child: Text(H.getText(context, 'article'),
                            style: globals.styleLabelDisplay),
                      ),
                      SizedBox(height: globals.heightRow),
                      Expanded(
                        flex: 7,
                        child: Text(
                          delvItem.matnr,
                          textAlign: TextAlign.right,
                          style: globals.styleDisplayField,
                        ),
                      ),
                    ]),
                    Divider(height: 10, thickness: 0.5, color: Colors.grey),
                    // Artikel-Bezeichnung
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
                          delvItem.maktx,
                          textAlign: TextAlign.right,
                          style: globals.styleDisplayField,
                        ),
                      ),
                    ]),
                    Divider(height: 10, thickness: 0.5, color: Colors.grey),
                    // Artikel-Bezeichnung
                    Row(children: <Widget>[
                      Expanded(
                        flex: 3,
                        child: Text(H.getText(context, 'dimension'),
                            style: globals.styleLabelDisplay),
                      ),
                      SizedBox(height: globals.heightRow),
                      Expanded(
                        flex: 7,
                        child: Text(
                          delvItem.abmes,
                          textAlign: TextAlign.right,
                          style: globals.styleDisplayField,
                        ),
                      ),
                    ]),
                    Divider(height: 10, thickness: 0.5, color: Colors.grey),
                    //Menge
                    Row(children: <Widget>[
                      Expanded(
                        flex: 4,
                        child: Text(H.getText(context, 'quantity'),
                            style: globals.styleLabelDisplay),
                      ),
                      SizedBox(height: globals.heightRow),
                      Expanded(
                        flex: 5,
                        child: Text(
                          /*
                          Helpers.double2String(delvItem.menge,
                                  decim: delvItem.decim) +
                              " " +
                              delvItem.meins,
                          */
                          Helpers.double2String(orgmenge, decim: orgdecim) +
                              " " +
                              orgmeins,
                          textAlign: TextAlign.right,
                          style: globals.styleDisplayField,
                        ),
                      ),
                      // Selektion der Mengeneinheit
                      Expanded(
                        flex: 1,
                        child: SizedBox(
                          width: 25,
                          child: IconButton(
                            icon: Icon(Icons.arrow_drop_down),
                            onPressed: () async {
                              orgmeins = await _selectUnit(
                                  context, delvItem, orgmeins, orgdecim);
                              setState(() {
                                _mengeUmrechnen();
                                orgmeins = orgmeins;
                                orgmenge = orgmenge;
                                orgdecim = orgdecim;
                              });
                            },
                          ),
                        ),
                      ),
                    ]),
                    Divider(height: 10, thickness: 0.5, color: Colors.grey),
                    //Switch "Position fehlt komplett"
                    Row(children: <Widget>[
                      Expanded(
                        //flex: 4,
                        child: Text(H.getText(context, 'short_compl'),
                            style: globals.styleLabelDisplay),
                      ),
                      SizedBox(height: globals.heightRow),
                      Container(
                        alignment: Alignment.centerRight,
                        child: Switch(
                          value: delvItem.shortage,
                          onChanged: (value) {
                            if (readonly == false) {
                              setState(() {
                                isChanged = true;
                                delvItem.shortage = value;
                                fmengController.text = '';
                                bmengController.text = '';
                              });
                            }
                          },
                          //activeTrackColor: Colors.lightGreenAccent,
                          activeColor: globals.primaryColor,
                        ),
                      ),
                    ]),
                    Divider(height: 10, thickness: 0.5, color: Colors.grey),
                    //Fehlmenge
                    Row(children: <Widget>[
                      Expanded(
                        flex: 5,
                        child: Text(
                            H.getText(context, 'short_quan'),
                            style: globals.styleLabelDisplay),
                      ),
                      SizedBox(height: globals.heightRow),
                      Expanded(
                        flex: 4,
                        child: SizedBox(
                          height: globals.heightRow,
                          child: TextField(
                            //autofocus: true,
                            enabled: !delvItem.shortage &&
                                !delvItem.damaged &&
                                !readonly,
                            controller: fmengController,
                            focusNode: fmengFocus,
                            decoration: InputDecoration(
                              suffixText: delvItem.fmein,
                              hintText: '...',
                              focusedBorder: UnderlineInputBorder(
                                borderSide: BorderSide(
                                    color: globals.primaryColor, width: 2),
                              ),
                              errorText: Helpers.isFloat(fmengController.text)
                                  ? fmengInvalid ? errorMessage : null
                                  : H.getText(context, 'M002'),
                              /*
                              suffixIcon: readonly
                                  ? null
                                  : IconButton(
                                      icon: Icon(Icons.cancel,
                                          size: 20, color: Colors.grey),
                                      onPressed: () {
                                        fmengInvalid = false;
                                        fmengController.clear();
                                      }),
                              */
                            ),
                            //style: globals.styleInputField,
                            style: TextStyle(
                                color: globals.primaryColor,
                                fontSize: 18,
                                fontWeight: FontWeight.bold),
                            keyboardType: TextInputType.number,
                            onChanged: (val) => setState(() {
                              isChanged = true;
                            }),
                            onSubmitted: (val) => setState(() {
                              _onSubmit(val);
                            }),
                          ),
                        ),
                      ),

                      // Selektion Mengeneinheit
                      Expanded(
                        flex: 1,
                        child: SizedBox(
                          width: 25,
                          child: IconButton(
                            icon: Icon(Icons.arrow_drop_down),
                            onPressed: () async {
                              delvItem.fmein = await _selectUnit(context,
                                  delvItem, delvItem.fmein, delvItem.fdeci);
                              setState(() {
                                delvItem.fmein = delvItem.fmein;
                                _checkInput();
                              });
                            },
                          ),
                        ),
                      ),
                    ]),
                    Divider(height: 10, thickness: 0.5, color: Colors.grey),
                    //Position ist komplett beschädigt
                    Row(children: <Widget>[
                      Expanded(
                        //flex: 4,
                        child: Text(H.getText(context, 'break_compl'),
                            style: globals.styleLabelDisplay),
                      ),
                      SizedBox(height: globals.heightRow),
                      Container(
                        alignment: Alignment.centerRight,
                        child: Switch(
                          value: delvItem.damaged,
                          onChanged: (value) {
                            if (readonly == false) {
                              setState(() {
                                isChanged = true;
                                delvItem.damaged = value;
                                bmengController.text = '';
                                fmengController.text = '';
                              });
                            }
                          },
                          //activeTrackColor: Colors.lightGreenAccent,
                          activeColor: globals.primaryColor,
                        ),
                      ),
                    ]),
                    Divider(height: 10, thickness: 0.5, color: Colors.grey),
                    //Bruchmenge
                    Row(children: <Widget>[
                      Expanded(
                        flex: 5,
                        child: Text(H.getText(context, 'break_quan'),
                            style: globals.styleLabelDisplay),
                      ),
                      SizedBox(height: globals.heightRow),
                      Expanded(
                        flex: 4,
                        child: SizedBox(
                          height: globals.heightRow,
                          child: TextField(
                            enabled: !delvItem.shortage &&
                                !delvItem.damaged &&
                                !readonly,
                            controller: bmengController,
                            focusNode: bmengFocus,
                            decoration: InputDecoration(
                              hintText: '...', //H.getText(context, 'M001'),
                              suffixText: delvItem.bmein,
                              focusedBorder: UnderlineInputBorder(
                                borderSide: BorderSide(
                                    color: globals.primaryColor, width: 2),
                              ),
                              errorText: Helpers.isFloat(bmengController.text)
                                  ? bmengInvalid ? errorMessage : null
                                  : H.getText(context, 'M002'),
                              /*
                              suffixIcon: readonly
                                  ? null
                                  : IconButton(
                                      icon: Icon(Icons.cancel,
                                          size: 20, color: Colors.grey),
                                      onPressed: () {
                                        bmengInvalid = false;
                                        bmengController.clear();
                                      }),
                              */
                            ),
                            //style: globals.styleInputField,
                            style: TextStyle(
                                color: globals.primaryColor,
                                fontSize: 18,
                                fontWeight: FontWeight.bold),
                            keyboardType: TextInputType.number,
                            onChanged: (val) => setState(() {
                              isChanged = true;
                            }),
                            onSubmitted: (val) => setState(() {
                              _onSubmit(val);
                            }),
                          ),
                        ),
                      ),
                      // Selektion der Mengeneinheit für die Bruchmenge
                      Expanded(
                        flex: 1,
                        child: SizedBox(
                          width: 25,
                          child: IconButton(
                            icon: Icon(Icons.arrow_drop_down),
                            onPressed: () async {
                              delvItem.bmein = await _selectUnit(context,
                                  delvItem, delvItem.bmein, delvItem.bdeci);
                              setState(() {
                                delvItem.bmein = delvItem.bmein;
                                print("new: " +
                                    delvItem.bmein +
                                    " deci " +
                                    delvItem.bdeci.toString());
                                _checkInput();
                              });
                            },
                          ),
                        ),
                      ),
                    ]),
                    Divider(height: 10, thickness: 0.5, color: Colors.grey),
                    // Anzahl Fotos
                    Row(children: <Widget>[
                      Expanded(
                        flex: 2,
                        child: Text(H.getText(context, 'images'),
                            style: globals.styleLabelDisplay),
                      ),
                      SizedBox(height: globals.heightRow),
                      Expanded(
                        flex: 1,
                        child: Text(delvItem.images.toString(),
                            textAlign: TextAlign.right,
                            style: globals.styleDisplayField),
                      ),
                      Expanded(
                        flex: 5,
                        child: Container(),
                      ),
                    ]),
                    //Divider(height: 10, thickness: 0.5, color: Colors.grey),
                  ]),
                ),
              ),
            ),
          );
        });
      },
      barrierDismissible: true,
      barrierColor: Colors.black,
      barrierLabel: "???",
      transitionDuration: const Duration(milliseconds: 200),
    ).whenComplete(() {
      //_buildReturnList();
      //return returnLeergutList;
    });

    if (isChanged) {
      if (fmengController.text == '') {
        delvItem.fmeng = 0.0;
      } else {
        delvItem.fmeng = Helpers.string2Double(fmengController.text);
      }
      if (bmengController.text == '') {
        delvItem.bmeng = 0.0;
      } else {
        delvItem.bmeng = Helpers.string2Double(bmengController.text);
      }
      if (delvItem.changeKz != 'I') delvItem.changeKz = 'U';
      globals.changeData = true;
    }
    return delvItem;
  }

  /*---------------------------------------------------------------------------*/
  // Select Value from ValueList
  /*---------------------------------------------------------------------------*/
  Future<String> _selectValue(BuildContext context, String title,
      List<Parameter> valueList, String currentValue) async {
    String selectedValue;
    if (valueList.length == 0) {
      valueList.add(Parameter(currentValue, currentValue));
    }

    await showGeneralDialog(
      context: context,
      pageBuilder: (BuildContext ctxt, Animation<double> animation,
          Animation<double> secondaryAnimation) {
        return Material(
          child: Column(
            children: <Widget>[
              Container(
                height: 70,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  border: Border(
                    top: BorderSide(color: Colors.grey, width: 1.0),
                    bottom: BorderSide(color: Colors.grey, width: 1.0),
                  ),
                ),
              ),
              for (Parameter entry in valueList)
                SimpleDialogOption(
                  onPressed: () {
                    Navigator.pop(context, entry.key);
                  },
                  child: Column(children: <Widget>[
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      mainAxisSize: MainAxisSize.max,
                      children: <Widget>[
                        Expanded(
                          child: Text(entry.key),
                        ),
                        SizedBox(height: 45),
                        Expanded(
                          child: Text(entry.val),
                        ),
                        Expanded(
                          child: entry.key == currentValue
                              ? Icon(
                                  Icons.check,
                                  color: Colors.green,
                                )
                              : Text(""),
                        ),
                      ],
                    ),
                    Divider(
                      color: Colors.grey,
                      height: 1.0,
                      thickness: 1.0,
                    ),
                  ]),
                ),
            ],
          ),
        );
      },
      barrierDismissible: false,
      barrierColor: Colors.black,
      barrierLabel: "???",
      transitionDuration: const Duration(milliseconds: 200),
    ).then((returnValue) {
      //print("selected value = " + returnValue);
      selectedValue = returnValue;
      return selectedValue;
    }).catchError(
      ((e) {
        print("got error: ${e.error}");
      }),
    );
    return selectedValue;
  }

  /*---------------------------------------------------------------------------*/
  // Foto zur Position hinzufügen
  /*---------------------------------------------------------------------------*/
  void _addPhoto(
      BuildContext context, 
      Delivery delivery, 
      DelvItem delvItem,
      {bool gallery: false}) async {
        
    if (delvItem.imgmax == null) delvItem.imgmax = 0;

    int lfd = delvItem.imgmax + 1;
    String lfdno = lfd.toString();
    String fileName =
        delivery.dlvno + '_' + delvItem.posnr + '_' + lfdno + '.png';

    File imageFile;

    if (gallery) {
      imageFile = await _getImage(ImageSource.gallery);
    } else {
      imageFile = await _getImage(ImageSource.camera);
    }

    if (imageFile != null) {
      // getting a directory path for saving
      final directory = await getApplicationDocumentsDirectory();
      final String path = directory.path;

      Images imgObj = new Images();
      imgObj.posnr = delvItem.posnr;
      imgObj.number = lfd;
      imgObj.fileName = '$path/$fileName';
      imgObj.changeKz = 'I';
      imgObj.comment = '';
      globals.changeData = true;

      String result = await _displayImages(context, imageFile, imgObj);
      if (result == 'OK') {
        final File newImage = await imageFile.copy('$path/$fileName');
        await imageFile.delete();
        delvItem.imgmax = lfd;
        delvItem.images = delvItem.images + 1;
        delivery.imageList.add(imgObj);
        /* T * E * S * T *
        final bytes = File('$path/$fileName').readAsBytesSync();
        String img64 = base64Encode(bytes);
        final decodedBytes = base64Decode(img64);
        var file = File('$path/$fileName');
        file.writeAsBytesSync(decodedBytes);
        */
      } else {
        await imageFile.delete();
      }
    } else {
      // Foto wurde nicht übernommen
    }
  }

  /*---------------------------------------------------------------------------*/
  // Vorhandene Bilder anzeigen + nachbearbeiten
  /*---------------------------------------------------------------------------*/
  void _displayGallery(
      BuildContext context, Delivery delivery, DelvItem delvItem) async {

    Map loopControl;
    int j = 0;
    int k = 0;
    File file;
    String fileName;
    String saveComment = '';

    void _buildMap() {
      loopControl = {};
      for (var i = 0; i < delivery.imageList.length; i++) {
        if (delivery.imageList[i].posnr == delvItem.posnr &&
            delivery.imageList[i].changeKz != 'D') {
          loopControl[j] = i;
          j++;
        }
      }
    }

    _buildMap();

    if (j == 0) {
      return;
    } else {
      j = j - 1;
    }

    while (true) {
      var i = loopControl[k];

      try {
        fileName = delivery.imageList[i].fileName;
        file = File(fileName);
      } catch (e) {
        print(e.text);
        file = null;
      }
      saveComment = delivery.imageList[i].comment;

      var result = await _displayImages(context, file, delivery.imageList[i],loop:true);

      if (result != 'dele') {
        if (delivery.imageList[i].comment != saveComment) {
          delivery.imageList[i].changeKz = 'U';
          globals.changeData = true;
        }
      }

      switch (result) {
        case 'prev':
          if (k > 0) k = k - 1;
          break;
        case 'forw':
          print("k: " + k.toString() + " j: " + j.toString());
          if (k < j) k = k + 1;
          break;
        case 'dele':
          try {
            await file.delete();
            delivery.imageList[i].changeKz = 'D';
            globals.changeData = true;
            delvItem.images = delvItem.images - 1;
            _buildMap();
            if (j == 0) {
              result = 'canc';
            } else {
              j = j - 1;
            }
            if (k > j) k = j;
          } catch (error) {
            print('>>> File error: $error');
          }
          break;
      }
      if (result == 'canc') break;
      if (result == 'done') break;
    }
  }

  /*---------------------------------------------------------------------------*/
  // Bild mit der Kamera schießen (oder aus der Gallerie holen)
  /*---------------------------------------------------------------------------*/
  Future<File> _getImage(ImageSource source) async {
    File image = await ImagePicker.pickImage(source: source);
    return image;
  }

  /*---------------------------------------------------------------------------*/
  // Aufrufen des Dialogs zum Bestätigen der Übernahme
  /*---------------------------------------------------------------------------*/
  Future<String> _displayImages(
      BuildContext context, File imgFile, Images imgObj,
      {bool loop: false}) {
    return showDialog(
        context: context,
        builder: (BuildContext context) {
          return FotoDialog(imgFile: imgFile, imgObj: imgObj, loop: loop);
        },);
  }
}

/*---------------------------------------------------------------------------*/
// Bild anzeigen
/*---------------------------------------------------------------------------*/
class FotoDialog extends StatefulWidget {

  FotoDialog({this.imgFile, this.imgObj, this.loop});
  File imgFile;
  bool loop;
  Images imgObj;

  @override
  _FotoDialogState createState() => new _FotoDialogState();
}

class _FotoDialogState extends State<FotoDialog> {
  File imgFile;
  Images imgObj;
  bool loop;
  Image image;

  TextEditingController _textFieldController = TextEditingController();

  @override
  void initState() {
    super.initState();
    imgFile = widget.imgFile;
    imgObj = widget.imgObj;
    loop   = widget.loop;
    image  = Image(image: FileImage(widget.imgFile));
    imgObj.comment == null
        ? _textFieldController.text = ''
        : _textFieldController.text = imgObj.comment;
  }

  /*---------------------------------------------------------------------------*/
  // Bild anzeigen + Kommentar erfassen
  /*---------------------------------------------------------------------------*/
  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      actions: loop
          ? <Widget>[
              new IconButton(
                  icon: new Icon(Icons.skip_previous),
                  onPressed: () {
                    imgObj.comment = _textFieldController.text;
                    Navigator.of(context).pop('prev');
                  }),
              new IconButton(
                  icon: new Icon(Icons.skip_next),
                  onPressed: () {
                    imgObj.comment = _textFieldController.text;
                    Navigator.of(context).pop('forw');
                  }),
              new IconButton(
                  icon: new Icon(Icons.delete),
                  onPressed: () => Navigator.of(context).pop('dele')),
              new IconButton(
                  //icon: new Icon(Icons.cancel),
                  icon: new Icon(Icons.done),
                  onPressed: () {
                    imgObj.comment = _textFieldController.text;
                    Navigator.of(context).pop('canc');
                  }),
            ]
          : <Widget>[
              new FlatButton(
                child: new Text(H.getText(context, 'take')),
                color: globals.primaryColor,
                textColor: Colors.white,
                shape: new RoundedRectangleBorder(
                    borderRadius: new BorderRadius.circular(5.0)),
                onPressed: () {
                  setState(() {
                    imgObj.comment = _textFieldController.text;
                    Navigator.of(context).pop('OK');
                  });
                },
              ),
              new FlatButton(
                child: new Text(H.getText(context, 'disc')),
                color: globals.primaryColor,
                textColor: Colors.white,
                shape: new RoundedRectangleBorder(
                    borderRadius: new BorderRadius.circular(5.0)),
                onPressed: () {
                  imgObj.comment = _textFieldController.text;
                  Navigator.of(context).pop(' ');
                },
              )
            ],
      content: new SingleChildScrollView(
        child: Expanded(
            child: new Column(
          children: <Widget>[
            Container(child: image != null ? image : null),
            Padding(
              padding: EdgeInsets.all(8.0),
            ),
            Container(
                child: TextField(
              //autofocus: true,
              minLines: 2,
              maxLines: 4,
              controller: _textFieldController,
              decoration: InputDecoration(
                labelText: H.getText(context, 'comment'),
                labelStyle: TextStyle(color: globals.primaryColor),
                border: OutlineInputBorder(),
                focusedBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: globals.primaryColor),
                ),
              ),
            ))
          ],
        )),
      ),
    );
  }
}
