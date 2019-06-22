import 'package:flutter/material.dart';
import 'src/widgets/add_car.dart';
import 'src/widgets/add_warehouse.dart';
import 'src/widgets/carlist.dart';
import 'src/widgets/settings.dart';
import 'src/widgets/search.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '中集车辆',
      theme: ThemeData(
        primarySwatch: Colors.green,
      ),
      home: HomePage(),
    );
  }
}

class HomePage extends StatefulWidget {
  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage>
    with SingleTickerProviderStateMixin {
  AnimationController _controller;

  static final tabs = ["扫描", "数据"];
  int _currentIndex = 0;

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
        ],
      ),
      body: _buildPage(_currentIndex),
    );
  }

  List<Widget> _buildActions(int index){
    switch (index){
      case 0:
        return null;
      case 1:
        return [
        IconButton(
            icon: Icon(Icons.settings),
            onPressed: () {
              Navigator.of(context).push(MaterialPageRoute(builder: (context) {
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
              Navigator.of(context).push(MaterialPageRoute(builder: (context){
                return SearchPage();
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
      default:
        return AddCar();
    }
  }
}
