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
              print("$command => $response");
            });
          }
          await Future.delayed(Duration(milliseconds: await MyApp.of(context).obd2.configObdWithJSON('''[
            {
                "command": "AT Z",
                "description": "",
                "status": true
            },
            {
                "command": "AT E0",
                "description": "",
                "status": true
            },
            {
                "command": "AT SP 0",
                "description": "",
                "status": true
            },
            {
                "command": "AT SH 81 10 F1",
                "description": "",
                "status": true
            },
            {
                "command": "AT H1",
                "description": "",
                "status": true
            },
            {
                "command": "AT S0",
                "description": "",
                "status": true
            },
            {
                "command": "AT M0",
                "description": "",
                "status": true
            },
            {
                "command": "AT AT 1",
                "description": "",
                "status": true
            },
            {
                "command": "01 00",
                "description": "",
                "status": true
            }
        ]''')), (){});
          await Future.delayed(Duration(milliseconds: await MyApp.of(context).obd2.getParamsFromJSON('''
        [
            {
                "PID": "AT RV",
                "length": 4,
                "title": "ولتاژ باطری",
                "unit": "V",
                "description": "<str>",
                "status": true
            },
            {
                "PID": "01 0C",
                "length": 2,
                "title": "دور موتور",
                "unit": "RPM",
                "description": "<double>, (( [0] * 256) + [1] ) / 4",
                "status": true
            },
            {
                "PID": "01 0D",
                "length": 1,
                "title": "سرعت خودرو",
                "unit": "Kh",
                "description": "<int>, [0]",
                "status": true
            },
            {
                "PID": "01 05",
                "length": 1,
                "title": "دمای موتور",
                "unit": "°C",
                "description": "<int>, [0] - 40",
                "status": true
            },
            {
                "PID": "01 0B",
                "length": 1,
                "title": "فشار مطلق منیفولد",
                "unit": "kPa",
                "description": "<int>, [0]",
                "status": true
            }
        ]
      ''')), (){});
          await Future.delayed(Duration(milliseconds: await MyApp.of(context).obd2.getDTCFromJSON('''
            [
    {
        "id": 1,
        "created_at": "2021-12-05T16:33:18.965620Z",
        "command": "03",
        "response": "6",
        "status": true
    },
    {
        "id": 7,
        "created_at": "2021-12-05T16:35:01.516477Z",
        "command": "18 FF 00",
        "response": "",
        "status": true
    },
    {
        "id": 6,
        "created_at": "2021-12-05T16:34:51.417614Z",
        "command": "18 02 FF FF",
        "response": "",
        "status": true
    },
    {
        "id": 5,
        "created_at": "2021-12-05T16:34:23.837086Z",
        "command": "18 02 FF 00",
        "response": "",
        "status": true
    },
    {
        "id": 4,
        "created_at": "2021-12-05T16:34:12.496052Z",
        "command": "18 00 FF 00",
        "response": "",
        "status": true
    },
    {
        "id": 3,
        "created_at": "2021-12-05T16:33:38.323200Z",
        "command": "0A",
        "response": "6",
        "status": true
    },
    {
        "id": 2,
        "created_at": "2021-12-05T16:33:28.439547Z",
        "command": "07",
        "response": "6",
        "status": true
    },
    {
        "id": 34,
        "created_at": "2021-12-05T16:41:25.883408Z",
        "command": "17 FF 00",
        "response": "",
        "status": true
    },
    {
        "id": 35,
        "created_at": "2021-12-05T16:41:38.901888Z",
        "command": "13 FF 00",
        "response": "",
        "status": true
    },
    {
        "id": 36,
        "created_at": "2021-12-05T16:41:51.040962Z",
        "command": "19 02 AF",
        "response": "",
        "status": true
    },
    {
        "id": 37,
        "created_at": "2021-12-05T16:42:01.384228Z",
        "command": "19 02 AC",
        "response": "",
        "status": true
    },
    {
        "id": 38,
        "created_at": "2021-12-05T16:42:11.770741Z",
        "command": "19 02 8D",
        "response": "",
        "status": true
    },
    {
        "id": 39,
        "created_at": "2021-12-05T16:42:28.443368Z",
        "command": "19 02 23",
        "response": "",
        "status": true
    },
    {
        "id": 40,
        "created_at": "2021-12-05T16:42:39.200378Z",
        "command": "19 02 78",
        "response": "",
        "status": true
    },
    {
        "id": 41,
        "created_at": "2021-12-05T16:42:50.444404Z",
        "command": "19 02 08",
        "response": "",
        "status": true
    },
    {
        "id": 42,
        "created_at": "2021-12-05T16:43:00.466739Z",
        "command": "19 0F AC",
        "response": "",
        "status": true
    },
    {
        "id": 43,
        "created_at": "2021-12-05T16:43:10.645120Z",
        "command": "19 0F 8D",
        "response": "",
        "status": true
    },
    {
        "id": 44,
        "created_at": "2021-12-05T16:43:25.257023Z",
        "command": "19 0F 23",
        "response": "",
        "status": true
    },
    {
        "id": 45,
        "created_at": "2021-12-05T16:43:36.567099Z",
        "command": "19 D2 FF 00",
        "response": "",
        "status": true
    },
    {
        "id": 46,
        "created_at": "2021-12-05T17:15:56.352652Z",
        "command": "19 C2 FF 00",
        "response": "",
        "status": true
    },
    {
        "id": 47,
        "created_at": "2021-12-05T17:16:17.567797Z",
        "command": "19 FF FF 00",
        "response": "",
        "status": true
    }
]
          ''')), (){
            print("dtc is finished");
          });
        }
      },
    );
  }
}


Future<void> showBluetoothList(BuildContext context, Obd2Plugin obd2plugin) async {
  List<BluetoothDevice> devices = await obd2plugin.getPairedDevices ;
  showModalBottomSheet(
      context: context,
      builder: (builder) {
        return Container(
          padding: const EdgeInsets.only(top: 0),
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

