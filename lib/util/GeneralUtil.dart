import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:path/path.dart';
import 'package:prevent_ride_pass2/ConstantValue.dart';
import 'package:prevent_ride_pass2/model/Point.dart';
import 'package:prevent_ride_pass2/ConstantValue.dart';
import 'package:sqflite/sqflite.dart';

import 'package:sqflite/sqlite_api.dart';

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
}
