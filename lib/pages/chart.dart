import 'package:charts_flutter/flutter.dart' as charts;
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';

class Chart extends StatefulWidget {

  @override
  _ChartState createState() => _ChartState();
}

class _ChartState extends State<Chart> {
  late List<Registro> _data;
  late List<charts.Series<Registro,String>> _chardata;
  late DatabaseReference _dataref;

  void _makeData(){
    _chardata.add(
        charts.Series(
          domainFn: (Registro registro,_) =>
          registro.fecha + " "+ registro.hora,
          measureFn: (Registro registro,_) =>
          registro.temperatura,
          id: 'Registros',
          data: _data,

        )
    );
  }

  @override
  void initState(){
    final FirebaseDatabase database = FirebaseDatabase.instance;
    _dataref = database.reference().child("data");
    _data = <Registro>[];
    _chardata = <charts.Series<Registro, String>>[];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _buildBody(context),
    );
  }

  Widget _buildBody(context){
    return StreamBuilder(
        stream: _dataref.onValue,
        builder: (context,snapshot){
          print(snapshot.data);
          if(!snapshot.hasData){
            return LinearProgressIndicator();
          }else{
            List<Registro> registros = <Registro>[];
            Map data = (snapshot.data as dynamic).snapshot.value;
            for(Map childata in data.values){
              var fecha =
              childata["received_at"].toString();
              var temperatura =
              childata["uplink_message"]["decoded_payload"]["temperatura"].toString();
              var humedad =
              childata["uplink_message"]["decoded_payload"]["humedad"].toString();
              registros.add(Registro(fecha,temperatura,humedad
              ));
            }
            return _builChart(context,registros);
          }
        }
    );
  }

  Widget _builChart(BuildContext context, List<Registro> registros){
    _data = registros;
    _makeData();
    return Padding(
      padding: EdgeInsets.all(8.0),
      child: Container(
        child: Center(
          child: Column(
            children: <Widget>[
              Text("Diagrama de barras de temperaturas"),
              SizedBox(height: 10.0),
              Expanded(
                child: charts.BarChart(_chardata,
                  animate: true,
                  animationDuration: Duration(seconds: 1),
                  vertical: false,
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
}

class Registro{
  String fecha='';
  String hora='';
  double temperatura=0;
  double humedad=0;

  Registro(fecha,temperatura,humedad){
    this.fecha = fecha.split("T")[0];
    this.hora = fecha.split(".")[0].split("T")[1];
    this.temperatura = double.parse(temperatura);
    this.humedad = double.parse(humedad);
  }
}