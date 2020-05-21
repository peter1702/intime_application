import 'package:flutter/material.dart';
import 'package:page_view_indicator/page_view_indicator.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'dart:convert';
import 'dart:async';
import '../Helpers/helpers.dart';
import '../globals.dart' as globals;
import '../models/menu.dart';
import '../views/template.dart';
import '../views/stock_entry.dart';

class MenuPage extends StatefulWidget {
  final String title; //Access with widget.title
  final String menue; //Access with widget.menue

  MenuPage({Key key, @required this.title, @required this.menue})
      : super(key: key);

  @override
  _MenuPageState createState() => _MenuPageState();
}

class _MenuPageState extends State<MenuPage> {
  final int maxTilesPerPage = 6;
  int maxPages = 3;
  int maxItems = 6;

  final GlobalKey<ScaffoldState> _scaffoldKey = new GlobalKey<ScaffoldState>();

  PageController controller = PageController();
  static const _kDuration = const Duration(milliseconds: 300);
  static const _kCurve = Curves.ease;
  var currentPageValue = 0.0;
  final pageIndexNotifier = ValueNotifier<int>(0);

  List<Menu> listMenu = [];
  List<Menu> pageMenu = [];
  var loading = false;
  String thisMenu;

  Future<String> _getFileData(String path) async {
    return await rootBundle.loadString(path);
  }

  Future<Null> _getMenuData() async {
    setState(() {
      loading = true;
      thisMenu = widget.menue;
    });
    //Load JSON data
    final String rawData = await _getFileData("resources/data/menu_data.json");
    final data = jsonDecode(rawData);
    setState(() {
      for (Map i in data) {
        listMenu.add(Menu.fromJson(i));
      }
      loading = false;
      _loadNextPage(0);
      _getPageCount();
    });
    // Pagecontroller
    controller.addListener(() {
      setState(() {
        currentPageValue = controller.page;
      });
    });
  }

  // Initialzation
  @override
  void initState() {
    super.initState();
    _getMenuData();
  }

  Future<bool> _exitApp(BuildContext context) async {
    String title =  H.getText(context, "leave");
    String content =  H.getText(context, "M033");
    String answer = await H.confirmDialog(context, title, content);
    if (answer == 'Y') {
      Navigator.pop(context, true);
    }
  }

  @override
  Widget build(BuildContext context) {
    //Berechnung, so dass 6 Tiles genau auf den Screen passen
    //abzgl. 130 für AppBar und PageViewIndicator
    var size = MediaQuery.of(context).size;

    return new WillPopScope(
      onWillPop: () => _exitApp(context),
      child: new Scaffold(
        key: _scaffoldKey,

      appBar: AppBar(
        iconTheme: IconThemeData(
          color: Colors.blue,
        ),
        //title: Text(AppLocalizations.of(context).translate('menu_title'),
        /*
        title: Text(widget.title, style: TextStyle(color: Colors.blue)),
        centerTitle: true,
        */
        title: Row(
          mainAxisAlignment: MainAxisAlignment.start,
          children: <Widget>[
            Image.asset(
              'lib/images/logo.png',
              fit: BoxFit.cover,
              height: 50.0,
            ),
            Padding(padding: EdgeInsets.only(left: 20.0)),
          ],
        ),

        backgroundColor: Colors.white,

        leading: new IconButton(
            icon: new Icon(Icons.arrow_back_ios, color: globals.primaryColor),
            onPressed: () {
              _exitApp(context);
            }),

        actions: <Widget>[
          new IconButton(
              icon: new Icon(Icons.more_vert, color: globals.primaryColor),
              onPressed: () {
                print("Button MORE pressed"); // handle onTap
              })
        ],
      ),
      
      body: Stack(alignment: FractionalOffset.bottomCenter, children: <Widget>[
        PageView.builder(
            controller: controller,
            pageSnapping: true,
            onPageChanged: (index) {
              pageIndexNotifier.value = index;
              _loadNextPage(index);
            },
            itemCount: maxPages,
            itemBuilder: (context, index) {
              return Container(
                  decoration: BoxDecoration(color: Colors.white),
                  child: OrientationBuilder(builder: (context, orientation) {
                    return GridView.count(
                      primary: false,
                      padding: const EdgeInsets.only(top: 4),
                      crossAxisSpacing: 4,
                      mainAxisSpacing: 4,
                      crossAxisCount:
                          orientation == Orientation.portrait ? 2 : 3,
                      //crossAxisCount: 2,
                      //genaues Einpassen der Tiles
                      childAspectRatio: 
                          orientation == Orientation.portrait 
                            ? ((size.width / 2) / ((size.height - 130) / 3))
                            : ((size.width / 3) / ((size.height - 130) / 2)),
                      children: List.generate(maxItems, (ix) {
                        var j = ix;
                        if (j < pageMenu.length) {
                          return _makeTile(
                              context,
                              pageMenu[j].title,
                              pageMenu[j].mtype,
                              globals.myIcons[pageMenu[j].icon],
                              pageMenu[j].action);
                        } else {
                          return Container();
                        }
                      }),
                    );
                  },),
              );
            }),

        //PageViewIndicator

        Stack(
          alignment: AlignmentDirectional.bottomCenter,  //.topStart,
          children: <Widget>[
            Container(
              margin: EdgeInsets.only(bottom: 8),
              child:
              _buildPageViewIndicator(),
            ),
            Container(
              //margin: EdgeInsets.only(bottom: 35),
              child: Row(
                //mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: <Widget>[
                  new IconButton(icon: new Icon(Icons.keyboard_arrow_left, color:globals.primaryColor), 
                      onPressed: () { controller.previousPage(duration: _kDuration, curve: _kCurve);} ),
                  new IconButton(icon: new Icon(Icons.keyboard_arrow_right, color:globals.primaryColor), 
                      onPressed: () { controller.nextPage(duration: _kDuration, curve: _kCurve); } ),
              ]),
            ),
          ]),

      ]),
    ));
  }

  PageViewIndicator _buildPageViewIndicator() {
    return PageViewIndicator(
      pageIndexNotifier: pageIndexNotifier,
      length: maxPages,
      normalBuilder: (animationController, index) => Circle(
        size: 8.0,
        color: globals.primaryColor,
      ),
      highlightedBuilder: (animationController, index) => ScaleTransition(
        scale: CurvedAnimation(
          parent: animationController,
          curve: Curves.ease,
        ),
        child: Circle(
          size: 12.0,
          color: globals.primaryColor,
        ),
      ),
    );
  }

  void _loadNextPage(int index) {
    pageMenu.clear();
    for (var i = 0; i < listMenu.length; i++) {
      int ix = index + 1;
      if (listMenu[i].page == ix.toString()) {
        pageMenu.add(listMenu[i]);
      }
    }
    maxItems = maxTilesPerPage;
    if (maxItems > pageMenu.length) {
      maxItems = pageMenu.length;
    }
  }

  void _getPageCount() {
    String lastPage;
    maxPages = 0;
    for (var i = 0; i < listMenu.length; i++) {
      if (listMenu[i].page != lastPage && listMenu[i].page != "") {
        maxPages++;
        lastPage = listMenu[i].page;
      }
    }
  }
}

Widget _makeTile(BuildContext context, pTitle, pType, pIcon, pAction) {
  if (pIcon == "") {
    pIcon = Icons.launch;
  }
  return InkWell(
      child: Container(
        padding: const EdgeInsets.all(8),
        color: globals.primaryColor,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: <Widget>[
            Icon(
              pIcon,
              color: Colors.white,
              size: 64,
            ),
            Text(pTitle,
                maxLines: 1,
                style: TextStyle(color: Colors.white, fontSize: 18)),
            //Text(pType,
            //    maxLines: 1,
            //    style: TextStyle(color: Colors.white60, fontSize: 14)),
          ],
        ),
      ),
      onTap: () {
        _doSomeAction(context, pAction);
      } // handle onTap
      );
}

void _doSomeAction(BuildContext context, pAction) {
  print(pAction);
  switch (pAction) {
    case 'KOMM': 
      Navigator.push(context, MaterialPageRoute(builder: (context) => TemplatePage()));
      break;
    case 'STOCK':
      Navigator.push(context, MaterialPageRoute(builder: (context) => StockEntryPage()));
      break;
  }
}
