
//Reference 1 = https://github.com/FirebaseExtended/flutterfire/tree/master/packages/firebase_database
//Reference 2 = https://www.youtube.com/watch?v=ZiagJJTqnZQ
//Reference 3 = https://medium.com/@nitishk72/flutter-local-notification-1e43a353877b
import 'package:flutter/material.dart';
import 'dart:async';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_database/ui/firebase_animated_list.dart';
import 'dart:convert';
//import 'package:charts_flutter/flutter.dart' as charts;
import 'package:intl/intl.dart';
import 'resources/my_flutter_app_icons.dart' as customIcon;
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'resources/image_banner.dart';

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
  List<RetrieveData> dataList = new List.generate(24, (index) => null);
  //List<GraphData> graphList = new List();
  String _kTestKey = 'Hello';
  String _kTestValue = 'world!';
  DatabaseError _error;
  //DataSnapshot newestSnap;
  
  FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin;
  @override
  void initState() {
    
    super.initState();
    // Demonstrates configuring to the database using a file
    _counterRef = FirebaseDatabase.instance.reference().child('Soil_Moisture/append');
    deleteAll();
    //deleteAll();
    // Demonstrates configuring the database directly
    final FirebaseDatabase database = FirebaseDatabase(app: widget.app);
    _messagesRef = database.reference().child('Soil_Moisture/append');
    database.reference().child('Soil_Moisture').once().then((DataSnapshot snapshot) {
      print('Connected to second database and read ${snapshot.value}');
      //graphList = graphListRetrieval(snapshot, graphList);
      //dataList.add(snapshot);
    });
    
    //storing data into device cache, using setPersistence
    /*database.setPersistenceEnabled(true);
    database.setPersistenceCacheSizeBytes(10000000);
    _counterRef.keepSynced(true);*/
    
    //_counterSubscription used to check if any event has changed in the app, and call setState() to rerender the app if a change occurs.
    //calling setState((){}) only already rerenders the page.
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
    //Checks if data updated into the database is valid or not.
    _messagesSubscription =
      _messagesRef.limitToLast(1).onChildAdded.listen((Event event) {
      print('Child added: ${event.snapshot.value}');
    }, onError: (Object o) {
      final DatabaseError error = o;
      print('Error: ${error.code} ${error.message}');
    });

    // initialise the plugin. app_icon needs to be a added as a drawable resource to the Android head project   
     // If you have skipped STEP 3 then change app_icon to @mipmap/ic_launcher
    var initializationSettingsAndroid =
        new AndroidInitializationSettings('@mipmap/ic_launcher'); 
    var initializationSettingsIOS = new IOSInitializationSettings();
    var initializationSettings = new InitializationSettings(
        initializationSettingsAndroid, initializationSettingsIOS);
    flutterLocalNotificationsPlugin = new FlutterLocalNotificationsPlugin();
    flutterLocalNotificationsPlugin.initialize(initializationSettings,
    onSelectNotification: onSelectNotification);
  }

  @override
  void dispose() {
    super.dispose();
    _messagesSubscription.cancel();
    _counterSubscription.cancel();
  }

  void deleteAll(){
    //dispose();
    _counterRef.remove();
  }
  
  Future onSelectNotification(String payload) async {
    showDialog(
      context: context,
      builder: (_) {
        return new AlertDialog(
          title: Text("Alert!"),
          content: Text("Plantbed is dry. You should water them soon."),
        );
      },
    );
  }
  
  Future _showNotificationWithDefaultSound() async {
    var androidPlatformChannelSpecifics = new AndroidNotificationDetails(
        'your channel id', 'your channel name', 'your channel description',
        importance: Importance.Max, priority: Priority.High, playSound: false,);
    var iOSPlatformChannelSpecifics = new IOSNotificationDetails();
    var platformChannelSpecifics = new NotificationDetails(
        androidPlatformChannelSpecifics, iOSPlatformChannelSpecifics);
    Duration interval = Duration(seconds:30);
    //Stream<int> stream = Stream<int>.periodic(interval);
    await flutterLocalNotificationsPlugin.show(
      0,
      'Alert!',
      'Plantbed is dry. You should water them soon.',
      platformChannelSpecifics,
      payload: 'Default_Sound',
    );
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('HILL PlantTrack'),
        backgroundColor: Colors.black,
        leading: Builder(
          builder: (BuildContext context) {
            return IconButton(
              icon: const Icon(customIcon.MyFlutterApp.droplet),
              onPressed: () { Scaffold.of(context).openDrawer(); },
              tooltip: MaterialLocalizations.of(context).openAppDrawerTooltip,
            );
          },
        ),
      ),
      body: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          //Flexible(
            //child: Center(
              /*child: _error == null
              ? Text(
                  'Button tapped $_counter time${_counter == 1 ? '' : 's'}.\n\n'
                  'This includes all devices, ever.',
                )
              : Text(
                  'Error retrieving button tap count:\n${_error.message}',
              ),*/
              //ImageBanner("assets/images/background.png"),
            //),
          //),
          ImageBanner("assets/images/background.png"),
          Flexible(
            child: FirebaseAnimatedList(
              defaultChild: CircularProgressIndicator(),
              shrinkWrap: true,
              key: ValueKey<bool>(_anchorToBottom),
              query: _messagesRef,
              //physics: const NeverScrollableScrollPhysics(),
              reverse: false,
              sort: true
                  ? (DataSnapshot a, DataSnapshot b) => b.key.compareTo(a.key)
                  : null,
              itemBuilder: (BuildContext context, DataSnapshot snapshot,
                Animation<double> animation, int index) {
                DateTime currentTime = DateTime.now();
                dataList = dataListRetrieval(snapshot, dataList, currentTime);
                print('$index Most Recent ID: ${dataList.last.id}');
                print(dataList.length);
                String test = snapshot.value['MoistureState'];
                print(test);

                var correspondingIcon = Icons.check;  
                Color correspondingColor = Colors.green;
                if(dataList.last.moistState == 'Dry'){
                  correspondingColor = Colors.red;
                  correspondingIcon = customIcon.MyFlutterApp.cactus;
                  _showNotificationWithDefaultSound();
                }
                if(dataList.last.moistState == 'Wet'){
                  correspondingColor = Colors.blue;
                  correspondingIcon = customIcon.MyFlutterApp.droplet;
                }
                
                return SizeTransition(
                  sizeFactor: animation,
                  child:  ListTileTheme(
                    textColor: correspondingColor ,
                    child: 
                    ListTile(
                      trailing: IconButton(
                        //onPressed: () =>
                          //_messagesRef.child(snapshot.key).remove(),
                        //gotta change this in a while.
                        icon: Icon(correspondingIcon),
                      ),
                      title: Text(
                        "${dataList.last.id} : ${dataList.last.moistState}"
                      ),
                      isThreeLine: false,
                      subtitle: Text("${dataList.last.date} | MOISTURE: ${dataList.last.moistVal} | STATE: ${dataList.last.moistState}"),
                      dense: true,
                    ),
                  )
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}


List<RetrieveData> dataListRetrieval(DataSnapshot snapshot, List<RetrieveData> dataList, DateTime currentTime){
  var data = snapshot.value;
  dataList.clear();
  String date = DateFormat('yyyy-MM-dd').format(currentTime);
  
  RetrieveData collectData = new RetrieveData(
    int.parse(data['ID']),
    data['MoistureState'],
    int.parse(data['Moisture']),
    data['color'],
    date
  );
  dataList.add(collectData);
  
  dataList.sort((RetrieveData a, RetrieveData b){
    return a.id.compareTo(b.id);
  });
  //print(dataList);
  return dataList;
}


class RetrieveData{
  int id;
  String moistState;
  int moistVal;
  String colorVal;
  String date;
  RetrieveData(this.id, this.moistState, this.moistVal,this.colorVal, this.date);
}


