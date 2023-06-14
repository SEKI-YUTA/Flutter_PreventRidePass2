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

  static void readAllPointFromDB(Database db) async {
    // static Future<List<Point>> readAllPointFromDB(Database db) async {
    List<Point> pointList = [];
    List<Map<String, dynamic>> rawQuery =
        await db.rawQuery("select * from ${ConstantValue.pointTable}");
    print("data count ${rawQuery.length}");
  }

  static Future<Database> getAppDatabase() async {
    String dbPath = await getDatabasesPath();
    String path = join(dbPath, ConstantValue.dbName);
    Database database =
        await openDatabase(path, version: 1, onCreate: (db, version) async {
      await db.execute(
          "create table ${ConstantValue.pointTable} (id INTEGER PRIMARY KEY, name TEXT, latitude TEXT, longitude TEXT)");
    });

    return database;
  }
}
