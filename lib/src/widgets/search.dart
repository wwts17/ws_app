import 'package:flutter/material.dart';
import '../car.dart';
import '../warehouse.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class CarSearchPage extends StatefulWidget {
  @override
  _CarSearchPageState createState() => _CarSearchPageState();
}

class _CarSearchPageState extends State<CarSearchPage>
    with SingleTickerProviderStateMixin {
  final _carRepo = CarRepository();
  final _whRepo = WarehouseRepository();
  final _textController= TextEditingController();
  String _vin = '';

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: TextField(
          controller: _textController,
          decoration: InputDecoration(
            icon: Icon(FontAwesomeIcons.search,color: Colors.white,),
            suffix:IconButton(icon: Icon(Icons.close),onPressed: (){
              _textController.text = '';
            },),
          ),
          onChanged: (input){
            setState(() {
              _vin = input;
            });
          },
        ),
        ),
      body: FutureBuilder<List<Car>>(
        future: _carRepo.searchVinLike(_vin),
        builder: (context,snap){
          if(snap.connectionState==ConnectionState.done&&snap.data!=null){
            List<Widget> widgets = List();
            widgets.add(Text('Total：${snap.data.length}',style: TextStyle(fontSize: 20.0),));
            for (int i=0;i<snap.data.length;i++) {
              widgets.add(Card(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: <Widget>[
                    Text('${i+1}/${snap.data.length}'),
                    Text('ID：${snap.data[i].id}'),
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
      ),
    );
  }


}
