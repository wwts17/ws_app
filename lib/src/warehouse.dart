import 'dart:async';
import 'database.dart';
import 'package:sqflite/sqlite_api.dart';
import 'exception.dart';

class Warehouse {
  int id;

  String name;

  String createdAt;

  String updatedAt;

  Warehouse({this.id, this.name, this.createdAt, this.updatedAt});

  factory Warehouse.fromMap(Map<String, dynamic> map) => Warehouse(
      id: map["id"],
      name: map["name"],
      createdAt: map["created_at"],
      updatedAt: map["updated_at"]);

  Map<String, dynamic> toMap() => {
        "id": id,
        "name": name,
        "created_at": createdAt,
        "updated_at": updatedAt
      };
}

class WarehouseRepository {
  final _table = 'warehouse';

  Future<int> save(Warehouse wh) async {
    final client = await SQLiteClient().getConn();
    if (wh.id==null) {
      return await client.insert(_table, {"name": wh.name},
          conflictAlgorithm: ConflictAlgorithm.rollback);
    }
    var result =
        await client.query(_table, where: 'id = ?', whereArgs: [wh.id]);
    if (result.isEmpty) {
      throw DataException('not found data.');
    }
    Warehouse whDB = Warehouse.fromMap(result[0]);
    return await client.update(_table, {"name": wh.name},
        where: "id = ?", whereArgs: [whDB.id]);
  }

  Future<List<Warehouse>> all() async {
    final client = await SQLiteClient().getConn();
    var result = await client.query(_table).then((l)=>l.map((m)=>Warehouse.fromMap(m)).toList());
    return result;
    //return [Warehouse(id: 0, name: "柳州1号仓"), Warehouse(id: 1, name: "柳州2号仓")];
  }
  

  Future<Warehouse> queryById(int id) async{
    final client = await SQLiteClient().getConn();
    var result = await client.query(_table,where: 'id = ?',whereArgs: [id]);
    if(result.isEmpty){
      throw DataException('not found data');
    }
    return Warehouse.fromMap(result[0]);
  }
}


