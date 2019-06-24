import 'package:flutter/material.dart';
import '../car.dart';
import '../warehouse.dart';

class CarListView extends StatefulWidget {
  @override
  _CarListViewState createState() => _CarListViewState();
}

class _CarListViewState extends State<CarListView> with SingleTickerProviderStateMixin {
  AnimationController _controller;
  final _carRepo = CarRepository();
  final _whRepo = WarehouseRepository();

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
    return FutureBuilder<List<Car>>(
      future: _carRepo.all(),
      builder: (context,snap){
        if(snap.connectionState==ConnectionState.done&&snap.data!=null){
          List<Widget> widgets = List();
          widgets.add(Text('扫描总数：${snap.data.length}',style: TextStyle(fontSize: 20.0),));
          for (int i=0;i<snap.data.length;i++) {
            widgets.add(Card(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  Text('${i+1}/${snap.data.length}'),
                  //Text('ID：${snap.data[i].id}'),
                  Text('VIN码：${snap.data[i].vin}'),
                  FutureBuilder<Warehouse>(
                    future: _whRepo.queryById(snap.data[i].warehouseId),
                    builder: (context,snap2){
                      if(snap2.connectionState==ConnectionState.done){
                        return Text('仓库：${snap2.data.name}');
                      }else{
                        return Container();
                      }
                    },
                  ),
                  Text('道位：${snap.data[i].mark}'),
                  Text('序号：${snap.data[i].num}'),
                  Text('创建时间：${snap.data[i].createdAt}'),
                ],
              ),
            ));
          }
        return ListView(
          children: widgets,
        );
        }else{
          return Container();
        }
      },
    );
  }

}


