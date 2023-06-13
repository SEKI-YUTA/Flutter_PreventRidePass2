import 'package:flutter/material.dart';

class ConstantValue {
  static String dbName = "prevetRidePass.db";
  static String pointTable = "pointTable";
  static String routeTable = "routeTable";
  static TextStyle titleText =
      const TextStyle(fontSize: 24, fontWeight: FontWeight.bold);
  static EdgeInsets cardPadding =
      const EdgeInsets.symmetric(horizontal: 8, vertical: 4);
  static InputDecoration createPlaceholderDecoration(String placeholder) {
    return InputDecoration(hintText: placeholder);
  }
}
