import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:csv/csv.dart';
import 'package:gbk2utf8/gbk2utf8.dart';


import '../database.dart';

class SettingPage extends StatefulWidget {
  @override
  _SettingPageState createState() => _SettingPageState();
}

class _SettingPageState extends State<SettingPage>
    with SingleTickerProviderStateMixin {
  AnimationController _controller;
  final _formKey = GlobalKey<FormState>();
  String _outputPath = '';
  String _openPath = '';

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
                child: Text(_outputPath),
              ),
              RaisedButton(
                child: Text('导出数据'),
                onPressed: _outputData,
              ),
              Padding(
                padding: EdgeInsets.symmetric(vertical: 30.0),
                child: Text(_openPath),
              ),
              Padding(
                padding: EdgeInsets.symmetric(vertical: 30.0),
              ),
              RaisedButton(
                child: Text('删除数据'),
                onPressed: _deleteData,
              )
            ],
          )
        ],
      ),
    );
  }

  void _outputData() async {
    List<List> buffer = await _exportCSVCarList();
    await _requestPermissions();
    final directory = await getExternalStorageDirectory();
    DateTime currentTime = DateTime.now();
    String timestamp =
        "${currentTime.year}${currentTime.month}${currentTime.day}${currentTime.hour}${currentTime.minute}${currentTime.second}";
    File file = File('${directory.path}/Documents/入库记录$timestamp.csv');
    String csv = const ListToCsvConverter().convert(buffer);
    await file.writeAsBytes(gbk.encode(csv));
    setState(() {
      _outputPath = file.path;
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
    return rows;
  }


  void _deleteData() {
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
                            '请问您是否要永久删除当前所有数据？(数据不可恢复，请谨慎操作！！！)',
                            style: TextStyle(
                              color: Colors.red,
                              fontSize: 16.0,
                            ),
                          ),
                          TextFormField(
                            validator: (input) =>
                                input == '删除所有数据' ? null : "请输入'确认删除'",
                            decoration: InputDecoration(
                              hintText: "若需要,请输入'删除所有数据'",
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
                    Navigator.of(context).pop();
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
                      await SQLiteClient().clean();
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
}
