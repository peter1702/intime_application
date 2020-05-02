import 'package:flutter/material.dart';

import '../models/tour.dart';
import '../helpers/helpers.dart';
import '../globals.dart' as globals;

class LeergutPage extends StatefulWidget {
  LeergutPage(
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
  _LeergutPageState createState() => new _LeergutPageState();
}

class _LeergutPageState extends State<LeergutPage> {
  final GlobalKey<ScaffoldState> _scaffoldKey = new GlobalKey<ScaffoldState>();

  Delivery delivery;
  Tour tourData;
  int currentTabIndex = 0;
  bool readonly;

  _initializeData() {
    //tourData = Tour.getBuffer(widget.routno, widget.drivno);
    tourData = widget.tourData;
    delivery = tourData.delvList[widget.dlvIndex];
    if (delivery.lgutList == null) {
      delivery.lgutList = [];
    }
    readonly = widget.readonly;
    globals.changeData = false;
  }
  Future<bool> _exitApp(BuildContext context) {
    print("Exit App -> data changed: "+globals.changeData.toString());
    if (readonly == false && globals.changeData == true) {
      Tour.saveDelivery(tourData,widget.dlvIndex) ; 
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
      /* ---------- appBar ----------------------------------------------------------*/
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
                    ? H.getText(context, 'empties') +
                      " - " +
                      H.getText(context, 'disp')
                    : H.getText(context, 'empties') +
                      " - " +
                      H.getText(context, 'proc'),
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
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final AddLeergut addLeergut = new AddLeergut(context: context);
          List<Leergut> lgutList =
              await addLeergut.appendLeergut(delivery.lgutList, readonly:readonly);
          setState(() {
            if (lgutList == null) print("LeergutListe = null");
            if (lgutList != null) {
              delivery.lgutList = List.from(lgutList);
            }
          });
        },
        backgroundColor: globals.actionColor,
        child: Icon(Icons.add),
      ),
      body: delivery.lgutList.length == 0
        ? BuildWelcomeScreen(
          delivery: delivery,
          routno: widget.routno,
          drivno: widget.drivno,
          dlvIndex: widget.dlvIndex,
          readonly: readonly)
        : BuildEmptiesList(
          delivery: delivery,
          routno: widget.routno,
          drivno: widget.drivno,
          dlvIndex: widget.dlvIndex,
          readonly: readonly),
    ));
  }
}

/*---------------------------------------------------------------------------*/
// Select new empties to return
/*---------------------------------------------------------------------------*/
class AddLeergut {
  AddLeergut({this.context});
  BuildContext context;

  Future<List<Leergut>> appendLeergut(List<Leergut> currentLeergutList, 
                                      {bool readonly: true}) async {
    TextEditingController searchController = TextEditingController();

    List<StandardLeergut> itemsAll;
    List<StandardLeergut> items;
    List<Leergut> returnLeergutList = [];
    itemsAll = await StandardLeergut.getLeergut();
    if (itemsAll == null || itemsAll == []) {
      return currentLeergutList;
    }
    print("Leergut..."+itemsAll.length.toString());

    items = itemsAll;
    searchController.clear;

    //Build maps
    Map itemsSel = {for (var v in itemsAll) v.matnr: ' '};
    Map itemsExcl = {};
    currentLeergutList.forEach((element) {
      String key = element.matnr;
      itemsSel[key] = 'X';
      if (element.menge > 0) {
        itemsExcl[key] = 'X';
        returnLeergutList.add(element);
      }
    });

    void _buildReturnList() {
      for (var stdItem in itemsAll) {
        if (itemsSel[stdItem.matnr] == 'X') {
          if (itemsExcl[stdItem.matnr] == null ||
              itemsExcl[stdItem.matnr] != 'X') {
            Leergut lgut = new Leergut();
            lgut.matnr = stdItem.matnr;
            lgut.maktx = stdItem.maktx;
            lgut.abmes = stdItem.abmes;
            lgut.meins = stdItem.meins;
            lgut.menge = 0;
            lgut.changeKz = 'I';
            globals.changeData = true;
            returnLeergutList.add(lgut);
          }
        }
      }
    }

    void _itemChange(bool val, int index) {
      if (itemsExcl[items[index].matnr] != 'X' && readonly == false) {
        if (val) {
          itemsSel[items[index].matnr] = 'X';
        } else {
          itemsSel[items[index].matnr] = ' ';
        }
      }
    }

    void _selectAll() {
      itemsSel.forEach((key, val) {
        if (itemsExcl[key] == null || itemsExcl[key] != 'X') {
          itemsSel[key] = 'X';
        }
      });
    }

    void _deSelectAll() {
      itemsSel.forEach((key, val) {
        if (itemsExcl[key] == null || itemsExcl[key] != 'X') {
          itemsSel[key] = ' ';
        }
      });
    }

    // --- BottomNavigation
    void _onTabTapped(int index) {
      switch (index) {
        case 0:
          Navigator.pop(context, true);
          break;
        case 1:
          if (readonly == false)
            _selectAll();
          break;
        case 2:
          if (readonly == false)
            _deSelectAll();
          break;
      }
    }

    await showGeneralDialog(
      context: context,
      pageBuilder: (BuildContext ctxt, Animation<double> animation,
          Animation<double> secondaryAnimation) {
        return StatefulBuilder(
            builder: (BuildContext ctxt, StateSetter setState) {
          return Scaffold(
            bottomNavigationBar: BottomNavigationBar(
              onTap: (index) {
                setState(() {
                  _onTabTapped(index);
                });
              },
              //currentIndex: 0, // this will be set when a new tab is tapped
              items: [
                BottomNavigationBarItem(
                  icon: new Icon(Icons.exit_to_app),
                  title: new Text(H.getText(context, "take")),
                ),
                BottomNavigationBarItem(
                  icon: new Icon(Icons.format_list_bulleted), //select_all
                  title: new Text(H.getText(context, "asel")),
                ),
                BottomNavigationBarItem(
                  icon: new Icon(Icons.select_all),
                  title: new Text(H.getText(context, "usel")),
                )
              ],
            ),
            body: Column(children: <Widget>[
              Container(
                height: 80,
                alignment: AlignmentDirectional.bottomStart,
                margin: EdgeInsets.all(10),
                child: TextField(
                  controller: searchController,
                  //autofocus: true,
                  onChanged: (value) {
                    setState(() {
                      items = _filterSearchResults(value, itemsAll);
                    });
                  },
                  decoration: InputDecoration(
                    labelText: H.getText(context, "search"),
                    hintText: H.getText(context, "search"),
                    prefixIcon: Icon(Icons.search),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.all(
                        Radius.circular(15.0),
                      ),
                    ),
                  ),
                ),
              ),
              Expanded(
                child: items.length == 0
                    ? Container()
                    : ListView.builder(
                        shrinkWrap: true,
                        itemCount: items.length,
                        itemBuilder: (context, index) {
                          return new CheckboxListTile(
                              activeColor: (itemsExcl[items[index].matnr] == 'X' || readonly )
                                ? Colors.grey
                                : globals.primaryColor,
                              value: (itemsSel[items[index].matnr] == 'X'),
                              title: Text(items[index].maktx),
                              subtitle: items[index].abmes != ''
                              ? Text(items[index].abmes)
                              : Text(items[index].matnr),
                              selected: itemsSel[items[index].matnr] == 'X',
                              controlAffinity: ListTileControlAffinity.leading,
                              onChanged: (bool val) {
                                setState(() {
                                  _itemChange(val, index);
                                });
                              });
                        },
                      ),
              )
            ]),
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
    if (readonly) {
      return currentLeergutList;
    } else {
      _buildReturnList();
     return returnLeergutList;
    }
  }

  // --- Search
  List<StandardLeergut> _filterSearchResults(
      String query, List<StandardLeergut> itemsAll) {
    List<StandardLeergut> itemsSearch = [];
    if (query.isNotEmpty) {
      itemsAll.forEach((item) {
        if (item.maktx.toLowerCase().contains(query.toLowerCase())) {
          itemsSearch.add(item);
        }
      });
      return itemsSearch;
    } else {
      return itemsAll;
    }
  }
}
/*---------------------------------------------------------------------------*/
// Screen bei leerer Liste
/*---------------------------------------------------------------------------*/
class BuildWelcomeScreen extends StatelessWidget {
  
  BuildWelcomeScreen({this.delivery, this.routno, this.drivno, this.dlvIndex,
                    this.readonly: true});
  
  Delivery delivery;

  final String routno;
  final String drivno;
  final int dlvIndex;
  final bool readonly;

  @override
  Widget build(BuildContext context) {
    return StatefulBuilder(builder: (BuildContext ctxt, StateSetter setState) {

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
                        child: Text(H.getText(context, 'empties'),
                          style: globals.styleTextBigBold,
                        )),
                    //
                    Container(
                        height: 35,
                        alignment: Alignment.topLeft,
                        child: readonly
                          ? Text(H.getText(context, 'leerg_no'), 
                            style: globals.styleTextNormal)
                          : Text(H.getText(context, 'leerg_add'),
                            style: globals.styleTextNormal),
                        ),
                  ]),
                ),
            ),
          ])
      );
    });
  }
}

/*---------------------------------------------------------------------------*/
// Liste zum Erfassen des Leerguts
/*---------------------------------------------------------------------------*/
class BuildEmptiesList extends StatelessWidget {
  
  BuildEmptiesList({this.delivery, this.routno, this.drivno, this.dlvIndex,
                    this.readonly: true});
  
  Delivery delivery;

  final String routno;
  final String drivno;
  final int dlvIndex;
  final bool readonly;

  @override
  Widget build(BuildContext context) {
    return StatefulBuilder(builder: (BuildContext ctxt, StateSetter setState) {
      return (delivery.lgutList.length == 0)
          ? Container()
          : ListView.builder(
              itemCount: delivery.lgutList.length,
              itemBuilder: (context, index) {
                return Card(
                  elevation: 5,
                  child: Column(children: <Widget>[
                    //margin: EdgeInsets.fromLTRB(0.0, 10.0, 0.0, 10.0),
                    Row(children: <Widget>[
                      Expanded(
                        flex: 2,
                        child: Column(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            mainAxisAlignment: MainAxisAlignment.start,
                            children: <Widget>[
                              Container(),
                            ]),
                      ),
                      SizedBox(height: 55),
                      Expanded(
                        flex: 6,
                        child: Column(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            mainAxisAlignment: MainAxisAlignment.start,
                            children: <Widget>[
                              // Materialbezeichnung 
                              Container(
                                alignment: Alignment.topLeft,
                                padding: EdgeInsets.only(top: 5.0),
                                child: Text(delivery.lgutList[index].maktx,
                                    style: globals.styleTextBigBold),
                              ),
                              // Abmessungen oder Material-Nummer
                              Container(
                                alignment: Alignment.topLeft,
                                padding: EdgeInsets.only(top: 5.0),
                                child: delivery.lgutList[index].abmes != ''
                                ? Text(delivery.lgutList[index].abmes,
                                    style: globals.styleTableTextNormal)
                                : Text(delivery.lgutList[index].matnr,
                                    style: globals.styleTableTextNormal),
                              ),
                            ]),
                      ),
                      Expanded(
                        flex: 2,
                        child: Column(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            mainAxisAlignment: MainAxisAlignment.start,
                            children: <Widget>[
                              Container(),
                            ]),
                      ),
                    ]),

                    Row(children: <Widget>[
                      Expanded(
                        flex: 2,
                        child: Column(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: <Widget>[
                              Container(
                                child: GestureDetector(
                                    child: Container(
                                      alignment: Alignment.center,
                                      child: Icon(Icons.remove_circle,
                                          size: 32,
                                          color: readonly
                                          ? Colors.grey
                                          : globals.primaryColor),
                                    ),
                                    onTap: () {
                                      setState(() {
                                        if (readonly == false) {
                                          if (delivery.lgutList[index].menge > 0) {
                                            delivery.lgutList[index].menge--;
                                            globals.changeData = true;
                                            if (delivery.lgutList[index].changeKz == '')
                                              delivery.lgutList[index].changeKz = 'U';
                                          }
                                        }
                                      });
                                    }),
                              ),
                            ]),
                      ),
                      SizedBox(height: 55),
                      Expanded(
                        flex: 6,
                        child: Column(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            mainAxisAlignment: MainAxisAlignment.start,
                            children: <Widget>[
                              // Menge
                              Container(
                                alignment: Alignment.center,
                                child: Text(
                                    delivery.lgutList[index].menge
                                        .toStringAsFixed(0),
                                    style: TextStyle(
                                        fontSize: 32,
                                        fontWeight: FontWeight.bold)),
                              ),
                            ]),
                      ),
                      Expanded(
                        flex: 2,
                        child: Column(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: <Widget>[
                              Container(
                                child: GestureDetector(
                                    child: Container(
                                      alignment: Alignment.center,
                                      child: Icon(Icons.add_circle,
                                          size: 32,
                                          color: readonly
                                          ? Colors.grey
                                          : globals.primaryColor),
                                    ),
                                    onTap: () {
                                      setState(() {
                                        if (readonly == false) {
                                          delivery.lgutList[index].menge++;
                                          globals.changeData = true;
                                          if (delivery.lgutList[index].changeKz == '')
                                            delivery.lgutList[index].changeKz = 'U';
                                        }
                                      });
                                    }),
                              ),
                            ]),
                      ),
                    ]),
                  ]),
                );
              });
    });
  }
}
