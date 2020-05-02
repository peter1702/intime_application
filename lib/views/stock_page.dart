//DataTables: https://www.coderzheaven.com/2019/01/24/flutter-tutorials-datatable-android-ios/

import 'package:flutter/material.dart';
import 'package:searchable_dropdown/searchable_dropdown.dart';
import '../helpers/helpers.dart';
import '../globals.dart' as globals;
import '../models/stock.dart';
import '../models/units.dart';

class StockPage extends StatefulWidget {
  StockPage({Key key, this.title}) : super(key: key);
  final String title;

  @override
  _StockPageState createState() => new _StockPageState();
}

class _StockPageState extends State<StockPage> {
  final GlobalKey<ScaffoldState> _scaffoldKey = new GlobalKey<ScaffoldState>();

  List<Stock> stock;
  List<Units> units;
  StockData stockData;
  String lastLgort = "";
  bool _newLgort = false;
  bool _lastItem = false;
  String currMeasureOfUnit;
  String baseMeasureOfUnit;
  String errorMessage;

  final List<DropdownMenuItem> unitsValues = [];
  Map<String, String> unitsMap = {};

  _initializeData() {
    setState(() {
      stockData = StockData.getBuffer();
      currMeasureOfUnit = baseMeasureOfUnit = stockData.meins;
      stock = stockData.stockList;
      stock.sort((a, b) => a.lgort.compareTo(b.lgort));
      units = Units.getUnits();
      for (Units entry in units) {
        //Build the Dropdownlist
        unitsValues.add(DropdownMenuItem(
          child: Text(entry.meins + " " + entry.bezei),
          value: entry.meins,
        ));
        //Build the Map
        unitsMap[entry.meins] = entry.bezei;
      }
    });
  }

  // Initialzation
  @override
  void initState() {
    _initializeData();
    super.initState();
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
            //automaticallyImplyLeading: false, // => Don't show the leading button
            title: RichText(
              text: TextSpan(children: [
                TextSpan(
                    text: H.getText(context, 'stock_title'),
                    style: globals.styleHeaderTitle),
                TextSpan(text: "\n"),
                TextSpan(
                  text: H.getText(context, 'material') + " " + stockData.matnr,
                  style: globals.styleHeaderSubTitle,
                )
              ]),
            ),
          ),
        ),

        /*---------- body ----------------------------------------------------------------*/
        body: Container(
          margin: EdgeInsets.fromLTRB(17.0, 10.0, 17.0, 10.0),
          color: Colors.white,
          child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              verticalDirection: VerticalDirection.down,
              children: <Widget>[
                // Materialbezeichnung 
                Row(
                  children: <Widget>[
                    SizedBox(height: globals.heightRow),
                    Expanded(
                      flex: 3,
                      child: Text(
                        H.getText(context, 'description'),
                        style: globals.styleLabelDisplay,
                      ),
                    ),
                    Expanded(
                      flex: 7,
                      child: Text(stockData.maktx,
                          textAlign: TextAlign.right,
                          style: globals.styleDisplayField),
                    ),
                  ],
                ),
                // Trenner 
                Divider(height: 1, thickness: 0.5, color: Colors.grey),
                // Mengeneinheit
                Row(
                  children: <Widget>[
                    SizedBox(height: globals.heightRow),
                    Expanded(
                      flex: 4,
                      child: Text(
                        H.getText(context, 'unitOfMeasure'),
                        style: globals.styleLabelDisplay,
                      ),
                    ),
                    Expanded(
                      flex: 6,
                      child: Row(
                        children: <Widget>[
                          Spacer(),
                          Text(
                            currMeasureOfUnit,
                            textAlign: TextAlign.right,
                            style: globals.styleDisplayField,
                          ),
                          /*
                    SearchableDropdown.single(
                      items: meinsValues,
                      value: currMeasureOfUnit,
                      hint: "Select one",
                      searchHint: "Select Measure Of Unit",
                      onChanged: (value) {
                        setState(() {
                          currMeasureOfUnit = value;
                        });
                      },
                      isExpanded: false,
                      displayClearIcon: false,
                    ),
                    */
                          // Icon für Selektion rechtsbündig platzieren
                          SizedBox(
                            width: 25,
                            child: IconButton(
                              icon: Icon(Icons.arrow_drop_down),
                              onPressed: () {
                                _selectUnits(context, currMeasureOfUnit);
                              },
                            ),
                          ),
                          //
                        ],
                      ),
                    ),
                  ],
                ),
                // Trenner 
                Divider(height: 10, thickness: 0.5, color: Colors.grey),
                // Table Header
                Container(
                  color: Colors.grey[100],
                  // Überschriften
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: <Widget>[
                      // Lagerort
                      SizedBox(
                        width: 70,
                        height: globals.tableCellHeight,
                        child: Text(H.getText(context, 'storageLocation'),
                            maxLines: 1, style: globals.styleTableTextHeader),
                      ),
                      // SizedBox für Zeilenhöhe (nicht am Anfang!)
                      SizedBox(height: globals.heightRow),
                      // Charge 
                      SizedBox(
                        width: 90,
                        height: globals.tableCellHeight,
                        child: Text(H.getText(context, 'batch'),
                            textAlign: TextAlign.left,
                            style: globals.styleTableTextHeader),
                      ),
                      // Bestand 
                      SizedBox(
                        width: 130,
                        height: globals.tableCellHeight,
                        child: Text(H.getText(context, 'stock'),
                            textAlign: TextAlign.right,
                            style: globals.styleTableTextHeader),
                      ),
                    ],
                  ),
                ),
                // Trenner 
                Divider(height: 10, thickness: 0.5, color: Colors.grey),
                // Table Columns
                Expanded(
                  child: SingleChildScrollView(
                    scrollDirection: Axis.vertical,
                    child: SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          for (Stock entry in stock)
                            Column(
                              children: <Widget>[
                                Row(
                                  // damit Menge rechtsbündig erscheint - "spaceBetween"
                                  mainAxisAlignment:MainAxisAlignment.spaceBetween,
                                  children: <Widget>[
                                    // Lagerort
                                    SizedBox(
                                      width: 70,
                                      height: globals.tableCellHeight,
                                      child: Text(
                                          _lgortChanged(stock.indexOf(entry))
                                              ? entry.lgort
                                              : "",
                                          maxLines: 1,
                                          style:
                                              globals.styleTableTextHighlight),
                                    ),
                                    // Charge 
                                    SizedBox(
                                      width: 90,
                                      height: globals.tableCellHeight,
                                      child: Text(
                                        entry.charg,
                                        style: globals.styleTableTextNormal,
                                      ),
                                    ),
                                    // SizedBox für Zeilenhöhe 
                                    SizedBox(height: globals.heightRow),
                                    // Bestand mit Mengeneinheit 
                                    SizedBox(
                                      height: globals.tableCellHeight,
                                      width: 130,
                                      child: Text(
                                          // Dezimalstellen formatieren 
                                          Units.convertUnit2String(
                                                  currMeasureOfUnit,
                                                  baseMeasureOfUnit,
                                                  entry.menge) +
                                              " " +
                                              currMeasureOfUnit,
                                          textAlign: TextAlign.right,
                                          maxLines: 1,
                                          style: globals.styleTableTextNormal),
                                    ),
                                  ],
                                ),
                                // Trenner (blau) nach Wechsel des Lagerorts
                                _newLgort || _lastItem
                                    ? Divider(
                                        height: 2,
                                        thickness: 1.5,
                                        color: globals.primaryColor)
                                    : Divider(
                                        height: 1,
                                        thickness: 0.5,
                                        color: Colors.grey),
                              ],
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
              ]),
        ));
  }

  /*---------------------------------------------------------------------------*/
  // Check if LGORT was changed in list
  /*---------------------------------------------------------------------------*/
  bool _lgortChanged(int index) {
    bool changed = false;
    bool nextChg = false;
    bool lastItm = false;
    if (stock[index].lgort != lastLgort) {
      changed = true;
    } else {
      changed = false;
    }
    if (index < stock.length - 1) {
      if (stock[index + 1].lgort != stock[index].lgort) {
        nextChg = true;
      }
    } else {
      lastItm = true;
    }
    setState(() {
      lastLgort = stock[index].lgort;
      _newLgort = nextChg;
      _lastItem = lastItm;
    });
    return changed;
  }

  /*---------------------------------------------------------------------------*/
  // Show Message
  /*---------------------------------------------------------------------------*/
  void _showMessage(String message, [MaterialColor color = Colors.red]) {
    _scaffoldKey.currentState.showSnackBar(
        new SnackBar(backgroundColor: color, content: new Text(message)));
  }

  /*---------------------------------------------------------------------------*/
  // Select Unit
  /*---------------------------------------------------------------------------*/
  void _selectUnits(BuildContext context, String pUnit) {
    String selectTitle = H.getText(context, 'unitOfMeasure');
    String selectValue = pUnit;
    Map<String, String> valueMap = unitsMap;

    List<Parameter> valueList = [];
    valueMap.forEach((k, v) => valueList.add(Parameter(k, v)));

    showGeneralDialog(
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
                          child: entry.key == selectValue
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
    ).then((value) {
      //print("selected value = " + value);
      setState(() {
        if (value != "") currMeasureOfUnit = value;
      });
      return value;
    }).catchError(
      ((e) {
        print("got error: ${e.error}");
      }),
    );
  }
}
