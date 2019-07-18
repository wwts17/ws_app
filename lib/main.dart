import 'package:flutter/material.dart';
import 'src/widgets/add_car.dart';
import 'src/widgets/add_warehouse.dart';
import 'src/widgets/carlist.dart';
import 'src/widgets/settings.dart';
import 'src/widgets/search.dart';
import 'src/widgets/search_file.dart';
import 'src/widgets/shiftcarpage.dart';
import 'src/widgets/shiftcar_search.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:io';
import 'package:spreadsheet_decoder/spreadsheet_decoder.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:audioplayers/audio_cache.dart';


import 'src/shiftcar.dart';

void main() {
  runApp(MyApp());
}

const _successAudio = 'success.mp3';
const _errorAudio = 'error.mp3';


class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '中集车辆',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: HomePage(),
    );
  }
}

class HomePage extends StatefulWidget {
  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final _pageController = PageController();
  static AudioCache _player = AudioCache();
  final _shiftCarRepo = ShiftCarRepository();
  static final tabs = ["扫描", "数据", "提车"];
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(tabs[_currentIndex]),
        leading: _buildLeading(_currentIndex),
        actions: _buildActions(_currentIndex),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        items: <BottomNavigationBarItem>[
          BottomNavigationBarItem(icon: Icon(Icons.add), title: Text(tabs[0])),
          BottomNavigationBarItem(
              icon: Icon(FontAwesomeIcons.database), title: Text(tabs[1])),
          BottomNavigationBarItem(
              icon: Icon(FontAwesomeIcons.car), title: Text(tabs[2])),
        ],
      ),
      body: _buildPage(_currentIndex),
    );
  }

  List<Widget> _buildActions(int index) {
    switch (index) {
      case 0:
        return null;
      case 1:
        return [
          IconButton(
              icon: Icon(FontAwesomeIcons.file),
              onPressed: () async {
                String path = await FilePicker.getFilePath();
                if (path == null || path.isEmpty) {
                  return null;
                }
                if (!path.contains('.xlsx')) {
                  return showDialog(
                    context: context,
                    builder: (context) {
                      return AlertDialog(
                        content: Text('仅支持xlsx文件',
                            style: TextStyle(color: Colors.red)),
                      );
                    },
                  );
                }
                Navigator.of(context)
                    .push(MaterialPageRoute(builder: (context) {
                  return FileSearch(
                    filePath: path,
                  );
                }));
              }),
          IconButton(
              icon: Icon(Icons.settings),
              onPressed: () {
                Navigator.of(context)
                    .push(MaterialPageRoute(builder: (context) {
                  return SettingPage();
                }));
              }),
        ];
      case 2:
        return [
          IconButton(
              icon: Icon(Icons.file_upload),
              onPressed: () async {
                String path = await FilePicker.getFilePath();
                if (path == null || path.isEmpty) {
                  return null;
                }
                if (!path.contains('.xlsx')) {
                 showDialog(
                    context: context,
                    builder: (context) {
                      return AlertDialog(
                        content: Text('仅支持xlsx文件',
                            style: TextStyle(color: Colors.red)),
                      );
                    },
                  );
                  _playMusic(_errorAudio);
                  return null;
                }
                await _requestPermissions();
                var bytes = File(path).readAsBytesSync();
                var decoder = new SpreadsheetDecoder.decodeBytes(bytes);
                var table = decoder.tables['Sheet1'];
                if(table==null){
                  showDialog(
                    context: context,
                    builder: (context) {
                      return AlertDialog(
                        content: Text('没有找到名为Sheet1的工作簿',
                            style: TextStyle(color: Colors.red)),
                      );
                    },
                  );
                  _playMusic(_errorAudio);
                  return null;
                }
                var columnName = table.rows[0];
                var vinIndex;
                for (int i = 0; i < columnName.length; i++) {
                  if(columnName[i]=='VIN码'){
                    vinIndex = i;
                  }
                }
                if (vinIndex!=null){
                  await _shiftCarRepo.clean();
                  for (int j = 1;j<table.maxRows;j++){
                    var _vinCode  =table.rows[j][vinIndex];
                    await _shiftCarRepo.save(ShiftCar(vin: _vinCode));
                  }
                }else{
                  showDialog(
                    context: context,
                    builder: (context) {
                      return AlertDialog(
                        content: Text('没有找到名为VIN的列',
                            style: TextStyle(color: Colors.red)),
                      );
                    },
                  );
                  _playMusic(_errorAudio);
                  return null;
                }
                setState(() {
                });
              }),
          IconButton(
              icon: Icon(Icons.settings),
              onPressed: () {
                Navigator.of(context)
                    .push(MaterialPageRoute(builder: (context) {
                  return SettingPage();
                }));
              }),
        ];

      default:
        return null;
    }
  }

  Widget _buildLeading(int index) {
    switch (index) {
      case 0:
        return IconButton(
            icon: Icon(Icons.add),
            onPressed: () {
              showDialog(
                context: context,
                builder: (context) {
                  return AddWarehouse();
                },
              );
            });
      case 1:
        return IconButton(
            icon: Icon(Icons.search),
            onPressed: () {
              Navigator.of(context).push(MaterialPageRoute(builder: (context) {
                return CarSearchPage();
              }));
            });
      case 2:
        return IconButton(
            icon: Icon(Icons.search),
            onPressed: () {
              Navigator.of(context).push(MaterialPageRoute(builder: (context) {
                return ShiftCarSearchPage();
              }));
            });
      default:
        return null;
    }
  }

  Widget _buildPage(int index) {
    switch (index) {
      case 0:
        return AddCar();
      case 1:
        return CarListView();
      case 2:
        return ShiftCarPage();
      default:
        return Scaffold();
    }
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

  Future<void> _playMusic(String name) async {
    await _player.play(name);
  }
}
