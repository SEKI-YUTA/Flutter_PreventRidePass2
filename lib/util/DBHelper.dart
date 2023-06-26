import 'package:prevent_ride_pass2/ConstantValue.dart';
import 'package:prevent_ride_pass2/model/Point.dart';
import 'package:sqflite/sqflite.dart';

class DBHelper {
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
          int id = value[idx]["id"];
          String name = value[idx]["name"];
          double latitiude = double.parse(value[idx]["latitude"]);
          double longitude = double.parse(value[idx]["longitude"]);
          return Point(
              id: id, name: name, latitude: latitiude, longitude: longitude);
        }));
  }

  static Future<int> deletePointByID(Database db, int id) async {
    int count = await db
        .rawDelete("delete from ${ConstantValue.pointTable} where id = $id");
    return count;
  }

  static Future<int> updatePointByID(
      Database db, int id, String newName) async {
    int count = await db.rawUpdate(
        "update ${ConstantValue.pointTable} set name = ? where id = $id",
        [newName]);
    return count;
  }
}
