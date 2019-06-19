import 'dart:async';
import 'package:flutter/material.dart';
import 'package:barcode_scan/barcode_scan.dart';
import 'package:flutter/services.dart';
import '../warehouse.dart';
import '../car.dart';

class AddCar extends StatefulWidget {
  @override
  _AddCarState createState() => _AddCarState();
}

class _AddCarState extends State<AddCar> with SingleTickerProviderStateMixin {
  AnimationController _controller;

  final _whRepo = WarehouseRepository();
  final carRepo = CarRepository();
  final _textController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _fieldState = false;
  String _barcode = '';
  int _selected,_num;
  String _mark,_vin;

  @override
  void initState() {
    _controller = AnimationController(vsync: this);
    super.initState();
  }

  @override
  void dispose() {
    _textController.dispose();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.all(10.0),
      child: ListView(children: [
        Form(
          key: _formKey,
          child: Column(
            children: <Widget>[
              Padding(
                padding: EdgeInsets.symmetric(vertical: 12.0),
                child: FutureBuilder<List<Warehouse>>(
                  future: _whRepo.all(),
                  builder: (context, snap) {
                    if (snap.connectionState == ConnectionState.done &&
                        snap.data != null && snap.data.isNotEmpty) {
                      return DropdownButtonFormField(
                        onChanged: (value) {
                          print(value);
                          setState(() {
                            _selected = value;
                            _fieldState = true;
                          });
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
                  validator: (input){
                    var r= RegExp(r'^[A-Za-z0-9]{17}$');
                    if(!r.hasMatch(input)){
                      return '请输入由数字和字母组成的17位识别码';
                    }
                    return null;
                  },
                  onSaved: (input)=>_vin = input,
                  decoration: InputDecoration(
                    labelText: '车辆识别码',
                    icon: Icon(Icons.code),
                    suffixIcon: IconButton(
                      icon: Icon(Icons.camera_alt),
                      onPressed: () async {
                        await scan();
                        setState(() {
                          _textController.text = _barcode;
                        });
                      },
                    ),
                  ),
                ),
              ),
              Padding(
                padding: EdgeInsets.symmetric(vertical: 12.0),
                child: TextFormField(
                  enabled: _fieldState,
                  validator: (input){
                    var r= RegExp(r'[\u4e00-\u9fa5\w]+$');
                    if(!r.hasMatch(input)){
                      return '请输入标识';
                    }
                    return null;
                  },
                  onSaved: (input)=>_mark = input,
                  decoration: InputDecoration(
                    labelText: '标识',
                    icon: Icon(Icons.room),
                  ),
                ),
              ),
              Padding(
                padding: EdgeInsets.symmetric(vertical: 12.0),
                child: TextFormField(
                  enabled: _fieldState,
                  validator: (input){
                    var r= RegExp(r'\d+$');
                    if(!r.hasMatch(input)){
                      return '请输入数字序号';
                    }
                    return null;
                  },
                  onSaved: (input)=>_num = int.parse(input),
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: '序号',
                    icon: Icon(Icons.confirmation_number),
                  ),
                ),
              ),
              Padding(
                padding: EdgeInsets.symmetric(vertical: 24.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: <Widget>[
                    RaisedButton(
                      onPressed: _submit,
                      child: const Text('提交'),
                    ),
                    Padding(
                      padding: EdgeInsets.all(10.0),
                    ),
                    RaisedButton(
                      onPressed: _cancel,
                      child: const Text('取消'),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: EdgeInsets.symmetric(vertical: 20.0),
                child: RaisedButton(child: Text('清除数据'),onPressed: () async{
                  await _whRepo.clean();
                }),
              )
            ],
          ),
        ),
      ]),
    );
  }

  void _submit() async{
    if (_formKey.currentState.validate()) {
      _formKey.currentState.save();
      await carRepo.save(Car(warehouseId: _selected,vin: _vin,mark: _mark,num: _num));
      print("----------------------->${carRepo.all()}");
    }
  }

  void _cancel() {
    setState(() {
      _formKey.currentState.reset();
      _textController.text = '';
      _selected = null;
      _fieldState = false;
    });
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
}
