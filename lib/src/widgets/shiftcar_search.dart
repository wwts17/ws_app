import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

import '../shiftcar.dart';

class ShiftCarSearchPage extends StatefulWidget {
  @override
  _ShiftCarSearchPageState createState() => _ShiftCarSearchPageState();
}

class _ShiftCarSearchPageState extends State<ShiftCarSearchPage>  {
  final _shiftCarRepo= ShiftCarRepository();
  final _textController = TextEditingController();

  String _vin;

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
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
      body: FutureBuilder<List<ShiftCar>>(
        future: _shiftCarRepo.searchVinLike(_vin),
        builder: (context,snap){
          if(snap.connectionState==ConnectionState.done&&snap.data!=null){
          return ListView.builder(itemBuilder: (context,idx){
            return Card(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  Text('${idx+1}/${snap.data.length}'),
                  Text('VIN码:${snap.data[idx].vin}'),
                  Text('自编条码:${snap.data[idx].barCode}'),
                  Text('扫描时间:${snap.data[idx].createdAt}'),
                ],
              ),
            );
          },itemCount: snap.data.length,);
          }else{
            return Container();
          }
        },
      ),
    );
  }
}
