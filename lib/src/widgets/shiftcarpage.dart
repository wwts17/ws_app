import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:audioplayers/audio_cache.dart';

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

  static AudioCache _player = AudioCache();

  String _vin, _barCode;

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
                        ),
                      )),
                  Padding(
                    padding: EdgeInsets.symmetric(vertical: 12.0),
                    child: TextFormField(
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

  Future<void> _playMusic(String name) async {
    await _player.play(name);
  }
}
