import 'dart:async';
import 'package:flutter/material.dart';
import 'package:barcode_scan/barcode_scan.dart';
import 'package:flutter/services.dart';
import 'package:audioplayers/audio_cache.dart';
import '../warehouse.dart';
import '../car.dart';

class AddCar extends StatefulWidget {
  @override
  _AddCarState createState() => _AddCarState();
}

const _successAudio = 'success.mp3';

class _AddCarState extends State<AddCar> with SingleTickerProviderStateMixin {
  AnimationController _controller;

  static AudioCache _player = AudioCache();
  final _whRepo = WarehouseRepository();
  final _carRepo = CarRepository();
  final _textController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _fieldState = false;
  String _barcode = '';
  int _selected;
  String _mark, _vin;
  static List<Car> latest = [];

  @override
  void initState() {
    loadData();
    _controller = AnimationController(vsync: this);
    super.initState();
  }

  loadData() async {
    await _player.load(_successAudio);
  }

  @override
  void dispose() {
    _textController.dispose();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return  ListView(
                children:[
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
                        style: TextStyle(fontSize: 20.0, fontWeight: FontWeight.w500),
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
                      .map((f) =>Card(
                      child: Container(
                          child:Column(
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
                      )))).toList(),
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
                        print(value);
                        setState(() {
                          _selected = value;
                          _fieldState = true;
                        });
                      },
                      validator: (input) {
                        if (input == null || input == 0) {
                          return '请选择仓库';
                        }
                      },
                      value: _selected,
                      decoration: InputDecoration(
                        labelText: '仓库',
                        icon: Icon(Icons.storage),
                      ),
                      items: snap.data
                          .map((m) => DropdownMenuItem(
                              value: m.id, child: Text(m.name)))
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
                controller: _textController,
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
                        _textController.text = _barcode;
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
                enabled: _fieldState,
                validator: (input) {
                  var r = RegExp(r'[\u4e00-\u9fa5\w@]+$');
                  if (input.isEmpty || !r.hasMatch(input)) {
                    return '请输入道位';
                  }
                  return null;
                },
                onSaved: (input) => _mark = input,
                decoration: InputDecoration(
                  labelText: '道位',
                  icon: Icon(Icons.room),
                ),
              ),
            ),
//              Padding(
//                padding: EdgeInsets.symmetric(vertical: 12.0),
//                child: TextFormField(
//                  enabled: _fieldState,
//                  validator: (input){
//                    var r= RegExp(r'\d+$');
//                    if(!r.hasMatch(input)){
//                      return '请输入数字序号';
//                    }
//                    return null;
//                  },
//                  onSaved: (input)=>_num = int.parse(input),
//                  keyboardType: TextInputType.number,
//                  decoration: InputDecoration(
//                    labelText: '序号',
//                    icon: Icon(Icons.confirmation_number),
//                  ),
//                ),
//              ),
          ],
        ),
      );
  }

  void _submit() async {
    if (_formKey.currentState.validate()) {
      _formKey.currentState.save();
      int _num = await _carRepo.count(_selected, _mark);
      Car _add =
          Car(warehouseId: _selected, vin: _vin, mark: _mark, num: _num + 1);
      int result = await _carRepo.save(_add);
      if (result > 0) {
        await playMusic();
      }
      setState(() {
        latest.add(_add);
      });
    }
  }

  Future scan() async {
    try {
      String barcode = await BarcodeScanner.scan();
      setState(() => this._barcode = barcode);
    } on PlatformException catch (e) {
      if (e.code == BarcodeScanner.CameraAccessDenied) {
        setState(() {
          this._barcode = 'The user did not grant the camera permission!';
        });
      } else {
        setState(() => this._barcode = 'Unknown error: $e');
      }
    } on FormatException {
      setState(() => this._barcode =
          'null (User returned using the "back"-button before scanning anything. Result)');
    } catch (e) {
      setState(() => this._barcode = 'Unknown error: $e');
    }
  }

  Future<void> playMusic() async {
    await _player.play(_successAudio);
  }
}
