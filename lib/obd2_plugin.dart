
import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/services.dart';
import 'package:flutter_bluetooth_serial/flutter_bluetooth_serial.dart';

enum Mode {
  parameter,
  config,
  dtc,
  at
}

class Obd2Plugin {
  static const MethodChannel _channel = MethodChannel('obd2_plugin');

  BluetoothState _bluetoothState = BluetoothState.UNKNOWN;
  final FlutterBluetoothSerial _bluetooth = FlutterBluetoothSerial.instance;

  BluetoothConnection? connection ;
  int requestCode = 999999999999999999;
  String lastetCommand = "";
  Function(String command, String response, int requestCode)? onResponse ;
  Mode commandMode = Mode.at ;

  static Future<String?> get platformVersion async {
    final String? version = await _channel.invokeMethod('getPlatformVersion');
    return version;
  }


  Future<BluetoothState> get initBluetooth async {
    _bluetoothState = await FlutterBluetoothSerial.instance.state;
    return _bluetoothState;
  }

  Future<bool> get enableBluetooth async {
    bool status = false;
    if (_bluetoothState == BluetoothState.STATE_OFF) {
      bool? newStatus = await FlutterBluetoothSerial.instance.requestEnable();
      if (newStatus != null && newStatus != false){
        status = true ;
      }
    } else {
      status = true ;
    }
    return status ;
  }


  Future<bool> get disableBluetooth async {
    bool status = false;
    if (_bluetoothState == BluetoothState.STATE_ON) {
      bool? newStatus = await FlutterBluetoothSerial.instance.requestDisable();
      if(newStatus != null && newStatus != false){
        newStatus = true ;
      }
    }
    return status ;
  }


  Future<bool> get isBluetoothEnable async {
    if (_bluetoothState == BluetoothState.STATE_OFF) {
      return false ;
    } else if (_bluetoothState == BluetoothState.STATE_ON) {
      return true ;
    } else {
      try {
        _bluetoothState = await initBluetooth;
        bool newStatus = await isBluetoothEnable ;
        return newStatus ;
      } catch (e){
        throw Exception("obd2 plugin not initialed");
      }
    }
  }

  Future<List<BluetoothDevice>> get getPairedDevices async {
    return await _bluetooth.getBondedDevices();
  }

  Future<List<BluetoothDevice>> get getNearbyDevices async {
    List<BluetoothDevice> discoveryDevices = [];
    return await _bluetooth.startDiscovery().listen((event) {
      final existingIndex = discoveryDevices.indexWhere((element) => element.address == event.device.address);
      if (existingIndex >= 0) {
        discoveryDevices[existingIndex] = event.device;
      } else {
        if (event.device.name != null){
          discoveryDevices.add(event.device);
        }
      }
    }).asFuture(discoveryDevices);
  }

  Future<List<BluetoothDevice>> get getNearbyPairedDevices async {
    List<BluetoothDevice> discoveryDevices = [];
    return await _bluetooth.startDiscovery().listen((event) async {
      final existingIndex = discoveryDevices.indexWhere((element) => element.address == event.device.address);
      if (existingIndex >= 0) {
        if (await isPaired(event.device)){
          discoveryDevices[existingIndex] = event.device;
        }
      } else {
        if (event.device.name != null){
          discoveryDevices.add(event.device);
        }
      }
    }).asFuture(discoveryDevices);
  }

  Future<List<BluetoothDevice>> get getNearbyAndPairedDevices async {
    List<BluetoothDevice> discoveryDevices = await _bluetooth.getBondedDevices();
    await _bluetooth.startDiscovery().listen((event) {
      final existingIndex = discoveryDevices.indexWhere((element) => element.address == event.device.address);
      if (existingIndex >= 0) {
        discoveryDevices[existingIndex] = event.device;
      } else {
        if (event.device.name != null){
          discoveryDevices.add(event.device);
        }
      }
    }).asFuture(discoveryDevices);
    return discoveryDevices;
  }


  Future<void> getConnection(BluetoothDevice _device, Function(BluetoothConnection? connection) onConnected, Function(String message) onError) async {
    if (connection != null){
      await onConnected(connection);
      return ;
    }
    connection = await BluetoothConnection.toAddress(_device.address);
    if (connection != null){
      await onConnected(connection);
    } else {
      throw Exception("Sorry this happened. But I can not connect to the device. But I guess the device is not nearby or you have not disconnected before. Finally, if you wants to enter into a new relationship, you must end his previous relationship");
    }
  }


  Future<bool> disconnect () async {
    if (connection?.isConnected == true) {
      await connection?.close() ;
      connection = null ;
      return true ;
    } else {
      connection = null ;
      return false ;
    }
  }

  Future<int> getDTCFromJSON(/*String stringJson, */{int lastIndex = 0}) async {
    commandMode = Mode.dtc ;
    String stringJson = '''[
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
    ]''';
    bool configed = false ;
    List<dynamic> stm = [];
    try {
      stm = json.decode(stringJson);
    } catch (e){
      print(e);
    }
    int index = 0 ;
    if (stm.isEmpty){
      throw Exception("Are you joking me ?, send me dtc json list text.");
    }
    _write(stm[lastIndex]["command"], 3);
    index = lastIndex ;
    if ((stm.length - 1) == index){
      configed = true;
      commandMode = Mode.at ;
    }

    if (!configed){
      Future.delayed(const Duration(milliseconds: 1000), (){
        getDTCFromJSON(lastIndex: (lastIndex + 1));
      });
    }

    return ((stm.length * 1000) + 1500);
  }

  /// This int value return needed time to config / please wait finish it
  /// user Future.delayed for wait in this function
  /// [configObdWithJSON] => start loading if you want
  /// [Future.delayed] with int in milliseconds duration => Stop Loading
  /// for example
  /// Start loading ...
  /// await Future.delayed(Duration(milliseconds: await MyApp.of(context).obd2.configObdWithJSON('json String')), (){
  //    print("config is finished");
  //  });
  // Stop loading ...
  /// Thank you for reading this document.
  Future<int> configObdWithJSON(String stringJson, {int lastIndex = 0}) async {
    commandMode = Mode.config ;
    bool configed = false ;
    List<dynamic> stm = [];
    try {
      stm = json.decode(stringJson);
    } catch (e){
      print(e);
    }
    int index = 0 ;
    if (stm.isEmpty){
      throw Exception("Are you joking me ?, send me configuration json list text.");
    }
    _write(stm[lastIndex]["command"], 2);
    index = lastIndex ;
    if ((stm.length - 1) == index){
      configed = true;
      commandMode = Mode.at ;
    }

    if (!configed){
      Future.delayed(Duration(milliseconds: stm[lastIndex]["command"] == "AT Z" || stm[lastIndex]["command"] == "ATZ" ? 1000 : 100), (){
        configObdWithJSON(stringJson, lastIndex: (lastIndex + 1));
      });
    }

    return (stm.length * 150 + 1500);
  }




  Future<bool> pairWithDevice(BluetoothDevice _device) async {
    bool paired = false;
    bool? isPaired = await _bluetooth.bondDeviceAtAddress(_device.address);
    if (isPaired != null){
      paired = isPaired ;
    }
    return paired ;
  }

  Future<bool> unpairWithDevice(BluetoothDevice _device) async {
    bool unpaired = false;
    try {
      bool? isUnpaired = await _bluetooth.removeDeviceBondWithAddress(_device.address);
      if (isUnpaired != null){
        unpaired = isUnpaired;
      }
    } catch (e) {
      unpaired = false ;
    }
    return unpaired;
  }


  Future<bool> isPaired (BluetoothDevice _device) async {
    BluetoothBondState state = await _bluetooth.getBondStateForAddress(_device.address);
    return state.isBonded;
  }
  Future<bool> get hasConnection async {
    return connection != null ;
  }

  Future<void> _write(String command, int requestCode) async {
    lastetCommand = command;
    this.requestCode = requestCode ;
    connection?.output.add(Uint8List.fromList(utf8.encode("$command\r\n"))) ;
    await connection?.output.allSent ;
  }





  double _volEff = 0.8322 ;
  double _fTime(x) => x / 1000 ;
  double _fRpmToRps(x) => x / 60 ;
  double _fMbarToKpa(x) => x / 1000 * 100 ;
  double _fCelciusToLelvin(x) => x + 273.15 ;
  double _fImap(rpm, pressMbar, tempC) {
    double _v = (_fMbarToKpa(pressMbar) / _fCelciusToLelvin(tempC) / 2);
    return _fRpmToRps(rpm) * _v;
  }
  double fMaf(rpm, pressMbar, tempC) {
    double c = _fImap(rpm, pressMbar, tempC);
    double v = c * _volEff * 1.984 * 28.97;
    return v / 8.314;
  }
  double fFuel(rpm, pressMbar, tempC) {
    return (fMaf(rpm, pressMbar, tempC) * 3600) / (14.7 * 820);
  }


  Future<bool> get isListenToDataInitialed async {
    return onResponse != null ;
  }


  Future<void> setOnDataReceived(Function(String command, String response, int requestCode) onResponse) async {
    String response = "";
    if (this.onResponse != null){
      throw Exception("onDataReceived is preset and you can not reprogram it");
    } else {
      this.onResponse = onResponse ;
      connection?.input?.listen((Uint8List data){
        Uint8List bytes = Uint8List.fromList(data.toList());
        String string = String.fromCharCodes(bytes);
        if (!string.contains('>')) {
          response += string ;
        } else {
          response += string ;
          if (this.onResponse != null){
            if (commandMode == Mode.dtc){
              String validResponse = !response.contains("NO DATA") ? _convertToByteString(response.replaceAll("\n", "").replaceAll("\r", "").replaceAll(">", "").replaceAll("SEARCHING...", "")) : response.replaceAll("\n", "").replaceAll("\r", "").replaceAll(">", "").replaceAll("SEARCHING...", "");
              List<String> dtcList = _getDtcsFrom(
                  _convertToByteString(validResponse),
                  limit: "7F ${lastetCommand.contains(" ") ? lastetCommand.split(" ")[0] : lastetCommand.toString()}",
                  command: lastetCommand
              );
              print(lastetCommand + ": " + validResponse + " => " + dtcList.toString());
              requestCode = 999999999999999999;
              lastetCommand = "";
              response = "";
            } else {
              this.onResponse!(
                  lastetCommand,
                  response.replaceAll("\n", "")
                      .replaceAll("\r", "")
                      .replaceAll(">", "")
                      .replaceAll("SEARCHING...", ""),
                  requestCode
              );

              requestCode = 999999999999999999;
              lastetCommand = "";
              response = "";
            }
          }
        }
      });
    }
  }

  String _convertToByteString (String text){
    var buffer = StringBuffer();
    int every = 2 ; // Chars
    for (int i = 0; i < text.length; i++) {
      buffer.write(text[i]);
      var nonZeroIndex = i + 1;
      if (nonZeroIndex % every == 0 && nonZeroIndex != text.length) {
        buffer.write(' '); // Replace this with anything you want after each 2 chars
      }
    }
    return buffer.toString();
  }

  List<String> _getDtcsFrom(String value, {required String limit, required String command}){
    value = _convertToByteString(value);
    List<String> result = [];
    String resultt = "";
    if (!value.contains(limit)){
      List<String> dtcBytes = _calculateDtcFrames(command, value);
      if (!(dtcBytes.length < 6)){
        for ( int i = 0; i < dtcBytes.length; i += 3 ){
          if (i >= dtcBytes.length){
            break ;
          }
          String binary = int.parse(dtcBytes[i]+dtcBytes[i+1], radix: 16).toRadixString(2);
          if (binary.length != 16) {
            var len = 16 - binary.length;
            binary = binary.padLeft(len + binary.length, '0');
          }
          resultt += _initialDataOne(binary.substring(0, 2));
          resultt += _initialDataTwo(binary.substring(2, 4));
          resultt += _initialDTC(binary.substring(4, 8));
          resultt += _initialDTC(binary.substring(8, 12));
          resultt += _initialDTC(binary.substring(12, binary.length));
          if(resultt != "P0000" && result.contains(resultt) == false){
            result.add(resultt);
          }
          resultt = "";
        }
      }
    }
    return result ;
  }




  List<String> _calculateDtcFrames(String command, String response){
    String cmd = "${(int.parse(command[0]) + 4)}${command[1]}";
    if (!response.contains(cmd)){
      return [];
    }
    List<String> responseCharacters = response.split(" ");
    List<String> bytes = [];
    bool addToBytes = false ;
    for (int i = 0; i < responseCharacters.length; i++){
      if ((responseCharacters.length - 1) == i){
        if (addToBytes){
          bytes.add(responseCharacters[i]);
        }
      } else {
        if (!addToBytes){
          if (cmd.contains(" ")){
            if (responseCharacters[i] == cmd.split(" ")[0] && responseCharacters[(i+1)] == cmd.split(" ")[1]){
              i = i + 1 ;
              addToBytes = true ;
            }
          } else {
            if (responseCharacters[i] == cmd){
              addToBytes = true ;
            }
          }

        } else {
          bytes.add(responseCharacters[i]);
        }
      }
    }

    if (bytes.isNotEmpty){
      bytes.removeAt(bytes.length - 1);
    }
    return bytes ;
  }



  String _initialDataOne(String data_1){
    String result = "";
    switch (data_1){
      case "00": {
        result = "P";
        return result;
      }
      case "01": {
        result = "C";
        return result;
      }
      case "10": {
        result = "B";
        return result;
      }
      case "11": {
        result = "U";
        return result;
      }
    }
    return result ;
  }

  String _initialDataTwo(String data_2){
    String result = "";
    switch (data_2){
      case "00": {
        result = "0";
        return result;
      }
      case "01": {
        result = "1";
        return result;
      }
      case "10": {
        result = "2";
        return result;
      }
      case "11": {
        result = "3";
        return result;
      }
    }
    return result ;
  }


  String _initialDTC(String data_3){
    String result = "";
    switch (data_3){
      case "0000": {
        result = "0";
        return result;
      }
      case "0001": {
        result = "1";
        return result;
      }
      case "0010": {
        result = "2";
        return result;
      }
      case "0011": {
        result = "3";
        return result;
      }
      case "0100": {
        result = "4";
        return result;
      }
      case "0101": {
        result = "5";
        return result;
      }
      case "0110": {
        result = "6";
        return result;
      }
      case "0111": {
        result = "7";
        return result;
      }
      case "1000": {
        result = "8";
        return result;
      }
      case "1001": {
        result = "9";
        return result;
      }
      case "1010": {
        result = "A";
        return result;
      }
      case "1011": {
        result = "B";
        return result;
      }
      case "1100": {
        result = "C";
        return result;
      }
      case "1101": {
        result = "D";
        return result;
      }
      case "1110": {
        result = "E";
        return result;
      }
      case "1111": {
        result = "F";
        return result;
      }
    }
    return result ;
  }


}



