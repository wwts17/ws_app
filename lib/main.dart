import 'package:flutter/material.dart';
import 'src/widgets/add_car.dart';
import 'src/widgets/add_warehouse.dart';
import 'src/widgets/carlist.dart';

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

  static final tabs = ["扫描", "查询"];
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
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index){
          setState(() {
            _currentIndex = index;
          });
        },
        items: <BottomNavigationBarItem>[
          BottomNavigationBarItem(icon: Icon(Icons.add), title: Text(tabs[0])),
          BottomNavigationBarItem(
              icon: Icon(Icons.search), title: Text(tabs[1])),
        ],
      ),
      body: _buildPage(_currentIndex),
    );
  }

  Widget _buildLeading(int index) {
    switch (index){
      case 0:
        return IconButton(icon: Icon(Icons.add), onPressed: (){
          showDialog(
              context: context,
              builder: (context){
                return AddWarehouse();
              },
          );
        });
      case 1:
        return IconButton(icon:Icon(Icons.settings) , onPressed: null);
      default:
        return null;
    }
  }

  Widget _buildPage(int index) {
    switch (index){
      case 0:
        return AddCar();
      case 1:
        return CarListView();
      default:
        return AddCar();
    }
  }
}
