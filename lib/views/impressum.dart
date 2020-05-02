import 'package:flutter/material.dart';
import '../helpers/helpers.dart';
import '../globals.dart' as globals;

class Impressum extends StatelessWidget {

  Future<bool> _exitApp(BuildContext context) {
    Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(

      appBar: AppBar(
        backgroundColor: globals.primaryColor,
        leading: new IconButton(
          icon: new Icon(Icons.arrow_back_ios),
            onPressed: () {
              _exitApp(context);
        }),
        title: Text(H.getText(context, H.getText(context, "impressum")),
      )),

      bottomNavigationBar: BottomAppBar(
        child: Container(
          margin: EdgeInsets.all(10.0),
          child: Text("App-ID: xxxxxxxx",
              style: TextStyle(color: globals.primaryColor  ),
          )),
      ),

      body: new Container(
        margin: EdgeInsets.fromLTRB(10.0, 10.0, 10.0, 10.0),
        child: new RefreshIndicator(
          onRefresh: _refreshPage,
          child: SingleChildScrollView(
            child: Wrap(
              direction: Axis.vertical,
              spacing: 10, // to apply margin horizontally
              runSpacing: 10, // to apply margin vertically
              children: <Widget>[
            Text("Name und Anschrift",
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            Text("xxx xxx xxx "),
            Text("xxx xxx xxx "),
            Text("xxx xxx xxx "),
            Spacer(),

            Text("Vertretungsberechtigter",
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            Text("xxx xxx xxx "),
            Spacer(),

            Text("Kontakt",
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            Text("Fax: xxx xxx xxx "),
            Text("E-Mail: xxx xxx xxx "),
            Spacer(),

            Text("Handelsregisternummer",
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            Text("xxx xxx xxx "),
            Spacer(),
            
          ]),
        )),
      ),
    );
  }

Future<void> _refreshPage() async
  {
    print('refreshing ...');
    await new Future.delayed(const Duration(seconds: 3));
  }


}
