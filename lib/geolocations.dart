import 'dart:convert';

import 'package:flutter_geofence/Geolocation.dart';
import 'package:shared_preferences/shared_preferences.dart';

extension GeolocationExt on Geolocation {
  static fromJson(Map<String, dynamic> json) => Geolocation(
      latitude: json['latitude'],
      longitude: json['longitude'],
      radius: json['radius'],
      id: json['id']);
  Map<String, dynamic> toJson() => {
        'latitude': latitude,
        'longitude': longitude,
        'radius': radius,
        'id': id,
      };
}

class Geolocations {
  static Future<void> setGeolocation(
      int locationNum, Geolocation geolocation) async {
    final prefs = await SharedPreferences.getInstance();
    final value = json.encode(geolocation.toJson());
    prefs.setString('location${locationNum + 1}', value);
  }

  static Future<Geolocation?> getGeolocation(int locationNum) async {
    final prefs = await SharedPreferences.getInstance();
    final jsonStr = prefs.getString('location${locationNum + 1}');

    if (jsonStr == null) {
      return null;
    }

    return GeolocationExt.fromJson(json.decode(jsonStr));
  }

  static Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
  }
}
