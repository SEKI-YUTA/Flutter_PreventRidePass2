import 'package:flutter/material.dart';
import 'package:flutter/src/widgets/framework.dart';
import 'package:flutter/src/widgets/placeholder.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:prevent_ride_pass2/DemoData.dart';
import 'package:prevent_ride_pass2/map_screen.dart';
import 'package:prevent_ride_pass2/model/Point.dart';
import 'package:prevent_ride_pass2/model/Route.dart';
import 'package:prevent_ride_pass2/model/SavedData.dart';
import 'package:prevent_ride_pass2/util/GeneralUtil.dart';
import 'package:prevent_ride_pass2/widget/RoutePassCard.dart';
import 'package:prevent_ride_pass2/widget/PointCard.dart';
import 'package:sqflite/sqflite.dart';

class PointListScreen extends ConsumerStatefulWidget {
  PointListScreen(
      {super.key,
      required this.type,
      required this.db,
      required this.pointList,
      required this.savedDataProvider});
  int type; // 1: 位置リスト 2: ルートリスト
  Database db;
  StateProvider<SavedData> savedDataProvider;
  List<Point> pointList;
  List<RoutePass> routeList = DemoData.routeList;
  @override
  _PointListScreenState createState() => _PointListScreenState();
}

class _PointListScreenState extends ConsumerState<PointListScreen> {
  @override
  void initState() {
    super.initState();
    print("passed list size: ${widget.pointList.length}");
  }

  // void startUp() async {
  //   List<Point> pList = await GeneralUtil.readAllPointFromDB(widget.db);
  //   print(pList.length);
  // }

  @override
  Widget build(BuildContext context) {
    final SavedData savedData = ref.watch(widget.savedDataProvider);
    final savedDataController = ref.read(widget.savedDataProvider.notifier);
    return Scaffold(
      appBar: AppBar(),
      body: Container(
        child: widget.type == 1
            ? ListView.builder(
                itemCount: widget.pointList.length,
                // itemCount: savedData.pointList.length,
                itemBuilder: (context, index) {
                  Point p = widget.pointList[index];
                  print("$index ${p.isActive}");
                  return PointCard(
                    p: p,
                    changeActiveState: (bool newState) {
                      List<RoutePass> routeList = savedData.routeList;
                      List<Point> pointList = widget.pointList;
                      Point newP = pointList[index];
                      newP.isActive = newState;
                      pointList[index] = newP;
                      savedDataController.state =
                          SavedData(pointList: pointList, routeList: routeList);
                    },
                  );
                },
              )
            : ListView.builder(
                itemCount: widget.routeList.length,
                itemBuilder: (context, index) {
                  RoutePass r = widget.routeList[index];
                  return RoutePassCard(r: r);
                },
              ),
      ),
      floatingActionButton: widget.type == 2
          ? FloatingActionButton(
              child: const Icon(Icons.add),
              onPressed: () {
                showDialog(
                    context: context,
                    builder: (context) {
                      return AlertDialog(
                        title: Text("ルートを作成"),
                        actions: [
                          TextButton(onPressed: () {}, child: Text("追加")),
                          TextButton(onPressed: () {}, child: Text("キャンセル"))
                        ],
                        content: Column(children: [
                          Container(
                            height: 100,
                            child: Text("選択した位置を表示するリスト"),
                          ),
                          Container(
                            height: 100,
                            child: Text("登録している地点のリスト"),
                          ),
                        ]),
                      );
                    });
              },
            )
          : Container(),
    );
  }
}
