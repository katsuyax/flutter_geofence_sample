import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_geofence/geofence.dart';
import 'package:flutter_geofence_sample/geolocations.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:gap/gap.dart';
import 'package:oktoast/oktoast.dart';
import 'package:permission_handler/permission_handler.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return OKToast(
      child: MaterialApp(
        title: 'Geofencing',
        home: MainPage(),
      ),
    );
  }
}

class MainPage extends HookWidget {
  final flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();
  static final locationCount = 3;
  final latitudeController =
      List.generate(locationCount, (_) => TextEditingController());
  final longitudeController =
      List.generate(locationCount, (_) => TextEditingController());
  final radiusController =
      List.generate(locationCount, (_) => TextEditingController(text: '100'));

  String entryID(int locationNum) => 'entry_location${locationNum + 1}';
  String exitID(int locationNum) => 'exit_location${locationNum + 1}';

  @override
  Widget build(BuildContext context) {
    useEffect(() {
      _initialize();
    }, const []);

    return Scaffold(
      appBar: AppBar(
        title: Text('Geofence Sample'),
      ),
      body: Container(
        padding: EdgeInsets.only(
          left: 16.0,
          right: 16.0,
        ),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: _buildLocation(),
          ),
        ),
      ),
    );
  }

  List<Widget> _buildLocation() {
    final widgets = <Widget>[];
    for (int index = 0; index < locationCount; index++) {
      widgets.add(TextField(
        keyboardType: TextInputType.number,
        decoration:
            InputDecoration(labelText: 'Location ${index + 1} latitude'),
        controller: latitudeController[index],
      ));
      widgets.add(TextField(
        keyboardType: TextInputType.number,
        decoration:
            InputDecoration(labelText: 'Location ${index + 1} longitude'),
        controller: longitudeController[index],
      ));
      widgets.add(TextField(
        keyboardType: TextInputType.number,
        decoration: InputDecoration(
            labelText: 'Location ${index + 1} radius', hintText: 'mater'),
        controller: radiusController[index],
      ));
      widgets.add(Gap(8));
      widgets.add(ElevatedButton(
        onPressed: () => _addGeolocation(index),
        child: Text('Add Location ${index + 1}'),
      ));
      widgets.add(ElevatedButton(
        onPressed: () => _setCurrentLocation(index),
        child: Text('Set Current Location to ${index + 1}'),
      ));
      widgets.add(Gap(8));
    }
    widgets.add(ElevatedButton(
      onPressed: _removeAllGeolocation,
      child: Text('Remove All Geolocation'),
      style: ElevatedButton.styleFrom(
        primary: Colors.red,
      ),
    ));
    widgets.add(Gap(32));

    return widgets;
  }

  Future<void> _initialize() async {
    final initializationSettingsAndroid =
        AndroidInitializationSettings('app_icon');
    final initializationSettingsIOS =
        IOSInitializationSettings(onDidReceiveLocalNotification: null);
    final initializationSettings = InitializationSettings(
        android: initializationSettingsAndroid, iOS: initializationSettingsIOS);
    await _requestPermissions();
    await FlutterLocalNotificationsPlugin()
        .initialize(initializationSettings, onSelectNotification: null);
    _loadSharedPreference();
    Geofence.initialize();
    _startListening();
  }

  Future<void> _requestPermissions() async {
    await [Permission.notification, Permission.location].request();
  }

  Future<void> _loadSharedPreference() async {
    for (int locationNum = 0; locationNum < locationCount; locationNum++) {
      final location = await Geolocations.getGeolocation(locationNum);
      if (location != null) {
        latitudeController[locationNum].text = location.latitude.toString();
        longitudeController[locationNum].text = location.longitude.toString();
        radiusController[locationNum].text = location.radius.toString();
      }
    }
  }

  void _addGeolocation(int locationNum) {
    var isSuccess = true;
    final entry = Geolocation(
        latitude: double.parse(latitudeController[locationNum].text),
        longitude: double.parse(longitudeController[locationNum].text),
        radius: double.parse(radiusController[locationNum].text),
        id: entryID(locationNum));
    final exit = Geolocation(
        latitude: double.parse(latitudeController[locationNum].text),
        longitude: double.parse(longitudeController[locationNum].text),
        radius: double.parse(radiusController[locationNum].text),
        id: exitID(locationNum));

    Geofence.addGeolocation(
      entry,
      GeolocationEvent.entry,
    ).catchError((onError) {
      isSuccess = false;
    });
    Geofence.addGeolocation(
      exit,
      GeolocationEvent.exit,
    ).catchError((onError) {
      isSuccess = false;
    });

    if (isSuccess) {
      showToast('success to add location ${locationNum + 1}');
      Geolocations.setGeolocation(locationNum, entry);
    } else {
      showToast('failure to add ${locationNum + 1}');
    }
  }

  Future<void> _setCurrentLocation(int locationNum) async {
    final location = await Geofence.getCurrentLocation();
    if (location != null) {
      print('current ${location.latitude},${location.longitude}');
      longitudeController[locationNum].text = '${location.longitude}';
      latitudeController[locationNum].text = '${location.latitude}';
      showToast('set current location to TextField \nNot yet add');
    } else {
      showToast('Location information has not been acquired');
    }
  }

  void _removeAllGeolocation() {
    Geofence.removeAllGeolocations().then((value) {
      showToast('remove all geolocations');
      longitudeController.forEach((controller) => controller.clear());
      latitudeController.forEach((controller) => controller.clear());
      radiusController.forEach((controller) => controller.text = '100');
      Geolocations.clear();
    }).onError((error, stackTrace) {
      showToast('failure to remove all geolocations');
    });
  }

  void _startListening() {
    Geofence.startListening(GeolocationEvent.entry, (entry) {
      print("Entry ${entry.id}");
      scheduleNotification('entry', '${entry.id}');
    });
    Geofence.startListening(GeolocationEvent.exit, (entry) {
      print("Exit ${entry.id}");
      scheduleNotification('exit', '${entry.id}');
    });
  }

  void scheduleNotification(String title, String subtitle) {
    Future.delayed(Duration(seconds: 5)).then((result) async {
      var androidPlatformChannelSpecifics = AndroidNotificationDetails(
          'id', 'name', 'description',
          importance: Importance.high, priority: Priority.high);
      var iOSPlatformChannelSpecifics = IOSNotificationDetails();
      var platformChannelSpecifics = NotificationDetails(
          android: androidPlatformChannelSpecifics,
          iOS: iOSPlatformChannelSpecifics);
      await flutterLocalNotificationsPlugin.show(
          Random().nextInt(100000), title, subtitle, platformChannelSpecifics);
    });
  }
}
