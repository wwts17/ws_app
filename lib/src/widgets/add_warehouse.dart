import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../warehouse.dart';

class AddWarehouse extends StatefulWidget {
  @override
  _AddWarehouseState createState() => _AddWarehouseState();
}

class _AddWarehouseState extends State<AddWarehouse>
    with SingleTickerProviderStateMixin {
  AnimationController _controller;
  final _formKer = GlobalKey<FormState>();
  final whRepo = WarehouseRepository();
  String _name;


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
    return SimpleDialog(
      title: Text('新增仓库'),
      children: <Widget>[
        Padding(
          padding: EdgeInsets.all(8.0),
          child: Form(
              key: _formKer,
              child: TextFormField(
                validator: (input) {
                  // input only word, number, _
                  var r= RegExp(r'[\u4e00-\u9fa5\w]+$');
                  if(!r.hasMatch(input)){
                    return '请输入正确仓库名';
                  }
                  return null;
                },
                onSaved: (input) {
                  setState(() {
                    _name = input;
                  });
                },
                decoration: InputDecoration(
                  icon: Icon(FontAwesomeIcons.warehouse),
                  labelText: '仓库名',
                ),
              )),
        ),
        Padding(
          padding: EdgeInsets.symmetric(vertical: 20.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: <Widget>[
              RaisedButton(
                onPressed: () async {
                  if (_formKer.currentState.validate()) {
                    _formKer.currentState.save();
                    await whRepo.save(Warehouse(name: _name));
                  }
                },
                child: Text('提交'),
              ),
              RaisedButton(
                onPressed: () {
                  Navigator.pop(context);
                },
                child: Text('取消'),
              )
            ],
          ),
        )
      ],
    );
  }
}
