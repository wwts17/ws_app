import 'dart:io';
import 'package:flutter/material.dart';

import 'package:spreadsheet_decoder/spreadsheet_decoder.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class FileSearch extends StatefulWidget {
  final String filePath;
  FileSearch({Key key, @required this.filePath}) : super(key: key);
  @override
  _FileSearchState createState() => _FileSearchState(filePath: filePath);
}

class _FileSearchState extends State<FileSearch>
    with SingleTickerProviderStateMixin {
  final _textController = TextEditingController();
  static List<Map<String, dynamic>> maps;
  AnimationController _controller;
  final String filePath;

  _FileSearchState({@required this.filePath});

  @override
  void initState() {
    maps = _inputData(filePath);
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
    return Scaffold(
        appBar: AppBar(
          title: TextField(
            decoration: InputDecoration(
              icon: Icon(
                FontAwesomeIcons.search,
                color: Colors.white,
              ),
              suffix: IconButton(
                icon: Icon(Icons.close),
                onPressed: () {
                  _textController.text = '';
                },
              ),
            ),
          ),
        ),
        body: ListView(
          children: _buildView(maps),
        ));
  }

  List<Widget> _buildView(List<Map<String, dynamic>> maps) {
    List<Widget> fin = [];
    fin.add(Text('总数:${maps.length}',style:TextStyle(fontSize: 20.0,fontWeight: FontWeight.w500)));
    var keys = maps[0].keys.toList();
    for (int i = 0; i < maps.length; i++) {
      var column = maps[i];
      List<Widget> texts = List();
      for (int j = 0; j < keys.length; j++) {
        var txt = column[keys[j]];
        texts.add(Text('${keys[j]}:${txt !=null ? txt : 'empty'}'));
      }
      fin.add(Card(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: texts,
        ),
      ));
    }
    return fin;
  }

  List<Map<String, dynamic>> _inputData(String path) {
    List<Map<String, dynamic>> cars = List();
    var bytes = File(path).readAsBytesSync();
    var decoder = new SpreadsheetDecoder.decodeBytes(bytes);
    var table = decoder.tables['Sheet1'];
    var columnName = table.rows[0];
    for (int i = 1; i < table.rows.length; i++) {
      var row = table.rows[i];
      Map<String, dynamic> gen = {};
      for (int j = 0; j < columnName.length; j++) {
        gen[columnName[j]] = row[j];
      }
      cars.add(gen);
    }
    return cars;
  }
}
