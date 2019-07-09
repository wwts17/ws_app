import 'dart:async';
import 'dart:io';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import 'package:synchronized/synchronized.dart';

class SQLiteClient {
  static final _default = 'ws.db';
  static final _version = 1;

  SQLiteClient._();
  static final _client = new SQLiteClient._();

  factory SQLiteClient() => _client;

  final _lock = new Lock();
  Database _db;

  Future<Database> getConn() async {
    var databasesPath = await getDatabasesPath();
    var path = join(databasesPath, _default);
    var exists = await databaseExists(path);
    if (!exists) {
      try {
        await Directory(dirname(path)).create(recursive: true);
        _db = await openDatabase(path, version: _version,
            onCreate: (db, version) async {
          await db.execute('''
        CREATE TABLE car(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        vin VARCHAR(50) UNIQUE NOT NULL,
        warehouse_id INTEGER,
        mark VARCHAR(50) NOT NULL,
        num INTEGER NOT NULL,
        created_at DATETIME NOT NULL DEFAULT (datetime('now','localtime')),
        updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP);
          ''');

          await db.execute('''
                  CREATE TABLE warehouse(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name VARCHAR(50) UNIQUE NOT NULL,
        created_at DATETIME NOT NULL DEFAULT (datetime('now','localtime')),
        updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP
        );
          ''');
          await db.execute('''
                  CREATE TABLE shift_car(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        vin VARCHAR(50) NOT NULL,
        bar_code VARCHAR(50) NOT NULL,
        created_at DATETIME NOT NULL DEFAULT (datetime('now','localtime')),
        updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP
        );
          ''');
        });
      } catch (_) {}
      return _db;
    }

    if (_db == null) {
      await _lock.synchronized(() async {
        // Check again once entering the synchronized block
        if (_db == null) {
          _db = await openDatabase(_default, version: _version);
        }
      });
    }
    return _db;
  }


  Future<void> clean() async{
    await getConn();
    if(_db!=null){
      var batch = _db.batch();
      batch.execute('''
      DROP TABLE IF EXISTS car;
      ''');
      batch.execute('''
      CREATE TABLE car(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        vin VARCHAR(50) UNIQUE NOT NULL,
        warehouse_id INTEGER,
        mark VARCHAR(50) NOT NULL,
        num INTEGER NOT NULL,
        created_at DATETIME NOT NULL DEFAULT (datetime('now','localtime')),
        updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP);
      ''');
      batch.execute('''
      DROP TABLE IF EXISTS warehouse;
      ''');
      batch.execute('''
       CREATE TABLE warehouse(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name VARCHAR(50) UNIQUE NOT NULL,
        created_at DATETIME NOT NULL DEFAULT (datetime('now','localtime')),
        updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP
        );
      ''');
      batch.execute('''
      DROP TABLE IF EXISTS shift_car;
      ''');
      await batch.execute('''
                  CREATE TABLE shift_car(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        vin VARCHAR(50) NOT NULL,
        bar_code VARCHAR(50) NOT NULL,
        created_at DATETIME NOT NULL DEFAULT (datetime('now','localtime')),
        updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP
        );
          ''');
      await batch.commit();
    }
  }
}
