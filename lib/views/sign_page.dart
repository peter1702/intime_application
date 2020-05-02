import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:signature/signature.dart';
import '../globals.dart' as globals;

class SignPage extends StatefulWidget {
  @override
  _SignPageState createState() => _SignPageState();
}

class _SignPageState extends State<SignPage> {
  final SignatureController _controller =
      SignatureController(penStrokeWidth: 5, penColor: Colors.red);

  @override
  void initState() {
    super.initState();
    _controller.addListener(() => {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: globals.primaryColor,
        title: Text('Unterschrift erfassen'),
      ),
      bottomNavigationBar: BottomAppBar(
        child: Container(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            mainAxisSize: MainAxisSize.max,
            children: <Widget>[
              //SHOW EXPORTED IMAGE IN NEW ROUTE
              IconButton(
                icon: const Icon(Icons.check),
                color: Colors.blue,
                onPressed: () async {
                  if (_controller.isNotEmpty) {
                    var bytes = await _controller.toPngBytes();
                    Navigator.pop(context, bytes);
                  }
                },
              ),
              //CLEAR CANVAS
              IconButton(
                icon: const Icon(Icons.clear),
                color: Colors.blue,
                onPressed: () {
                  setState(() => _controller.clear());
                },
              ),
            ],
          ),
        ),
      ),
      body: Builder(
        builder: (context) => Scaffold(
          //body: ListView(
          body: Column(
            children: <Widget>[
              Expanded(
                child:
                    //SIGNATURE CANVAS
                    Signature(
                        controller: _controller,
                        //height: 300,
                        height: double.infinity,
                        backgroundColor: Colors.grey[200]),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
