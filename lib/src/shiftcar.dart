import 'dart:async';
import 'database.dart';
import 'package:sqflite/sqlite_api.dart';
import 'exception.dart';

class ShiftCar {
  int id;

  String vin;

  String barCode;

  String createdAt;

  String updatedAt;

  ShiftCar({this.id, this.vin, this.barCode, this.createdAt, this.updatedAt});

  factory ShiftCar.fromMap(Map<String, dynamic> map) => ShiftCar(
      id: map["id"],
      vin: map["vin"],
      barCode: map["bar_code"],
      createdAt: map["created_at"],
      updatedAt: map["updated_at"]);

  Map<String, dynamic> toMap() => {
    "id": id,
    "vin": vin,
    "bar_code":barCode,
    "created_at": createdAt,
    "updated_at": updatedAt
  };
}

class ShiftCarRepository{
  final _table = "shift_car";

  Future<int> save(ShiftCar sc) async {
    final client = await SQLiteClient().getConn();
    if (sc.id==null) {
      return await client.insert(_table, {"vin": sc.vin,"bar_code":sc.barCode},
          conflictAlgorithm: ConflictAlgorithm.rollback);
    }
    var result =
    await client.query(_table, where: 'id = ?', whereArgs: [sc.id]);
    if (result.isEmpty) {
      throw DataException('not found data.');
    }
    ShiftCar whDB = ShiftCar.fromMap(result[0]);
    return await client.update(_table, {"bar_code": sc.barCode},
        where: "id = ?", whereArgs: [whDB.id]);
  }

  Future<List<ShiftCar>> all() async {
    final client = await SQLiteClient().getConn();
    var result = await client.query(_table,orderBy: "created_at desc").then((l)=>l.map((m)=>ShiftCar.fromMap(m)).toList());
    return result;
  }

  Future<List<ShiftCar>> searchVinLike(String vin) async {
    final client = await SQLiteClient().getConn();
    var result = await client.query(_table,where:"vin like ? ",whereArgs: ['%${vin}%'],orderBy: 'created_at desc').then((l)=>l.map((m)=>ShiftCar.fromMap(m)).toList());
    return result;
  }

}