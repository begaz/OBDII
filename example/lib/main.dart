import 'package:flutter/material.dart';
import 'dart:async';

import 'package:flutter/services.dart';
import 'package:obd2_plugin/obd2_plugin.dart';
import 'package:flutter_bluetooth_serial/flutter_bluetooth_serial.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({Key? key}) : super(key: key);
  static _MyAppState of(BuildContext context) => context.findAncestorStateOfType()!;

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  final String _platformVersion = 'Unknown';

  @override
  void initState() {
    super.initState();
  }

  var obd2 = Obd2Plugin();

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: "OBDII Plugin Test",
      locale: const Locale.fromSubtags(languageCode: 'en'),
      home: Scaffold(
        appBar: AppBar(
          title: const Text('OBDII Plugin Test'),
        ),
        body: Center(
          child: Text('Running on: $_platformVersion\n'),
        ),
        floatingActionButton: const Float(),
        floatingActionButtonAnimator: FloatingActionButtonAnimator.scaling,
        floatingActionButtonLocation: FloatingActionButtonLocation.miniCenterFloat,
      ),
    );
  }
}


class Float extends StatelessWidget {
  const Float({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return FloatingActionButton(
      child: const Icon(Icons.bluetooth),
      onPressed: () async {
        if(!(await MyApp.of(context).obd2.isBluetoothEnable)){
          await MyApp.of(context).obd2.enableBluetooth ;
        }
        if (!(await MyApp.of(context).obd2.hasConnection)){
          await showBluetoothList(context, MyApp.of(context).obd2);
        } else {
          if (!(await MyApp.of(context).obd2.isListenToDataInitialed)){
            MyApp.of(context).obd2.setOnDataReceived((command, response, requestCode){
              print("c: $command r: $response, rc: $requestCode");
            });
          }
          Future.delayed(Duration(milliseconds: await MyApp.of(context).obd2.configObdWithJSON()), (){
            print("config is finished");
          });
        }
      },
    );
  }
}


Future<void> showBluetoothList(BuildContext context, Obd2Plugin obd2plugin) async {
  List<BluetoothDevice> devices = await obd2plugin.getNearbyAndPairedDevices ;
  showModalBottomSheet(
      context: context,
      builder: (builder) {
        return Container(
          padding: const EdgeInsets.only(top: 32),
          width: double.infinity,
          height: devices.length * 50,
          child: ListView.builder(
            itemCount: devices.length,
            itemBuilder: (context, index){
              return SizedBox(
                height: 50,
                child: TextButton(
                  onPressed: (){
                    obd2plugin.getConnection(devices[index], (connection)
                    {
                      print("connected to bluetooth device.");
                      Navigator.pop(builder);
                    }, (message) {
                      print("error in connecting: $message");
                      Navigator.pop(builder);
                    });
                  },
                  child: Center(
                    child: Text(devices[index].name.toString()),
                  ),
                ),
              );
            },
          ),
        );
      }
  );
}

