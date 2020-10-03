import 'dart:isolate';
import 'dart:math';
import 'dart:ui';

import 'package:android_alarm_manager/android_alarm_manager.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// The [SharedPreferences] key to access the alarm fire count.
const String countKey = 'count';

/// The name associated with the UI isolate's [SendPort].
const String isolateName = 'isolate';

/// A port used to communicate from a background isolate to the UI isolate.
final ReceivePort port = ReceivePort();

/// Global [SharedPreferences] object.
SharedPreferences prefs;

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  IsolateNameServer.registerPortWithName(
    port.sendPort,
    isolateName,
  );
  prefs = await SharedPreferences.getInstance();
  if (!prefs.containsKey(countKey)) {
    await prefs.setInt(countKey, 0);
  }
  runApp(AlarmManagerExampleApp());
}

class AlarmManagerExampleApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Traffic Control',
      theme: ThemeData(
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: _AlarmHomePage(title: 'Traffic Control'),
    );
  }
}

class _AlarmHomePage extends StatefulWidget {
  _AlarmHomePage({Key key, this.title}) : super(key: key);
  final String title;

  @override
  _AlarmHomePageState createState() => _AlarmHomePageState();
}

class _AlarmHomePageState extends State<_AlarmHomePage> {
  @override
  void initState() {
    super.initState();
    AndroidAlarmManager.initialize();
    //port.listen((_) async => await playMusic());
  }

  //Future<void> playMusic() async {
    //print('Play');
    //await prefs.reload();
  //}

  static SendPort uiSendPort;

  static Future<void> callback() async {
    print('Alarm fired!');

    uiSendPort ??= IsolateNameServer.lookupPortByName(isolateName);
    uiSendPort?.send(null);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.red[50],
      appBar: AppBar(
        title: Text(widget.title, style: GoogleFonts.amaranth(fontSize: 22)),
        backgroundColor: Colors.redAccent,
      ),
      body: Stack(children: [
        Container(
            decoration: BoxDecoration(
                image: DecorationImage(
                    image: AssetImage("images/trafficcontrolBG.png"),
                    fit: BoxFit.fill))),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 150),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.end,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: <Widget>[
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  RaisedButton(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                    color: Colors.redAccent,
                    padding: EdgeInsets.symmetric(vertical: 15, horizontal: 65),
                    elevation: 0.5,
                    splashColor: Colors.white70,
                    child: Text('Set One Hour Timer',
                        style: GoogleFonts.amaranth(
                          shadows: <Shadow>[
                            Shadow(
                              blurRadius: 25,
                              color: Colors.black87,
                            )
                          ],
                          fontSize: 22,
                          color: Colors.white,
                          fontWeight: FontWeight.w500,
                        )),
                    key: ValueKey('RegisterOneShotAlarm'),
                    onPressed: () async {
                      await AndroidAlarmManager.oneShot(
                        const Duration(seconds: 3),
                        // Ensure we have a unique alarm ID.
                        Random().nextInt(pow(2, 31)),
                        callback,
                        exact: true,
                        wakeup: true,
                      );
                    },
                  ),
                ],
              )
            ],
          ),
        )
      ]),
    );
  }
}
