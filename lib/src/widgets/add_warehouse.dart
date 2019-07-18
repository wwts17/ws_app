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
  final _whRepo = WarehouseRepository();
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
              child:Column(
                children: <Widget>[
                  TextFormField(
                    enableInteractiveSelection: false,
                    validator: (input){
                      // input only word, number, _
                      var r= RegExp(r'[\u4e00-\u9fa5\w]+$');
                      if(input==null||!r.hasMatch(input)){
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
                  )
                ],
              ),
          ),
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
                    var result = await _whRepo.queryByName(_name);
                    if (result==null){
                      await _whRepo.save(Warehouse(name: _name));
                    }
                    Navigator.of(context).pop(true);
                  }
                },
                child: Text('提交'),
              ),
              Padding(
              padding: EdgeInsets.symmetric(horizontal: 8.0),
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
