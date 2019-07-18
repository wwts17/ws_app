import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:audioplayers/audio_cache.dart';
import 'package:barcode_scan/barcode_scan.dart';
import 'package:flutter/services.dart';

import '../shiftcar.dart';

const _successAudio = 'success.mp3';
const _errorAudio = 'error.mp3';

class ShiftCarPage extends StatefulWidget {
  @override
  _ShiftCarPageState createState() => _ShiftCarPageState();
}

class _ShiftCarPageState extends State<ShiftCarPage> {
  final _shiftCarRepo = ShiftCarRepository();
  final _pageController = PageController();
  final _formKey = GlobalKey<FormState>();
  final _vinTextController = TextEditingController();
  final _barCodeTextController = TextEditingController();

  static AudioCache _player = AudioCache();

  String _vin, _barCode, _scanResult;

  @override
  void initState() {
    super.initState();
  }

  loadData() async {
    await _player.load(_successAudio);
    await _player.load(_errorAudio);
  }

  @override
  void dispose() {
    _vinTextController.dispose();
    _barCodeTextController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PageView(
      controller: _pageController,
      children: <Widget>[
        ListView(
          children: <Widget>[
            Form(
              key: _formKey,
              child: Column(
                children: <Widget>[
                  Padding(
                      padding: EdgeInsets.symmetric(vertical: 12.0),
                      child: TextFormField(
                        controller: _vinTextController,
                        validator: (input) {
                          var r = RegExp(r'^[A-Za-z0-9]{17}$');
                          if (input.isEmpty || !r.hasMatch(input)) {
                            return '请输入由数字和字母组成的17位识别码';
                          }
                          return null;
                        },
                        onSaved: (input) => _vin = input,
                        decoration: InputDecoration(
                          icon: Icon(FontAwesomeIcons.code),
                          labelText: 'VIN码',
                          suffixIcon: IconButton(
                            icon: Icon(Icons.camera_alt),
                            onPressed: () async {
                              await scan();
                              setState(() {
                                _vinTextController.text = _scanResult;
                              });
                              _submit();
                            },
                          ),
                        ),
                      )),
                  Padding(
                    padding: EdgeInsets.symmetric(vertical: 12.0),
                    child: TextFormField(
                      controller: _barCodeTextController,
                      validator: (input) {
                        if (input.isEmpty) {
                          return "请输入自编条码";
                        }
                        return null;
                      },
                      onSaved: (input) => _barCode = input,
                      decoration: InputDecoration(
                        icon: Icon(FontAwesomeIcons.barcode),
                        labelText: '自编条码',
                        suffixIcon: IconButton(
                          icon: Icon(Icons.camera_alt),
                          onPressed: () async {
                            await scan();
                            setState(() {
                              _barCodeTextController.text = _scanResult;
                            });
                            _submit();
                          },
                        ),
                      ),
                    ),
                  ),
                  RaisedButton(
                    onPressed: () async {
                      if (_formKey.currentState.validate()) {
                        _formKey.currentState.save();
                        var result = await _shiftCarRepo
                            .save(ShiftCar(vin: _vin, barCode: _barCode));
                        if (result > 0) {
                          _playMusic(_successAudio);
                          setState(() {});
                        }
                      }
                    },
                    child: Text('提交'),
                  ),
                ],
              ),
            )
          ],
        ),
        Container(
          child: FutureBuilder<List<ShiftCar>>(
              future: _shiftCarRepo.all(),
              builder: (context, snap) {
                if (snap.connectionState == ConnectionState.done &&
                    snap.data != null &&
                    snap.data.isNotEmpty) {
                  return ListView.builder(
                    itemBuilder: (context, idx) {
                      return Card(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: <Widget>[
                            Text('${idx + 1}/${snap.data.length}'),
                            Text('VIN码:${snap.data[idx].vin}'),
                            Text('自编条码:${snap.data[idx].barCode}'),
                            Text('扫描时间:${snap.data[idx].createdAt}'),
                          ],
                        ),
                      );
                    },
                    itemCount: snap.data.length,
                  );
                } else {
                  return Container();
                }
              }),
        )
      ],
    );
  }

  void _submit() async {
    if (_formKey.currentState.validate()) {
      _formKey.currentState.save();
      var sc = await _shiftCarRepo.findByVin(_vin);
      if (sc==null){
        showDialog(
          context: context,
          builder: (context) {
            return AlertDialog(
              content: Text('没有此VIN码',
                  style: TextStyle(color: Colors.red)),
            );
          },
        );
        _playMusic(_errorAudio);
        return null;
      }
      var result =
          await _shiftCarRepo.save(ShiftCar(id:sc.id,vin: sc.vin, barCode: _barCode));
      if (result > 0) {
        await _playMusic(_successAudio);
      } else if (result == -1) {
        await _playMusic(_errorAudio);
        return showDialog(
          context: context,
          builder: (context) {
            return AlertDialog(
              content: Text(
                '添加失败',
                style: TextStyle(color: Colors.red),
              ),
            );
          },
        );
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
