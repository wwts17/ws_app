import 'database.dart';
import 'exception.dart';

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
  }

  Future<List<Car>> all() async {
    final client = await SQLiteClient().getConn();
    var result = await client.query(_table,orderBy: 'created_at desc').then((l)=>l.map((m)=>Car.fromMap(m)).toList());
    return result;
  }
}
