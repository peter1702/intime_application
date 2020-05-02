import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'dart:io';

import '../models/tour.dart';
import '../helpers/helpers.dart';
import '../globals.dart' as globals;

class EventPage extends StatefulWidget {
  EventPage({Key key, this.tourData}) : super(key: key);

  Tour tourData;

  @override
  _EventPageState createState() => new _EventPageState();
}

class _EventPageState extends State<EventPage> {

  Tour tourData;
  //var dateFormatter = new DateFormat('dd.MM.yyyy');
  //var timeFormatter = new DateFormat('HH:mm:ss');

  _initializeData() {
    tourData = widget.tourData;
  }

  Future<bool> _exitApp(BuildContext context) {
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
    return new Scaffold(
      appBar: new AppBar(
        title: new Text(H.getText(context, "tour_history")),
        backgroundColor: globals.primaryColor,
        leading: new IconButton(
          icon: new Icon(Icons.arrow_back_ios, color: Colors.white),
          onPressed: () {
            _exitApp(context);
          }),
      ),
      body: ListView.builder( 
        itemCount: tourData.eventList.length, 
        itemBuilder: (context, index) {
          return Padding(
          padding: new EdgeInsets.fromLTRB(10.0,5.0,10.0,0.0),
          child: 
          Card(child: Padding(
            padding: new EdgeInsets.all(10.0),
            child:
            Column(children: <Widget>[
              Row(children: <Widget>[
                Expanded(
                  child: Text(Events.getEventDescr(context, tourData.eventList[index].event),
                    style: globals.styleTableTextNormalBold,),
                ),
                Container(
                  height: 30,
                  child:
                    Text(Helpers.formatDate(tourData.eventList[index].dateTime),
                    style: globals.styleTableTextNormal,),
                ),
              ]),    
              Row(children: <Widget>[
                Expanded(
                  child: tourData.eventList[index].reason != ''
                  ? Text(Events.getReasonDescr(context, tourData.eventList[index].reason), 
                      style: globals.styleTableTextNormal,)
                  : tourData.eventList[index].info != ''
                    ? Text(tourData.eventList[index].info,
                        style: globals.styleTableTextNormal,)
                    : tourData.eventList[index].delvno != ''
                      ? Text(H.getText(context, 'delivery') + ' ' + tourData.eventList[index].delvno,
                          style: globals.styleTableTextNormal,)
                      : Text('...'),
                ),
                Container(
                  height: 30,
                  child: Text(Helpers.formatTime(tourData.eventList[index].dateTime, seconds:true),
                    style: globals.styleTableTextNormal,),
                ),
              ]),  
            ]),)      
          ));
        }     
      ),
    );
  }
}