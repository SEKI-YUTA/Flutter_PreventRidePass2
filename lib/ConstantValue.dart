import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';

class ConstantValue {
  static String dbName = "prevetRidePass.db";
  static String pointTable = "pointTable";
  static String routeTable = "routeTable";
  static String GASbaseURL =
      "https://script.google.com/macros/s/AKfycbzd3QKrbBm7SsJYsUJ3oVdnznnmBGdOcqaAqztLNqf9euL41HibiXsBkqF5ENawf322jQ/exec";
  static LatLng defaultLocation = LatLng(35.68954055933207, 139.69169865644184);
  static TextStyle titleText =
      const TextStyle(fontSize: 24, fontWeight: FontWeight.bold);
  static EdgeInsets cardPadding =
      const EdgeInsets.symmetric(horizontal: 8, vertical: 4);
  static EdgeInsets p8 = const EdgeInsets.all(8);
  static TextStyle normalText = const TextStyle(fontSize: 18);
  static InputDecoration createPlaceholderDecoration(String placeholder) {
    return InputDecoration(hintText: placeholder);
  }
}
