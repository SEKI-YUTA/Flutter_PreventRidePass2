import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:prevent_ride_pass2/ConstantValue.dart';
import 'package:prevent_ride_pass2/model/Point.dart';
import 'package:prevent_ride_pass2/model/RoutePass.dart';
import 'package:prevent_ride_pass2/model/SavedData.dart';

class RoutePassCard extends StatefulWidget {
  RoutePassCard(
      {super.key,
      required this.r,
      required this.pointList,
      required this.setNewPointList});

  final RoutePass r;
  List<Point> pointList;
  Function setNewPointList;

  @override
  State<RoutePassCard> createState() => _RoutePassCardState();
}

class _RoutePassCardState extends State<RoutePassCard> {
  bool isActive = false;
  late List<int> idList;
  @override
  void initState() {
    super.initState();
    idList = widget.r.pointIdsStr
        .split(",")
        .map(
          (e) => int.parse(e),
        )
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Container(
        padding: ConstantValue.cardPadding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(widget.r.name, style: ConstantValue.titleText),
            Row(
              children: [
                Column(
                  children: [
                    ...widget.pointList
                        .where((ele) => idList.contains(ele.id))
                        .toList()
                        .map((e) => Text(e.name))
                  ],
                ),
                Switch(
                    value: isActive,
                    onChanged: (value) {
                      isActive = value;
                      List<Point> newPointList = widget.pointList.map((item) {
                        if (idList.contains(item.id)) {
                          item.isActive = value;
                          item.isRinged = !value;
                          return item;
                        } else {
                          return item;
                        }
                      }).toList();
                      widget.setNewPointList(newPointList);
                      setState(() {});
                    })
              ],
            )
          ],
        ),
      ),
    );
  }
}
