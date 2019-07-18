import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:csv/csv.dart';
import 'package:gbk2utf8/gbk2utf8.dart';
import 'package:audioplayers/audio_cache.dart';

import '../database.dart';

const _successAudio = 'success.mp3';
const _errorAudio = 'error.mp3';

class SettingPage extends StatefulWidget {
  @override
  _SettingPageState createState() => _SettingPageState();
}

class _SettingPageState extends State<SettingPage>
    with SingleTickerProviderStateMixin {
  AnimationController _controller;
  static AudioCache _player = AudioCache();
  final _formKey = GlobalKey<FormState>();
  String _outputCarPath = '';
  String _outputShiftCarPath = '';

  @override
  void initState() {
    _controller = AnimationController(vsync: this);
    super.initState();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('系统设置'),
      ),
      body: ListView(
        children: <Widget>[
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              Padding(
                padding: EdgeInsets.symmetric(vertical: 30.0),
                child: Text(_outputCarPath),
              ),
              RaisedButton(
                child: Text('导出扫描入库数据'),
                onPressed: _outputCarData,
              ),
              Padding(
                padding: EdgeInsets.symmetric(vertical: 30.0),
                child: Text(_outputShiftCarPath),
              ),
              RaisedButton(
                child: Text('导出提车数据'),
                onPressed: _outputShiftCarData,
              ),
              Padding(
                padding: EdgeInsets.symmetric(vertical: 30.0),
              ),
              RaisedButton(
                child: Text('删除扫描数据'),
                onPressed: _deleteCars,
              ),
              Padding(
                padding: EdgeInsets.symmetric(vertical: 30.0),
              ),
              RaisedButton(
                child: Text('删除提车数据'),
                onPressed: _deleteShifCars,
              ),
              Padding(
                padding: EdgeInsets.symmetric(vertical: 30.0),
              ),
              RaisedButton(
                child: Text('删除仓库数据'),
                onPressed: _deleteWarehouse,
              ),
              Padding(
                padding: EdgeInsets.symmetric(vertical: 30.0),
              ),
            ],
          )
        ],
      ),
    );
  }

  void _outputCarData() async {
    List<List> buffer = await _exportCSVCarList();
    if (buffer == null || buffer.isEmpty) {
      setState(() {
        _outputCarPath = "数据库暂无数据可导出";
      });
      return;
    }
    await _requestPermissions();
    final directory = await getExternalStorageDirectory();
    DateTime currentTime = DateTime.now();
    String timestamp =
        "${currentTime.year}${currentTime.month}${currentTime.day}${currentTime.hour}${currentTime.minute}${currentTime.second}";
    File file = File('${directory.path}/Documents/扫描入库记录$timestamp.csv');
    String csv = const ListToCsvConverter().convert(buffer);
    await file.writeAsBytes(gbk.encode(csv));
    setState(() {
      _outputCarPath = file.path;
    });
  }

  Future _requestPermissions() async {
    PermissionStatus permission = await PermissionHandler()
        .checkPermissionStatus(PermissionGroup.storage);

    if (permission != PermissionStatus.granted) {
      Map<PermissionGroup, PermissionStatus> permissions =
          await PermissionHandler()
              .requestPermissions([PermissionGroup.storage]);
    }
  }

  void _outputShiftCarData() async {
    List<List> buffer = await _exportCSVShiftCarList();
    if (buffer == null || buffer.isEmpty) {
      setState(() {
        _outputShiftCarPath = "数据库暂无数据可导出";
      });
      return;
    }
    await _requestPermissions();
    final directory = await getExternalStorageDirectory();
    DateTime currentTime = DateTime.now();
    String timestamp =
        "${currentTime.year}${currentTime.month}${currentTime.day}${currentTime.hour}${currentTime.minute}${currentTime.second}";
    File file = File('${directory.path}/Documents/提车记录$timestamp.csv');
    String csv = const ListToCsvConverter().convert(buffer);
    await file.writeAsBytes(gbk.encode(csv));
    setState(() {
      _outputShiftCarPath = file.path;
    });
  }

  Future<List<List>> _exportCSVCarList() async {
    final client = await SQLiteClient().getConn();
    final sql = '''
    SELECT 
    car.id AS ID,
    car.vin AS VIN码,
    warehouse.name AS 仓库,
    car.mark AS 道位,
    car.num AS 序号,
    car.created_at AS 扫描时间
    FROM car,warehouse WHERE car.warehouse_id = warehouse.id ORDER BY 扫描时间;
    ''';
    var result = await client.rawQuery(sql);

    List<List<dynamic>> rows = List();
    if (result.isNotEmpty) {
      // [[field1, field2, field3, ...],[ column1.v1, column1.v2, column1.v3 ...], ...]
      var field = result[0].keys.toList();
      rows.add(field);
      result.forEach((f) {
        var row = [];
        for (int i = 0; i < field.length; i++) {
          row.add(f[field[i]]);
        }
        rows.add(row);
      });
    }
    return rows;
  }

  Future<List<List>> _exportCSVShiftCarList() async {
    final client = await SQLiteClient().getConn();
    final sql = '''
    SELECT 
    vin AS VIN码,
    bar_code AS 自编条码,
    created_at AS 扫描时间
    FROM shift_car ORDER BY created_at desc;
    ''';
    var result = await client.rawQuery(sql);
    List<List<dynamic>> rows = List();
    if(result.isNotEmpty){
      // [[field1, field2, field3, ...],[ column1.v1, column1.v2, column1.v3 ...], ...]
      var field = result[0].keys.toList();
      rows.add(field);
      result.forEach((f) {
        var row = [];
        for (int i = 0; i < field.length; i++) {
          row.add(f[field[i]]);
        }
        rows.add(row);
      });
    }
    return rows;
  }

  void _deleteWarehouse() {
    showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            content: ListView(
              children: <Widget>[
                Container(
                    height: 300,
                    child: Form(
                      key: _formKey,
                      child: Column(
                        children: <Widget>[
                          Icon(
                            Icons.delete_forever,
                            size: 80.0,
                            color: Colors.red,
                          ),
                          Text(
                            '请问您是否要永久删除当前所有仓库数据？(删除仓库数据同时会删除扫描数据,数据不可恢复，请谨慎操作！！！)',
                            style: TextStyle(
                              color: Colors.red,
                              fontSize: 16.0,
                            ),
                          ),
                        ],
                      ),
                    )),
              ],
            ),
            actions: <Widget>[
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 20.0),
                child: RaisedButton(
                  onPressed: () {
                    Navigator.of(context).pop(false);
                  },
                  child: Text('取消'),
                  color: Colors.green,
                  textColor: Colors.black,
                ),
              ),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 20.0),
                child: RaisedButton(
                  onPressed: () async {
                    if (_formKey.currentState.validate()) {
                      await SQLiteClient().cleanWarehouse();
                      await SQLiteClient().cleanCars();
                      _playMusic(_successAudio);
                      Navigator.of(context).pop(true);
                    }
                  },
                  child: Text('确认'),
                  color: Colors.red,
                  textColor: Colors.black,
                ),
              )
            ],
          );
        });
    return;
  }

  void _deleteCars() {
    showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            content: ListView(
              children: <Widget>[
                Container(
                    height: 300,
                    child: Form(
                      key: _formKey,
                      child: Column(
                        children: <Widget>[
                          Icon(
                            Icons.delete_forever,
                            size: 80.0,
                            color: Colors.red,
                          ),
                          Text(
                            '请问您是否要永久删除当前所有扫描数据？(数据不可恢复，请谨慎操作！！！)',
                            style: TextStyle(
                              color: Colors.red,
                              fontSize: 16.0,
                            ),
                          ),
                        ],
                      ),
                    )),
              ],
            ),
            actions: <Widget>[
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 20.0),
                child: RaisedButton(
                  onPressed: () {
                    Navigator.of(context).pop(false);
                  },
                  child: Text('取消'),
                  color: Colors.green,
                  textColor: Colors.black,
                ),
              ),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 20.0),
                child: RaisedButton(
                  onPressed: () async {
                    if (_formKey.currentState.validate()) {
                      await SQLiteClient().cleanCars();
                      _playMusic(_successAudio);
                      Navigator.of(context).pop(true);
                    }
                  },
                  child: Text('确认'),
                  color: Colors.red,
                  textColor: Colors.black,
                ),
              )
            ],
          );
        });
    return;
  }

  void _deleteShifCars() {
    showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            content: ListView(
              children: <Widget>[
                Container(
                    height: 300,
                    child: Form(
                      key: _formKey,
                      child: Column(
                        children: <Widget>[
                          Icon(
                            Icons.delete_forever,
                            size: 80.0,
                            color: Colors.red,
                          ),
                          Text(
                            '请问您是否要永久删除当前所有提车数据？(数据不可恢复，请谨慎操作！！！)',
                            style: TextStyle(
                              color: Colors.red,
                              fontSize: 16.0,
                            ),
                          ),
                        ],
                      ),
                    )),
              ],
            ),
            actions: <Widget>[
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 20.0),
                child: RaisedButton(
                  onPressed: () {
                    Navigator.of(context).pop(false);
                  },
                  child: Text('取消'),
                  color: Colors.green,
                  textColor: Colors.black,
                ),
              ),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 20.0),
                child: RaisedButton(
                  onPressed: () async {
                    if (_formKey.currentState.validate()) {
                      await SQLiteClient().cleanShiftCars();
                      _playMusic(_successAudio);
                      Navigator.of(context).pop(true);
                    }
                  },
                  child: Text('确认'),
                  color: Colors.red,
                  textColor: Colors.black,
                ),
              )
            ],
          );
        });
    return;
  }

  Future<void> _playMusic(String name) async {
    await _player.play(name);
  }
}
