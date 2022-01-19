
import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/services.dart';
import 'package:flutter_bluetooth_serial/flutter_bluetooth_serial.dart';
import 'package:math_expressions/math_expressions.dart';

enum Mode {
  parameter,
  config,
  dtc,
  at
}

/// Never run multiple command functions at the same time. This may result in errors for which there is no warranty
/// Never use 1, 2, 3 or 4 for requestCodes for example you can use 5, 11, 222, 333, 4444 or 1234 and any number you wants
/// but never use single number about 1,2,3,4 => Thanks.
class Obd2Plugin {
  static const MethodChannel _channel = MethodChannel('obd2_plugin');

  BluetoothState _bluetoothState = BluetoothState.UNKNOWN;
  final FlutterBluetoothSerial _bluetooth = FlutterBluetoothSerial.instance;

  BluetoothConnection? connection ;
  int requestCode = 999999999999999999;
  String lastetCommand = "";
  Function(String command, String response, int requestCode)? onResponse ;
  Mode commandMode = Mode.at ;
  List<String> dtcCodesResponse = [];
  bool sendDTCToResponse = false ;
  dynamic runningService = '';
  List<dynamic> parameterResponse = [];

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

  Future<int> getParamsFromJSON (String jsonString, {int lastIndex = 0, int requestCode = 4}) async {
    commandMode = Mode.parameter ;
    bool configed = false ;
    List<dynamic> stm = [];
    try {
      stm = json.decode(jsonString);
    } catch (e){
      //
    }
    int index = 0 ;
    if (stm.isEmpty){
      throw Exception("Are you joking me ?, send me params json list text.");
    }
    index = lastIndex ;
    runningService = stm[lastIndex];
    if ((stm.length - 1) == index){
      configed = true;
      sendDTCToResponse = true;
    }
    _write(stm[lastIndex]["PID"], requestCode);
    if (!configed){
      Future.delayed(const Duration(milliseconds: 350), (){
        getParamsFromJSON(jsonString, lastIndex: (lastIndex + 1));
      });
    }

    return ((stm.length * 350) + 150);
  }



  Future<int> getDTCFromJSON(String stringJson, {int lastIndex = 0, int requestCode = 3}) async {
    commandMode = Mode.dtc ;
    bool configed = false ;
    List<dynamic> stm = [];
    try {
      stm = json.decode(stringJson);
    } catch (e){
      //
    }
    int index = 0 ;
    if (stm.isEmpty){
      throw Exception("Are you joking me ?, send me dtc json list text.");
    }
    index = lastIndex ;
    if ((stm.length - 1) == index){
      configed = true;
      sendDTCToResponse = true;
    }
    _write(stm[lastIndex]["command"], requestCode);


    if (!configed){
      Future.delayed(const Duration(milliseconds: 1000), (){
        getDTCFromJSON(stringJson, lastIndex: (lastIndex + 1));
      });
    }

    return ((stm.length * 1000) + 150);
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
  Future<int> configObdWithJSON(String stringJson, {int lastIndex = 0, int requestCode = 2}) async {
    commandMode = Mode.config ;
    bool configed = false ;
    List<dynamic> stm = [];
    try {
      stm = json.decode(stringJson);
    } catch (e){
      //
    }
    int index = 0 ;
    if (stm.isEmpty){
      throw Exception("Are you joking me ?, send me configuration json list text.");
    }
    _write(stm[lastIndex]["command"], requestCode);
    index = lastIndex ;
    if ((stm.length - 1) == index){
      configed = true;
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
            if (commandMode == Mode.parameter){
              dynamic dyResponse = "";
              String type = runningService["description"].toString().replaceAll("<", "").replaceAll(">", "");

              String validResponse = response.replaceAll("\n", "").replaceAll("\r", "").replaceAll(">", "").replaceAll("SEARCHING...", "");
              if(validResponse.contains(runningService["unit"].toString().toUpperCase()) || validResponse.contains(runningService["unit"].toString().toLowerCase())){
                validResponse = validResponse.replaceAll(runningService["unit"].toString().toUpperCase(), "");
                validResponse = validResponse.replaceAll(runningService["unit"].toString().toLowerCase(), "");
              }
              if(runningService["description"].toString().contains(", ")){
                List<String> bytes = _calculateParameterFrames(runningService["PID"], validResponse.toString());
                String formula = runningService["description"].toString().split(", ")[1];
                type = type.split(", ")[0];
                // formula for example => (( [0] * 256) + [1] ) / 4
                try {
                  for (int i = 0 ; i < bytes.length; i++){
                    formula = formula.replaceAll("[${i.toString()}]", int.parse(bytes[i], radix: 16).toRadixString(10));
                  }
                  Parser p = Parser();
                  Expression exp = p.parse(formula);
                  dyResponse = exp.evaluate(EvaluationType.REAL, ContextModel()).toString();
                } catch (e){
                  //
                }

              } else {
                dyResponse = validResponse.toString();
              }
              runningService["response"] = dyResponse ;
              parameterResponse.add(runningService);
              if (sendDTCToResponse){
                this.onResponse!(
                    "PARAMETER",
                    json.encode(parameterResponse),
                    requestCode
                );
                parameterResponse = [];
                sendDTCToResponse = false ;
              }
              commandMode = Mode.at ;
              requestCode = 999999999999999999 ;
              lastetCommand = "";
              response = "";
            } else if (commandMode == Mode.dtc){
              String validResponse = response.replaceAll("\n", "").replaceAll("\r", "").replaceAll(">", "").replaceAll("SEARCHING...", "");
              dtcCodesResponse += _getDtcsFrom(
                  validResponse,
                  limit: "7F ${lastetCommand.contains(" ") ? lastetCommand.split(" ")[0] : lastetCommand.toString()}",
                  command: lastetCommand
              );
              dtcCodesResponse = dtcCodesResponse.toSet().toList();
              if (sendDTCToResponse){
                this.onResponse!(
                    "DTC",
                    json.encode(dtcCodesResponse),
                    requestCode
                );
                dtcCodesResponse = [];
                sendDTCToResponse = false ;
              }
              commandMode = Mode.at ;
              requestCode = 999999999999999999 ;
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
              sendDTCToResponse = false ;
              commandMode = Mode.at ;
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
    String result = "";
    List<String> _dtcCodes = [];
    if (!value.contains(limit)){
      List<String> dtcBytes = _calculateDtcFrames(command, value);
      if (dtcBytes.length < 6){
        // checkTheEndItem(context);
      } else {
        for ( int i = 0; i < dtcBytes.length; i += 3 ){
          if (i >= dtcBytes.length){
            break ;
          }
          try {
            String binary = int.parse(dtcBytes[i]+dtcBytes[i+1], radix: 16).toRadixString(2);
            if (binary.length != 16) {
              var len = 16 - binary.length;
              binary = binary.padLeft(len + binary.length, '0');
            }
            result += _initialDataOne(binary.substring(0, 2));
            result += _initialDataTwo(binary.substring(2, 4));
            result += _initialDTC(binary.substring(4, 8));
            result += _initialDTC(binary.substring(8, 12));
            result += _initialDTC(binary.substring(12, binary.length));
            if(result != "P0000" && _dtcCodes.contains(result) == false){
              _dtcCodes.add(result);
            }
          } on RangeError catch (e){
            // index range error - no problem
          }
          result = "";
        }
      }
    }
    return _dtcCodes ;
  }



  List<String> _calculateParameterFrames(String command, String response){
    command = command.replaceAll(" ", "");
    response = response.replaceAll(" ", "");

    if (response == "NODATA"){
      return [];
    }

    String cmd = "";
    for (int i = 0; i < command.length ; i++){
      cmd += i == 0 ? (int.parse(command[i]) + 4).toString() : command[i];
    }
    String calculatedValidResponse = "";
    List<String> splitedValid = response.split(cmd);
    for (int i = 1; i < splitedValid.length; i++){
      calculatedValidResponse += splitedValid[i];
    }
    List<String> bytes = _convertToByteString(calculatedValidResponse).split(" ");

    if (bytes.isNotEmpty){
      if (bytes[bytes.length - 1].length < 2){
        bytes.removeAt(bytes.length - 1);
      }
    }
    return bytes ;
  }




  List<String> _calculateDtcFrames(String command, String response){
    command = command.replaceAll(" ", "");
    response = response.replaceAll(" ", "");

    if (response == "NODATA"){
      return [];
    }

    String cmd = "";
    for (int i = 0; i < 2 ; i++){
      cmd += i == 0 ? (int.parse(command[i]) + 4).toString() : command[i];
    }
    String calculatedValidResponse = "";
    List<String> splitedValid = response.split(cmd);
    for (int i = 1; i < splitedValid.length; i++){
      calculatedValidResponse += splitedValid[i];
    }
    List<String> bytes = _convertToByteString(calculatedValidResponse).split(" ");

    if (bytes.isNotEmpty){
      if (bytes[bytes.length - 1].length < 2){
        bytes.removeAt(bytes.length - 1);
      }
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



