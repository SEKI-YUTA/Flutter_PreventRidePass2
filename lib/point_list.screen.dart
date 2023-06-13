import 'package:flutter/material.dart';
import 'package:flutter/src/widgets/framework.dart';
import 'package:flutter/src/widgets/placeholder.dart';
import 'package:prevent_ride_pass2/DemoData.dart';
import 'package:prevent_ride_pass2/model/Point.dart';
import 'package:prevent_ride_pass2/model/Route.dart';
import 'package:prevent_ride_pass2/widget/RoutePassCard.dart';
import 'package:prevent_ride_pass2/widget/PointCard.dart';

class PointListScreen extends StatefulWidget {
  int type; // 1: 位置リスト 2: ルートリスト
  PointListScreen({super.key, required this.type});
  List<Point> pointList = DemoData.pointList;
  List<RoutePass> routeList = DemoData.routeList;
  @override
  State<PointListScreen> createState() => _PointListScreenState();
}

class _PointListScreenState extends State<PointListScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(),
        body: Container(
          child: widget.type == 1
              ? ListView.builder(
                  itemCount: widget.pointList.length,
                  itemBuilder: (context, index) {
                    Point p = widget.pointList[index];
                    return PointCard(p: p);
                  },
                )
              : ListView.builder(
                  itemCount: widget.routeList.length,
                  itemBuilder: (context, index) {
                    RoutePass r = widget.routeList[index];
                    return RoutePassCard(r: r);
                  },
                ),
        ));
  }
}
