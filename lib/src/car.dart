import 'database.dart';
import 'exception.dart';
import 'package:sqflite/sqflite.dart';

class Car {
  int id;

  int warehouseId;

  String vin;

  String mark;

  int num;

  String createdAt;

  String updatedAt;

  Car(
      {this.id,
      this.warehouseId,
      this.vin,
      this.mark,
      this.num,
      this.createdAt,
      this.updatedAt});

  factory Car.fromMap(Map<String, dynamic> map) => Car(
      id: map["id"],
      warehouseId: map["warehouse_id"],
      vin: map["vin"],
      mark: map["mark"],
      num: map["num"] is String ? int.parse(map["num"]):map["num"],
      createdAt: map["created_at"],
      updatedAt: map["updated_at"]);

  Map<String, dynamic> toMap() => {
        "id": id,
        "warehouse_id": warehouseId,
        "vin": vin,
        "mark": mark,
        "num": num,
        "created_at": createdAt,
        "updated_at": updatedAt
      };
}

class CarRepository {
  final _table = 'car';

  Future<int> save(Car car) async{
    try{
      final client = await SQLiteClient().getConn();
      if (car.id==null){
        return await client.insert(_table, {"warehouse_id":car.warehouseId,"vin":car.vin,"mark":car.mark,"num":car.num});
      }
      List li = await client.query(_table,where: "id = ?",whereArgs: [car.id]);
      if (li.isEmpty){
        throw DataException("not found data");
      }
      Car carDB = Car.fromMap(li[0]);
      return await client.update(_table, {"warehouse_id": car.warehouseId,
        "mark": car.mark,
        "num": car.num,},where: 'id = ?',whereArgs: [carDB.id]);
    }on DatabaseException catch(e){
      return -1;
    }
  }

  Future<List<Car>> all() async {
    final client = await SQLiteClient().getConn();
    var result = await client.query(_table,orderBy: 'created_at desc').then((l)=>l.map((m)=>Car.fromMap(m)).toList());
    return result;
  }

  Future<Car> latest() async{
    final client = await SQLiteClient().getConn();
    var result = await client.query(_table, orderBy: 'created_at desc', limit: 1).then((l)=>l.map((m)=>Car.fromMap(m)).toList());
    if (result.isEmpty){
      return null;
    }
    return result[0];
  }

  Future<List<Car>> searchVinLike(String vin) async {
    final client = await SQLiteClient().getConn();
    var result = await client.query(_table,where:"vin like ? ",whereArgs: ['%${vin}%'],orderBy: 'created_at desc').then((l)=>l.map((m)=>Car.fromMap(m)).toList());
    return result;
  }

  Future<int> count(int warehouseId,String mark) async{
    final client = await SQLiteClient().getConn();
    return Sqflite.firstIntValue(await client.rawQuery('select count(id) from car where warehouse_id = ? and mark = ?',[warehouseId,mark]));
  }
}
