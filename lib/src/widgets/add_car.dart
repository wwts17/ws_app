import 'dart:async';
import 'package:flutter/material.dart';
import 'package:barcode_scan/barcode_scan.dart';
import 'package:flutter/services.dart';
import 'package:audioplayers/audio_cache.dart';
import '../warehouse.dart';
import '../car.dart';

final saveSate = Map<String, dynamic>();

class AddCar extends StatefulWidget {
  @override
  _AddCarState createState() => _AddCarState();
}

const _successAudio = 'success.mp3';
const _errorAudio = 'error.mp3';

class _AddCarState extends State<AddCar> with SingleTickerProviderStateMixin {
  AnimationController _controller;

  FocusNode _focusNode;
  FocusNode _focusNode2;
  static AudioCache _player = AudioCache();
  final _whRepo = WarehouseRepository();
  final _carRepo = CarRepository();
  final _textController = TextEditingController();
  final _textController2 = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _fieldState = saveSate["warehouse"] != null ?? false;
  String _scanResult = '';
  int _selected = saveSate["warehouse"] ?? null;
  String _mark = saveSate["mark"] ?? null;
  String _vin;
  static List<Car> latest = [];

  @override
  void initState() {
    _focusNode = FocusNode();
    _focusNode2 = FocusNode();
    loadData();
    _controller = AnimationController(vsync: this);

    _textController2.text = saveSate["mark"];
    _textController.addListener(() async{
      if (_textController.text.length!=0) {
        await _submit();
        FocusScope.of(context).requestFocus(_focusNode2);
      }
    });
    super.initState();
  }

  loadData() async {
    await _player.load(_successAudio);
    await _player.load(_errorAudio);
  }

  @override
  void dispose() {
    _textController2.dispose();
    _textController.dispose();
    _controller.dispose();
    _focusNode2.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      children: [
        _buildForm(),
        Padding(
          padding: EdgeInsets.only(top: 20.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: <Widget>[
              Row(
                children: <Widget>[
                  Text(
                    '最近',
                    style:
                        TextStyle(fontSize: 20.0, fontWeight: FontWeight.w500),
                  ),
                  Icon(
                    Icons.access_time,
                    size: 26.0,
                  ),
                ],
              ),
              Text('扫描数量：${latest.length}')
            ],
          ),
        ),
        Column(
          children: latest
              .map((f) => Card(
                      child: Container(
                          child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: <Widget>[
                      Text('VIN码:${f.vin}'),
                      FutureBuilder<Warehouse>(
                        future: _whRepo.queryById(f.warehouseId),
                        builder: (context, snap2) {
                          if (snap2.connectionState == ConnectionState.done) {
                            return Text('仓库：${snap2.data.name}');
                          } else {
                            return Container();
                          }
                        },
                      ),
                      Text('道位：${f.mark}'),
                      Text('序号：${f.num}'),
                    ],
                  ))))
              .toList(),
        ),
      ],
    );
  }

  Widget _buildForm() {
    return Form(
      key: _formKey,
      child: Column(
        children: <Widget>[
          Padding(
            padding: EdgeInsets.symmetric(vertical: 12.0),
            child: FutureBuilder<List<Warehouse>>(
              future: _whRepo.all(),
              builder: (context, snap) {
                if (snap.connectionState == ConnectionState.done &&
                    snap.data != null &&
                    snap.data.isNotEmpty) {
                  return DropdownButtonFormField<int>(
                    onChanged: (value) {
                      setState(() {
                        _selected = value;
                        saveSate["warehouse"] = value;
                        _fieldState = true;
                      });
                    },
                    validator: (input) {
                      if (input == null || input == 0) {
                        return '请选择仓库';
                      }
                    },
                    value: _selected ?? saveSate["warehouse"],
                    decoration: InputDecoration(
                      labelText: '仓库',
                      icon: Icon(Icons.storage),
                    ),
                    items: snap.data
                        .map((m) =>
                            DropdownMenuItem(value: m.id, child: Text(m.name)))
                        .toList(),
                  );
                } else {
                  return Container();
                }
              },
            ),
          ),
          Padding(
            padding: EdgeInsets.symmetric(vertical: 12.0),
            child: TextFormField(
              enableInteractiveSelection: false,
              controller: _textController,
              focusNode: _focusNode,
              autofocus: _fieldState,
              enabled: _fieldState,
              validator: (input) {
                var r = RegExp(r'^[A-Za-z0-9]{17}$');
                if (input.isEmpty || !r.hasMatch(input)) {
                  return '请输入由数字和字母组成的17位识别码';
                }
                return null;
              },
              onSaved: (input) => _vin = input,
              decoration: InputDecoration(
                labelText: 'VIN码',
                icon: Icon(Icons.code),
                suffixIcon: IconButton(
                  icon: Icon(Icons.camera_alt),
                  onPressed: () async {
                    await scan();
                    setState(() {
                      _textController.text = _scanResult;
                    });
                    _submit();
                  },
                ),
              ),
            ),
          ),
          Padding(
            padding: EdgeInsets.symmetric(vertical: 12.0),
            child: TextFormField(
              enableInteractiveSelection: false,
              controller: _textController2,
              enabled: _fieldState,
              focusNode: _focusNode2,
              validator: (input) {
                var r = RegExp(r'[\u4e00-\u9fa5\w@]+$');
                if (input.isEmpty || !r.hasMatch(input)) {
                  return '请输入道位';
                }
                return null;
              },
              onSaved: (input) {
                _mark = input;
                saveSate["mark"] = input;
              },
              decoration: InputDecoration(
                labelText: '道位',
                icon: Icon(Icons.room),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _submit() async {
    if (_formKey.currentState.validate()) {
      _formKey.currentState.save();
      int _num = await _carRepo.count(_selected, _mark);
      Car _add =
          Car(warehouseId: _selected, vin: _vin, mark: _mark, num: _num + 1);
      int result = await _carRepo.save(_add);
      if (result > 0) {
        await _playMusic(_successAudio);
        setState(() {
          latest.add(_add);
          _textController.text = '';
        });
      } else if (result == -1) {
        await _playMusic(_errorAudio);
        showDialog(
          context: context,
          builder: (context) {
            return AlertDialog(
              content: Text(
                '错误提示：重复的VIN码',
                style: TextStyle(color: Colors.red),
              ),
            );
          },
        );
        _textController.text = '';
      }
    }
  }

  Future scan() async {
    try {
      String barcode = await BarcodeScanner.scan();
      setState(() => this._scanResult = barcode);
    } on PlatformException catch (e) {
      if (e.code == BarcodeScanner.CameraAccessDenied) {
        setState(() {
          this._scanResult = 'The user did not grant the camera permission!';
        });
      } else {
        setState(() => this._scanResult = 'Unknown error: $e');
      }
    } on FormatException {
      setState(() => this._scanResult =
          'null (User returned using the "back"-button before scanning anything. Result)');
    } catch (e) {
      setState(() => this._scanResult = 'Unknown error: $e');
    }
  }

  Future<void> _playMusic(String name) async {
    await _player.play(name);
  }
}
