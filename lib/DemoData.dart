import 'package:prevent_ride_pass2/model/Point.dart';
import 'package:prevent_ride_pass2/model/Route.dart';

class DemoData {
  static List<Point> pointList = [
    Point(
        name: "野崎駅", latitude: 34.71882808994998, longitude: 135.6370849393795),
    Point(
        name: "京橋駅",
        latitude: 34.69674957047948,
        longitude: 135.53394609019063),
    Point(
        name: "谷町六丁目駅",
        latitude: 34.676107381723234,
        longitude: 135.517035352869),
  ];

  static List<RoutePass> routeList = [
    RoutePass(name: "バイト先までのルート", pointList: [
      Point(
          name: "野崎駅",
          latitude: 34.71882808994998,
          longitude: 135.6370849393795),
      Point(
          name: "京橋駅",
          latitude: 34.69674957047948,
          longitude: 135.53394609019063),
      Point(
          name: "谷町六丁目駅",
          latitude: 34.676107381723234,
          longitude: 135.517035352869),
    ])
  ];
}
