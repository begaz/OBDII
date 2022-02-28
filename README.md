# OBD-II Plugin

Connect safety to elm327 🤗
© Copyright 2021 [Begaz](https://begaz.app) - All Rights Reserved

## Getting Started

1. Download the plugin from git
2. Save in [../projectFolder]() directory
3. Extract folder on ../projectFolder
4. Rename extracted folder to "obd_connection_ii"
5. add plugin to pubspec.yaml with

```yaml
dependencies:
  flutter:
    sdk: flutter

  obd_connection_ii:
    path: ../
```
then in terminal run
```sh
flutter pub get
```

## Usage

*Initial class*
```dart
Obd2Plugin obd2 = Obd2Plugin();
```

***Status***
below line code request to enable Bluetooth in device if Bluetooth not enable
```dart
bool enabled = await obd2.enableBluetooth;
```
if Bluetooth already enabled before request will be return 
```dart 
true
```
***Connection***
Check device has a active connection
```dart
bool connected = await obd2.hasConnection;
```

Get paired bluetooth device
```dart
List<BluetoothDevice> devices = await obd2.getPairedDevices;
```
Get nearby devices
```dart
List<BluetoothDevice> devices = await obd2.getNearbyDevices;
```
Or both
```dart
List<BluetoothDevice> devices = await obd2.getNearbyPairedDevices;
```
& Connect to a BluetoothDevice

```dart
obd2.getConnection(
	devices[index], 
	(connection){
		print("connected to bluetooth device.");
	},
	(message) {
		print("error in connecting: $message");
	}
);
```


***Receive data***

Listen to returned response from OBD-II
```dart
obd2.setOnDataReceived((command, response, requestCode){
	print("$command => $response");
});
```
```setOnDataReceived``` method initial only one time so if you want check this is initialed or not must use
```dart
await obd2.isListenToDataInitialed;
```

***Send data***

##### Config parameters
```dart
await obd2.configObdWithJSON(json, {int requestCode});
```

##### Note
1. ```configObdWithJSON``` is return ```int``` value.
2. int value is say time is need for waiting in milliseconds.
3. we recommend to use below code.
	```dart
	loading.start();
	await Future.delayed(Duration(milliseconds: await obd2.configObdWithJSON(json)), (){
		loading.stop();
	});
	```
4.  First, check your needs and use the three methods provided in different situations.
	```dart
	getParamsFromJSON(paramJSON), getDTCFromJSON(dtcJSON), configObdWithJSON(json)
	```
5. you must use this json format string in methods.

	***config***
	```dart
	String json = '''[
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
        ]''';
	```
	***param***
	```dart
	String paramJSON = '''
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
      ''';
	```

	***dtc 🚗***
	```dart
	String dtcJSON = '''
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
          ''';
	```
After call ```configObdWithJSON```, you can access received data in ```setOnDataReceived``` method.

Created with ❤️ at Begaz.
