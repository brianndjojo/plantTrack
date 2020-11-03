
//Reference 1 = https://github.com/FirebaseExtended/flutterfire/tree/master/packages/firebase_database
//Reference 2 = https://www.youtube.com/watch?v=ZiagJJTqnZQ
//Reference 3 = https://medium.com/@nitishk72/flutter-local-notification-1e43a353877b
//Reference 4 = https://medium.com/@ayushpguptaapg/using-streams-in-flutter-62fed41662e4

import 'package:flutter/material.dart';
import 'dart:async';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_database/ui/firebase_animated_list.dart';
import 'dart:convert';
import 'package:intl/intl.dart';
import 'resources/my_flutter_app_icons.dart' as customIcon;
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'resources/image_banner.dart';
import 'dataRetrieval.dart';
import 'package:hexcolor/hexcolor.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final FirebaseApp app = await FirebaseApp.configure(
    name: 'hello_world',
    options: const FirebaseOptions(
      googleAppID: '1:1024477209072:android:b7900e4bd9a39a133afd35',
      // apiKey: 'AIzaSyCTuFVDqesqmlxSGCuyoEF-TQbv6sEfYhk',
      apiKey: 'AIzaSyBrpLvi3QW-MsY4gJ-00n-F1eGaeft_hTw',
      databaseURL: 'https://soil-moisture-sensor-b10f9.firebaseio.com',
    ),
  );
  runApp(MaterialApp(
    title: 'HILL PlantTrack',
    home: MyHomePage(app: app),
  ));
}

class MyHomePage extends StatefulWidget {
  MyHomePage({this.app});
  final FirebaseApp app;

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  int _counter;
  DatabaseReference _counterRef;
  DatabaseReference _messagesRef;
  StreamSubscription<Event> _counterSubscription;
  StreamSubscription<Event> _messagesSubscription;
  bool _anchorToBottom = false;

  String _kTestKey = 'Hello';
  String _kTestValue = 'world!';
  DatabaseError _error;

  @override
  void initState() {
    super.initState();

    // Demonstrates configuring to the database using a file
    _counterRef = FirebaseDatabase.instance.reference().child('Soil_Moisture/append');
    // Demonstrates configuring the database directly
    final FirebaseDatabase database = FirebaseDatabase(app: widget.app);
    _messagesRef = database.reference().child('Soil_Moisture/append');
    database.reference().child('Soil_Moisture/append').once().then((DataSnapshot snapshot) {
      print('Connected to second database and read ${snapshot.value}');
    });
    database.setPersistenceEnabled(true);
    database.setPersistenceCacheSizeBytes(10000000);
    _counterRef.keepSynced(true);
    _counterSubscription = _counterRef.onValue.listen((Event event) {
      setState(() {
        _error = null;
        _counter = event.snapshot.value ?? 0;
      });
    }, onError: (Object o) {
      final DatabaseError error = o;
      setState(() {
        _error = error;
      });
    });
    _messagesSubscription =
        _messagesRef.limitToLast(10).onChildAdded.listen((Event event) {
      print('Child added: ${event.snapshot.value}');
    }, onError: (Object o) {
      final DatabaseError error = o;
      print('Error: ${error.code} ${error.message}');
    });
  }

  @override
  //stops all streamsubscriptions to prevent memory leak.
  void dispose() {
    super.dispose();
    _messagesSubscription.cancel();
    _counterSubscription.cancel();
  }

  Future<void> _increment() async {
    // Increment counter in transaction.
    final TransactionResult transactionResult =
        await _counterRef.runTransaction((MutableData mutableData) async {
      mutableData.value = (mutableData.value ?? 0) + 1;
      return mutableData;
    });

    if (transactionResult.committed) {
      _messagesRef.push().set(<String, String>{
        _kTestKey: '$_kTestValue ${transactionResult.dataSnapshot.value}'
      });
    } else {
      print('Transaction not committed.');
      if (transactionResult.error != null) {
        print(transactionResult.error.message);
      }
    }
  }

  //deletes all records within the database. Not for final implementation
  void _delete() async{
     _messagesRef.remove();
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('PlantTrack'),
      ),
      body: Column(
        children: <Widget>[
          StreamBuilder(
            stream: _messagesRef.onValue,
            builder: (context, snapshot){
              if(!snapshot.hasData){
                return Flexible(child: Center(child: CircularProgressIndicator(),));
              }    

             
              Map<dynamic, dynamic> map = snapshot.data.snapshot.value;
              if(map == null){
                return 
                  Flexible(child: Center(child: CircularProgressIndicator(),));
                
              }
              else{
                List list = map.values.toList();
                list.sort((a, b) {
                  return b["ID"].compareTo(a["ID"]);
                });
            
                return
                  Flexible(
                    child: Center(
                      child: _error == null
                        ? Text(
                            '${list.first}'
                                  
                        )
                        : Text(
                            'Error retrieving data.\n${_error.message}',
                      ),
                    ),
                  );
              }
            }
             
          ),
         
          ListTile(
            leading: Checkbox(
              onChanged: (bool value) {
                setState(() {
                  _anchorToBottom = value;
                });
              },
              value: _anchorToBottom,
            ),
            title: const Text('Anchor to bottom'),
          ),
          Flexible(
            child: FirebaseAnimatedList(
              key: ValueKey<bool>(_anchorToBottom),
              query: _messagesRef,
              reverse: _anchorToBottom,
              sort: _anchorToBottom
                  ? (DataSnapshot a, DataSnapshot b) => b.key.compareTo(a.key)
                  : null,
              itemBuilder: (BuildContext context, DataSnapshot snapshot,
                Animation<double> animation, int index) {

                  //Converting retrieved data into a format where each attribute can be accessed.
                  DateTime currentTime = DateTime.now();
                  dataList = dataListRetrieval(snapshot, dataList, currentTime);
                  
                  var iconState = Icons.check;

                  if(dataList.last.moistState == 'Wet'){
                    iconState = customIcon.MyFlutterApp.droplet;
                  }
                  if(dataList.last.moistState == 'Dry'){
                    iconState = customIcon.MyFlutterApp.cactus;
                  }

                  String stateColor = dataList.last.colorVal.replaceAll('#', '0xff');

                  return SizeTransition(
                    sizeFactor: animation,
                    child: ListTile(
                      trailing: IconButton(
                        //onPressed: () =>
                            //_messagesRef.child(snapshot.key).remove(),
                        icon: Icon(iconState),
                        color: Color(int.parse(stateColor)),
                      ),
                      title: Text(
                        "$index: ${dataList.last.moistState}",
                      ),
                      subtitle: Text(
                        "${dataList.last.date} | ${dataList.last.moistState} | ${dataList.last.moistVal}"
                      ),
                    ),
                  );
                },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _delete,
        tooltip: 'deletes all records',
        child: const Icon(Icons.delete),
      ),
    );
  }
}
