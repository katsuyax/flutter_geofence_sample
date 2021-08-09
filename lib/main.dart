import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_geofence/geofence.dart';
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
  FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();
  final longitudeController = TextEditingController();
  final latitudeController = TextEditingController();
  final radiusController = TextEditingController();

  final entryID = 'entry_home';
  final exitID = 'exit_home';

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
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              keyboardType: TextInputType.number,
              decoration: InputDecoration(labelText: 'latitude'),
              controller: latitudeController,
            ),
            TextField(
              keyboardType: TextInputType.number,
              decoration: InputDecoration(labelText: 'longitude'),
              controller: longitudeController,
            ),
            TextField(
              keyboardType: TextInputType.number,
              decoration:
                  InputDecoration(labelText: 'radius', hintText: 'mater'),
              controller: radiusController,
            ),
            Gap(16.0),
            ElevatedButton(
              onPressed: _addGeolocation,
              child: Text('Add GeoLocation'),
            ),
            ElevatedButton(
              onPressed: _removeGeolocation,
              child: Text('Remove Geolocation'),
            ),
            ElevatedButton(
              onPressed: _setCurrentLocation,
              child: Text('Set CurrentLocation'),
            ),
          ],
        ),
      ),
    );
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
    Geofence.initialize();
    _startListening();
  }

  Future<void> _requestPermissions() async {
    await [Permission.notification, Permission.location].request();
  }

  void _addGeolocation() {
    var isFailure = false;
    Geofence.addGeolocation(
            Geolocation(
                latitude: double.parse(latitudeController.text),
                longitude: double.parse(longitudeController.text),
                radius: double.parse(radiusController.text),
                id: entryID),
            GeolocationEvent.entry)
        .catchError((onError) {
      isFailure = true;
    });
    Geofence.addGeolocation(
            Geolocation(
                latitude: double.parse(latitudeController.text),
                longitude: double.parse(longitudeController.text),
                radius: double.parse(radiusController.text),
                id: exitID),
            GeolocationEvent.exit)
        .catchError((onError) {
      isFailure = true;
    });

    if (isFailure) {
      showToast('failure to add');
    } else {
      showToast('success to add');
    }
  }

  Future<void> _setCurrentLocation() async {
    final location = await Geofence.getCurrentLocation();
    if (location != null) {
      print('current ${location.latitude},${location.longitude}');
      longitudeController.text = '${location.longitude}';
      latitudeController.text = '${location.latitude}';
    } else {
      showToast('Location information has not been acquired');
    }
  }

  void _removeGeolocation() {
    Geofence.removeAllGeolocations()
        .then((value) => showToast('remove all geolocations'))
        .onError((error, stackTrace) =>
            showToast('failure to remove all geolocations'));
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
