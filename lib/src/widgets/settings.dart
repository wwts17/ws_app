import 'dart:io';
import 'package:flutter/material.dart';
import 'package:spreadsheet_decoder/spreadsheet_decoder.dart';
import 'package:path_provider/path_provider.dart';
import 'package:file_picker/file_picker.dart';
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
              RaisedButton(
                child: Text('导入数据'),
                onPressed: _inputData,
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
    final client = await SQLiteClient().getConn();
    final sql = '''
    SELECT 
    car.id AS ID,
    car.vin AS 车辆识别码,
    warehouse.name AS 仓库,
    car.mark AS 标识,
    car.num AS 序号,
    car.created_at AS 创建时间
    FROM car,warehouse WHERE car.warehouse_id = warehouse.id ORDER BY 创建时间;
    ''';
    var result = await client.rawQuery(sql);
    List<List<dynamic>> buffer = List();
    // 字段
    var field = result[0].keys.toList();
    buffer.add(field);
    result.forEach((f) {
      var temp = [];
      for(int i=0;i<field.length;i++){
        temp.add(f[field[i]]);
      }
      buffer.add(temp);
    });
    PermissionStatus permission = await PermissionHandler()
        .checkPermissionStatus(PermissionGroup.storage);

    if (permission != PermissionStatus.granted) {
      Map<PermissionGroup, PermissionStatus> permissions =
          await PermissionHandler()
              .requestPermissions([PermissionGroup.storage]);
    }

    final directory = await getExternalStorageDirectory();
    var path = directory.path;
    var now = DateTime.now();
    var file = File(
        '$path/Documents/入库记录${now.year}${now.month}${now.day}${now.hour}${now.minute}${now.second}.csv');
    String csv = const ListToCsvConverter().convert(buffer);
    await file.writeAsBytes(gbk.encode(csv));
    setState(() {
      _outputPath = file.path;
    });
  }

  void _inputData() async {
    var file = await FilePicker.getFile();
    setState(() {
      _openPath = file.path;
    });
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
