import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:geolocator/geolocator.dart';
import 'package:path/path.dart';
import 'package:prevent_ride_pass2/ConstantValue.dart';
import 'package:prevent_ride_pass2/model/Point.dart';
import 'package:prevent_ride_pass2/ConstantValue.dart';
import 'package:prevent_ride_pass2/notification_screen.dart';
import 'package:sqflite/sqflite.dart';

import 'package:sqflite/sqlite_api.dart';

// https://github.com/Baseflow/flutter-geolocator/issues/1212

class GeneralUtil {
  static Future<int> insertPoint(Database database, Point p) async {
    int insertedId = -1;
    if (database == null) return insertedId;
    await database.transaction((txn) async {
      insertedId = await txn.rawInsert(
          "insert into ${ConstantValue.pointTable} (name, latitude, longitude) values (?, ?, ?)",
          [p.name, p.latitude, p.longitude]);
      print("inserted id: $insertedId");
    });
    return insertedId;
  }

  static Future<List<Point>> readAllPointFromDB(Database db) async {
    // static Future<List<Point>> readAllPointFromDB(Database db) async {
    List<Point> pointList = [];
    Future<List> list =
        db.rawQuery("select * from ${ConstantValue.pointTable}");
    return list.then((value) => List.generate(value.length, (idx) {
          String name = value[idx]["name"];
          double latitiude = double.parse(value[idx]["latitude"]);
          double longitude = double.parse(value[idx]["longitude"]);
          return Point(name: name, latitude: latitiude, longitude: longitude);
        }));
  }

  static Future<Database> getAppDatabase() async {
    String dbPath = await getDatabasesPath();
    String path = join(dbPath, ConstantValue.dbName);
    Database database =
        await openDatabase(path, version: 1, onCreate: (db, version) async {
      await db.execute(
          "create table ${ConstantValue.pointTable} (id INTEGER PRIMARY KEY, name TEXT, latitude TEXT, longitude TEXT)");
      await db.execute(
          "create table ${ConstantValue.routeTable} (id INTEGER PRIMARY KEY, name TEXT, latitude TEXT, longitude TEXT)");
    });

    return database;
  }

  static Future<bool> checkNetworkConnect() {
    final connectState = Connectivity().checkConnectivity();
    return connectState.then((value) {
      if (value == ConnectivityResult.none) {
        return false;
      } else {
        return true;
      }
    });
  }

  static Future<bool> checkLocationPermission() async {
    bool serviceEnabled;
    LocationPermission permission;
    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      // Location services are not enabled don't continue
      // accessing the position and request users of the
      // App to enable the location services.
      return Future.error('Location services are disabled.');
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        // Permissions are denied, next time you could try
        // requesting permissions again (this is also where
        // Android's shouldShowRequestPermissionRationale
        // returned true. According to Android guidelines
        // your App should show an explanatory UI now.
        return Future.error('Location permissions are denied');
      }
    }

    if (permission == LocationPermission.deniedForever) {
      // Permissions are denied forever, handle appropriately.
      return Future.error(
          'Location permissions are permanently denied, we cannot request permissions.');
    }
    bool result = (permission == LocationPermission.whileInUse ||
            permission == LocationPermission.always)
        ? true
        : false;
    return result;
  }

  static Future<bool> checkNotificationPermission() async {
    bool? result = false;
    FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
        FlutterLocalNotificationsPlugin();
    result = await flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.requestPermission();

    return Future.value(result);
  }

  static Future<void> notify(
      {required String title,
      required String body,
      required int id,
      // required BuildContext context,
      bool playSound = true,
      bool vib = true}) {
    final flnp = FlutterLocalNotificationsPlugin();
    return flnp
        .initialize(
          InitializationSettings(
            android: AndroidInitializationSettings('location_target'),
          ),
          // onDidReceiveNotificationResponse: (details) {
          //   onDidReceiveLocalNotification(id, title, body, "", context);
          // },
        )
        .then((_) => flnp.show(
            id,
            title,
            body,
            NotificationDetails(
              android: AndroidNotificationDetails(
                'channel_id',
                'channel_name',
                playSound: playSound,
                enableVibration: vib,
              ),
            )));
  }

  static void onDidReceiveLocalNotification(int id, String title, String body,
      String payload, BuildContext context) async {
    // display a dialog with the notification details, tap ok to go to another page
    showDialog(
      context: context,
      builder: (BuildContext context) => CupertinoAlertDialog(
        title: Text(title),
        content: Text(body),
        actions: [
          CupertinoDialogAction(
            isDefaultAction: true,
            child: Text('Ok'),
            onPressed: () async {
              Navigator.of(context, rootNavigator: true).pop();
              await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => NotificationScreen(
                    payload: payload,
                  ),
                ),
              );
            },
          )
        ],
      ),
    );
  }
}
