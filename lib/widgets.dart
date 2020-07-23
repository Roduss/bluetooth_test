// Copyright 2017, Paul DeMarco.
// All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:flutter_blue/flutter_blue.dart';

class ScanResultTile extends StatelessWidget {
  const ScanResultTile({Key key, this.result, this.onTap}) : super(key: key);

  final ScanResult result;
  final VoidCallback onTap;

  @override
  void initState(){

  }

  Widget _buildTitle(BuildContext context) {
    if (result.device.name.length > 0) {
      return Column(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            result.device.name,
            overflow: TextOverflow.ellipsis,
          ),
          Text(
            result.device.id.toString(),
            style: Theme.of(context).textTheme.caption,
          )
        ],
      );
    } else {
      return Text(result.device.id.toString());
    }
  }

  Widget _buildAdvRow(BuildContext context, String title, String value) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(title, style: Theme.of(context).textTheme.caption),
          SizedBox(
            width: 12.0,
          ),
          Expanded(
            child: Text(
              value,
              style: Theme.of(context)
                  .textTheme
                  .caption
                  .apply(color: Colors.black),
              softWrap: true,
            ),
          ),
        ],
      ),
    );
  }

  String getNiceHexArray(List<int> bytes) {
    return '[${bytes.map((i) => i.toRadixString(16).padLeft(2, '0')).join(', ')}]'
        .toUpperCase();
  }

  String getNiceManufacturerData(Map<int, List<int>> data) {
    if (data.isEmpty) {
      return null;
    }
    List<String> res = [];
    data.forEach((id, bytes) {
      res.add(
          '${id.toRadixString(16).toUpperCase()}: ${getNiceHexArray(bytes)}');
    });
    return res.join(', ');
  }

  String getNiceServiceData(Map<String, List<int>> data) {
    if (data.isEmpty) {
      return null;
    }
    List<String> res = [];
    data.forEach((id, bytes) {
      res.add('${id.toUpperCase()}: ${getNiceHexArray(bytes)}');
    });
    return res.join(', ');
  }

  @override
  Widget build(BuildContext context) {
    return ExpansionTile(
      title: _buildTitle(context),
      leading: Text(result.rssi.toString()),
      trailing: RaisedButton(
        child: Text('CONNECT'), //Ecran de connexion lorsque le bluetoth est activé avec localisation
        color: Colors.black,
        textColor: Colors.white,
        onPressed: (result.advertisementData.connectable) ? onTap : null, //Permet de savoir les devices connectables ou non
      ),
      children: <Widget>[
        _buildAdvRow(
            context, 'Complete Local Name', result.advertisementData.localName),
        _buildAdvRow(context, 'Tx Power Level',
            '${result.advertisementData.txPowerLevel ?? 'N/A'}'),
        _buildAdvRow(
            context,
            'Manufacturer Data',
            getNiceManufacturerData(
                result.advertisementData.manufacturerData) ??
                'N/A'),
        _buildAdvRow(
            context,
            'Service UUIDs',
            (result.advertisementData.serviceUuids.isNotEmpty)
                ? result.advertisementData.serviceUuids.join(', ').toUpperCase()
                : 'N/A'),
        _buildAdvRow(context, 'Service Data',
            getNiceServiceData(result.advertisementData.serviceData) ?? 'N/A'),
      ],
    );
  }
}

class ServiceTile extends StatelessWidget {// Page pour une connexion (ex : nordic uart)
  final BluetoothService service;
  final List<CharacteristicTile> characteristicTiles;

  const ServiceTile({Key key, this.service, this.characteristicTiles})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (characteristicTiles.length > 0) {
      return ExpansionTile(
        title: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text('Service'),
            Text('0x${service.uuid.toString().toUpperCase().substring(4, 8)}',
                style: Theme.of(context)
                    .textTheme
                    .body1
                    .copyWith(color: Theme.of(context).textTheme.caption.color))
          ],
        ),
        children: characteristicTiles,//Menu déroulant quand tu cliques sur un service dispo.
      );
    } else {
      return ListTile( //Quand il n'y a pas de caractéristiques pour le service
        title: Text('Service'),
        subtitle:
        Text('0x${service.uuid.toString().toUpperCase().substring(4, 8)}'),
      );
    }
  }
}

class CharacteristicTile extends StatefulWidget {
  //La classe avec les boutons d'écriture/Notification
  final BluetoothCharacteristic characteristic;
  //final List<DescriptorTile> descriptorTiles;
  final BluetoothDevice device;
  final VoidCallback onReadPressed;
  final VoidCallback onWritePressed;
  final VoidCallback onNotificationPressed;

  const CharacteristicTile({Key key,
    this.characteristic,
    this.device,
    this.onReadPressed,
    this.onWritePressed,
    this.onNotificationPressed})
      : super(key: key);

  @override
  CharacteristicTitleState createState(){
    return CharacteristicTitleState(this.characteristic,this.device, this.onReadPressed,this.onWritePressed,this.onNotificationPressed);
  }

}

class CharacteristicTitleState extends State<CharacteristicTile>{
  final BluetoothCharacteristic characteristic;
  final BluetoothDevice device;
  final VoidCallback onReadPressed;
  final VoidCallback onWritePressed;
  final VoidCallback onNotificationPressed;

  final valnotif = ValueNotifier(0);

  CharacteristicTitleState(this.characteristic,this.device, this.onReadPressed,this.onWritePressed,this.onNotificationPressed);


  /*changesOnField(){
    characteristic.value.listen((value) {
      String _val = value.toString();
      String _newcode="";
      int _code =0;
      print("Val init de la longueur de val: ${_val.length}");
      if(_val.length >2){
        for(int i=0; i<_val.length/4;i++){

          //print("Val $i : ${value[i]}");
          _code = value[i] -48;

          _newcode = _newcode + _code.toString();

        }
        print("Equivalent : $_newcode");
      }
    });
    WidgetsBinding.instance.addPostFrameCallback((_) => setState(() {}));
  }*/

  @override
  void initState(){
    //device.discoverServices();
    characteristic.setNotifyValue(true);//Dit qu'on active les notifs

    characteristic.value.listen((value) {
      String _val = value.toString();
      String _newcode="";
      int _code =0;
      print("Val init de la longueur de val: ${_val.length}");
      if(_val.length >2){
        for(int i=0; i<_val.length/4;i++){

          //print("Val $i : ${value[i]}");
          _code = value[i] -48;

          _newcode = _newcode + _code.toString();

        }
        print("Equivalent : $_newcode");
      }
    });
    //valnotif.addListener(changesOnField); A remettre si tu veux utiliser les changements
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<int>>(
      stream: characteristic.value,
      initialData: characteristic.lastValue,
      builder: (c, snapshot) {
        final value = snapshot.data;
        return
          Text((() {
            String _val = value.toString();
            String _newcode = "";
            int _code = 0;
            print("Val de la longueur de val: ${_val.length}");
            if (_val.length > 2) {
              for (int i = 0; i < _val.length / 4; i++) {
                //print("Val $i : ${value[i]}");
                _code = value[i] - 48;

                _newcode = _newcode + _code.toString();
              }
              print("Equivalent ds code : $_newcode");
            }
            return _newcode;
          })());

      }
    );
  }
}
