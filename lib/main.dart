// Copyright 2017, Paul DeMarco.
// All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_blue/flutter_blue.dart';
import './widgets.dart';

void main() {
  runApp(FlutterBlueApp());
}

class FlutterBlueApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      color: Colors.lightBlue,
      home: StreamBuilder<BluetoothState>(
          stream: FlutterBlue.instance.state,
          initialData: BluetoothState.unknown,
          builder: (c, snapshot) {
            final state = snapshot.data;
            if (state == BluetoothState.on) {
              return FindDevicesScreen();
            }
            return BluetoothOffScreen(state);
          }),
    );
  }
}

class BluetoothOffScreen extends StatefulWidget {
  final BluetoothState state;
  const BluetoothOffScreen(this.state, {Key key}) : super(key: key);


  @override
  BluetoothOffScreenState createState(){
    return BluetoothOffScreenState(this.state);
  }

}

class BluetoothOffScreenState extends State<BluetoothOffScreen>{

  final BluetoothState state;

  BluetoothOffScreenState(this.state);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.lightBlue,
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Icon(
              Icons.bluetooth_disabled,
              size: 200.0,
              color: Colors.white54,
            ),
            Text(
              'Bluetooth Adapter is ${state != null ? state.toString().substring(15) : 'not available'}.',
              style: Theme.of(context)
                  .primaryTextTheme
                  .subhead
                  .copyWith(color: Colors.white),
            ),
          ],
        ),
      ),
    );
  }
}

class FindDevicesScreen extends StatefulWidget {
  FindDevicesScreen({Key key}) : super(key:key);

  @override
  FindDevicesScreenState createState() {
    return FindDevicesScreenState();
  }
}


class FindDevicesScreenState extends State<FindDevicesScreen>{

  FindDevicesScreenState();


  @override
  void initState(){
    bool isHere = false;
    ScanResult r;
    FlutterBlue.instance.startScan(timeout: Duration(seconds: 2));
    /*var subscription = FlutterBlue.instance.scanResults.listen((results) {
      for(r in results){
        if(r.device.name ==('Nordic_UART')){
          isHere=true;

        }
    }
      if(isHere == true){
       /// r.device.connect(); Pas fou parce qu'il essaie de se connecer à tous
        ///Les devices dispos !
        print("Connected to nordic from init");
      }
    });*/
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Find Devices'),
      ),
      body: RefreshIndicator(
        onRefresh: () =>
            FlutterBlue.instance.startScan(timeout: Duration(seconds: 4)),
        child: SingleChildScrollView(
          child: Column(
            children: <Widget>[
              StreamBuilder<List<BluetoothDevice>>(
                stream: Stream.periodic(Duration(seconds: 2))
                    .asyncMap((_) => FlutterBlue.instance.connectedDevices),
                initialData: [],
                builder: (c, snapshot) => Column(
                  children: snapshot.data
                      .map((d) => ListTile(
                    title: Text((() { // A placer quand la liste est crée apparemment, parce que ça s'éxécute quand je cliques sur Nordic.
                      /*if(d.name == 'Nordic_UART'){
                        print("Found a nordic !");
                        d.connect();
                        Navigator.of(context).push(
                            MaterialPageRoute(
                                builder: (context) =>
                                    DeviceScreen(d)));
                      }
                      else{
                        print("Nordic not found");
                      }*/
                      ///Le fait de mettre un navigator empeche de revenir sur la page
                      ///de connexion, ça sera peut etre intérréssant !
                      return d.name;
                    } ())),


                    subtitle: Text(d.id.toString()),
                    trailing: StreamBuilder<BluetoothDeviceState>(
                      stream: d.state,
                      initialData: BluetoothDeviceState.disconnected,
                      builder: (c, snapshot) {
                        if (snapshot.data ==
                            BluetoothDeviceState.connected) {
                          return RaisedButton(
                            child: Text('OPEN'),
                            onPressed: () => Navigator.of(context).push(
                                MaterialPageRoute(
                                    builder: (context) =>
                                        DeviceScreen(d))),
                          );
                        }


                        return Text(snapshot.data.toString());
                      },
                    ),
                  ))
                      .toList(),
                ),
              ),
              StreamBuilder<List<ScanResult>>(
                stream: FlutterBlue.instance.scanResults,
                initialData: [],
                builder: (c, snapshot) => Column(
                  children: snapshot.data
                      .map(
                        (r) => ScanResultTile(
                      result: r,
                      onTap: () => Navigator.of(context)
                          .push(MaterialPageRoute(builder: (context) {
                        r.device.connect(autoConnect: true);
                        return DeviceScreen(r.device);
                      })),
                    ),
                  )
                      .toList(),
                ),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: StreamBuilder<bool>(
        stream: FlutterBlue.instance.isScanning,
        initialData: false,
        builder: (c, snapshot) {
          if (snapshot.data) {
            return FloatingActionButton(
              child: Icon(Icons.stop),
              onPressed: () => FlutterBlue.instance.stopScan(),
              backgroundColor: Colors.red,
            );
          } else {
            return FloatingActionButton(
                child: Icon(Icons.search),
                onPressed: () => FlutterBlue.instance
                    .startScan(timeout: Duration(seconds: 4)));
          }
        },
      ),
    );
  }
}

class DeviceScreen extends StatefulWidget {
  BluetoothDevice device;
  DeviceScreen(this.device,{Key key}) : super(key: key);


  @override
  DeviceScreenState createState(){
    return DeviceScreenState(this.device);
  }

}

class DeviceScreenState extends State<DeviceScreen>{
  final BluetoothDevice device;
  String mydata="";
  BluetoothCharacteristic characteristic;

  DeviceScreenState(this.device);

  List<int> _getRandomBytes() { //Permet de choisir ce qu'on envoie a la carte.
    final math = Random();
    return [
      104,
      104,
      104,
      104
    ];
  }


@override //S'éxécute au lancement de la page
void initState() {
device.discoverServices();
//characteristic.setNotifyValue(true);
super.initState();
}

@override
void dispose(){ //A voir si on a besoin de fermer des streams ici par exemple
  super.dispose();
}
  //Construction des services avec boutons quand t'es connecte.
  List<Widget> _buildServiceTiles(List<BluetoothService> services) {
    return services
        .map(
          (s) => ServiceTile(
        service: s,

        characteristicTiles: s.characteristics
            .map(
              (c) => CharacteristicTile( //Quand tu cliques ça éxécute ça !
            characteristic: c,
          ),
        )
            .toList(),
      ),
    )
        .toList();
  }

  @override
  Widget build(BuildContext context) {


    return Scaffold(
      appBar: AppBar(
        title: Text(device.name),
        actions: <Widget>[
          StreamBuilder<BluetoothDeviceState>(
            stream: device.state,
            initialData: BluetoothDeviceState.connecting,
            builder: (c, snapshot) {
              VoidCallback onPressed;
              String text;
              switch (snapshot.data) {
                case BluetoothDeviceState.connected:
                  onPressed = () => device.disconnect();
                  text = 'DISCONNECT';
                  break;
                case BluetoothDeviceState.disconnected:
                  onPressed = () => device.connect(autoConnect: true); //A voir si ça fait connexion automatique ou pas
                  text = 'CONNECT';
                  break;
                default:
                  onPressed = null;
                  text = snapshot.data.toString().substring(21).toUpperCase();
                  break;
              }
              return FlatButton(
                  onPressed: onPressed,
                  child: Text(
                    text,
                    style: Theme.of(context)
                        .primaryTextTheme
                        .button
                        .copyWith(color: Colors.white),
                  ));
            },
          )
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: <Widget>[
            StreamBuilder<BluetoothDeviceState>(
              stream: device.state,
              initialData: BluetoothDeviceState.connecting,
              builder: (c, snapshot) => ListTile(
                leading: (snapshot.data == BluetoothDeviceState.connected)
                    ? Icon(Icons.bluetooth_connected)
                    : Icon(Icons.bluetooth_disabled),
                title: Text(
                    'Device is ${snapshot.data.toString().split('.')[1]}.'),
                subtitle: Text('${device.id}'),
                trailing: StreamBuilder<bool>(
                  stream: device.isDiscoveringServices,
                  initialData: false,
                  builder: (c, snapshot) => IndexedStack(
                    index: snapshot.data ? 1 : 0,
                    children: <Widget>[
                      IconButton(
                        icon: Icon(Icons.refresh),
                        onPressed: () => device.discoverServices(),
                        //La flèche a coté du nom, qui affiche les services
                      ),

                    ],
                  ),
                ),
              ),
            ),
            StreamBuilder<int>(
              stream: device.mtu,
              initialData: 0,
              builder: (c, snapshot) => ListTile(
                title: Text('MTU Size'),
                subtitle: Text('${snapshot.data} bytes'),
                trailing: IconButton(
                  icon: Icon(Icons.edit),
                  onPressed: () => device.requestMtu(223),
                  //TODO: Regarder ce qu'est le MTU : ici on lui donne une taille 223.
                ),
              ),
            ),
            TextFormField(
              decoration: InputDecoration(
                labelText: 'Entre des datas'
              ),
              onChanged: (text){
                mydata=text;

              },
            ),
            StreamBuilder<List<BluetoothService>>(
              stream: device.services,
              initialData: [],
              builder: (c, snapshot) {
                return Column(
                  children: _buildServiceTiles(snapshot.data),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}