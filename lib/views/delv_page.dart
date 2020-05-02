import 'package:flutter/material.dart';

import '../models/tour.dart';
import '../helpers/helpers.dart';
import '../globals.dart' as globals;

import '../views/delv_cust.dart';  // Kunden-Info
import '../views/delv_leer.dart';  // Leergut 
import '../views/delv_item.dart';  // Vollgut 
import '../views/bill_page.dart';  // Abrechnung
import '../views/cash_page.dart';  // Inkasso, Barzahlung

class DeliveryPage extends StatefulWidget {
  DeliveryPage(
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
  _DeliveryPageState createState() => new _DeliveryPageState();
}

class _DeliveryPageState extends State<DeliveryPage>
    with SingleTickerProviderStateMixin {
  final GlobalKey<ScaffoldState> _scaffoldKey = new GlobalKey<ScaffoldState>();

  VoidCallback onChanged;

  Delivery delivery;
  Tour tourData;
  TabController tabController;
  int currentTabIndex = 0;
  int dlvIndex;
  bool readonly;

  _initializeData() {
    //tourData = Tour.getBuffer(widget.routno, widget.drivno);
    tourData = widget.tourData;
    delivery = tourData.delvList[widget.dlvIndex];
    dlvIndex = widget.dlvIndex;
    if (delivery.lgutList == null) {
      delivery.lgutList = [];
    }
    readonly = widget.readonly;
    globals.changeData = false;
  }

  // Initialization
  @override
  void initState() {
    super.initState();
    _initializeData();
    tabController = new TabController(initialIndex: 0, length: 4, vsync: this);
    onChanged = () {
      setState(() {
        currentTabIndex = this.tabController.index;
      });
    };
    tabController.addListener(onChanged);
  }
  Future<bool> _exitApp(BuildContext context) {
    print("Exit App -> data changed: " + globals.changeData.toString());
    if (readonly == false && globals.changeData == true) {
      Tour.saveDelivery(tourData, widget.dlvIndex);
      globals.changeData = false;
    }
    Navigator.pop(context, true);
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
                  ? H.getText(context, 'delv_display')
                  : H.getText(context, 'delv_process'),
                  style: globals.styleHeaderTitle),
              TextSpan(text: "\n"),
              TextSpan(
                text: delivery.dlvno,
                style: globals.styleHeaderSubTitle,
              )
            ]),
          ),
        ),
      ),
      /*---------- body ----------------------------------------------------------------*/
      body:
          //DefaultTabController(length: 4,
          //child:
          Scaffold(
        appBar: AppBar(
          automaticallyImplyLeading: false,
          backgroundColor: Colors.white,
          bottom: new PreferredSize(
              preferredSize: new Size(double.infinity, 75.0),
              child: Column(
                children: <Widget>[
                  Container(
                    color: Colors.grey[200],
                    height: 83, //preferredSize + 8
                    width: double.infinity,
                    alignment: Alignment.topLeft,
                    child: Padding(
                      padding: EdgeInsets.fromLTRB(17.0, 10.0, 17.0, 10.0),
                      child: Column(children: <Widget>[
                        Container(
                          padding: EdgeInsets.only(top: 0.0),
                          alignment: Alignment.topLeft,
                          child: Text(delivery.name1,
                              textAlign: TextAlign.left,
                              style: globals.styleTableTextNormal),
                        ),
                        Container(
                          padding: EdgeInsets.only(top: 3.0),
                          alignment: Alignment.topLeft,
                          child: Text(delivery.stras + " " + delivery.hausn,
                              textAlign: TextAlign.left,
                              style: globals.styleTableTextNormal),
                        ),
                        Container(
                          padding: EdgeInsets.only(top: 3.0),
                          alignment: Alignment.topLeft,
                          child: Text(delivery.pstlz + " " + delivery.ort01,
                              textAlign: TextAlign.left,
                              style: globals.styleTableTextNormal),
                        ),
                      ]),
                    ),
                  ),
                  TabBar(
                    isScrollable: true,
                    labelColor: globals.primaryColor,
                    labelStyle: globals.styleTableTextNormalBold,
                    controller: tabController,
                    indicatorColor: globals.primaryColor,
                    tabs: [
                      //Tab(icon: Icon(Icons.directions_car, color: globals.primaryColor)),
                      Tab(child: Text(H.getText(context,'filled'))),
                      Tab(child: Text(H.getText(context,'empties'))),
                      Tab(child: Text(H.getText(context,'customer'))),
                      Tab(child: Text(H.getText(context,'billing'))),
                    ],
                  ),
                ],
              )),
        ),
        floatingActionButton: 
            currentTabIndex == 1 // Leergut
            ? FloatingActionButton(
                onPressed: () async {
                  final AddLeergut addLeergut = new AddLeergut(context: context);
                  List<Leergut> lgutList =
                      await addLeergut.appendLeergut(delivery.lgutList, readonly:readonly);
                  setState(() {
                    if (lgutList == null) { 
                      print("LeergutListe = null");
                    }
                    if (lgutList != null) {
                      delivery.lgutList = List.from(lgutList);
                    }
                  });
                },
                backgroundColor: globals.actionColor,
                child: Icon(Icons.add),
              )
            : currentTabIndex == 3 // Abrechnung 
            ? FloatingActionButton(
                onPressed: () async {
                  _billDelivery(context);
                },
                backgroundColor: globals.actionColor,
                child: Icon(Icons.account_balance),
              )
            : currentTabIndex == 2 // Kunde -> Barzahlung, Kasse
              ? FloatingActionButton(
                onPressed: () async {
                  _displayInkasso(context);
                },
                backgroundColor: globals.actionColor,
                child: Icon(Icons.attach_money),
                )
              : Container(),
        body: TabBarView(
          controller: tabController,
          children: [
            // Vollgut
            BuildFilledList(
                delivery: delivery,
                routno: widget.routno,
                drivno: widget.drivno,
                dlvIndex: widget.dlvIndex,
                readonly: readonly),
            // Leergut
            delivery.lgutList.length == 0
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
            // Kundeninfo
            BuildAddress(
                tourData: tourData,
                delivery: delivery,
                routno: widget.routno,
                drivno: widget.drivno,
                dlvIndex: widget.dlvIndex, 
                readonly: readonly),
            // Abrechnung
            BuildBilling(
                tourData: tourData,
                delivery: delivery,
                routno: widget.routno,
                drivno: widget.drivno,
                dlvIndex: widget.dlvIndex, 
                readonly: readonly),   
          ],
        ),
      ),
      //),
    ));
  }

  /*-----------------------------------------------------------------------------------*/
  // -> Abrechnung 
  /*-----------------------------------------------------------------------------------*/
  void _billDelivery(BuildContext context) async {

    Navigator.push(context, 
        MaterialPageRoute(builder: (context) => BillingPage(
            tourData: tourData,
            routno: tourData.routno,
            drivno: tourData.drivno,
            dlvIndex: dlvIndex,
            readonly: readonly,
          ),
        ),
      );
  }
  /*-----------------------------------------------------------------------------------*/
  // -> Inkasso, Barzahlung 
  /*-----------------------------------------------------------------------------------*/
  void _displayInkasso(BuildContext context) async {

      Navigator.push(context, 
        MaterialPageRoute(builder: (context) => InkassoPage(
            tourData: tourData,
            routno: tourData.routno,
            drivno: tourData.drivno,
            dlvIndex: dlvIndex,
            readonly: readonly),
        ),
      );
  }
 
}
