import 'package:flutter/material.dart';
import 'package:flutter/src/widgets/framework.dart';
import 'package:flutter/src/widgets/placeholder.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:prevent_ride_pass2/ConstantValue.dart';
import 'package:prevent_ride_pass2/DemoData.dart';
import 'package:prevent_ride_pass2/map_screen.dart';
import 'package:prevent_ride_pass2/model/Point.dart';
import 'package:prevent_ride_pass2/model/RoutePass.dart';
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
      required this.savedDataProvider});
  int type; // 1: 位置リスト 2: ルートリスト
  Database db;
  StateProvider<SavedData> savedDataProvider;
  @override
  _PointListScreenState createState() => _PointListScreenState();
}

class _PointListScreenState extends ConsumerState<PointListScreen> {
  List<Point> selectedList = [];
  List<Point> copyedPointList = [];
  TextEditingController nameController = TextEditingController();
  @override
  void initState() {
    super.initState();
    copyedPointList = ref.read(widget.savedDataProvider).pointList;
  }

  // void startUp() async {
  //   List<Point> pList = await GeneralUtil.readAllPointFromDB(widget.db);
  //   print(pList.length);
  // }

  @override
  Widget build(BuildContext context) {
    print("build");
    final SavedData savedData = ref.watch(widget.savedDataProvider);
    final savedDataController = ref.read(widget.savedDataProvider.notifier);
    print("pontSize: ${savedData.pointList.length}");
    return Scaffold(
      appBar: AppBar(),
      body: Container(
        child: widget.type == 1
            ? ListView.builder(
                itemCount: savedData.pointList.length,
                // itemCount: savedData.pointList.length,
                itemBuilder: (context, index) {
                  Point p = savedData.pointList[index];
                  print("$index ${p.isActive}");
                  return PointCard(
                    p: p,
                    changeActiveState: (bool newState) {
                      List<RoutePass> routeList = savedData.routeList;
                      List<Point> pointList = savedData.pointList;
                      Point newP = pointList[index];
                      newP.isActive = newState;
                      newP.isRinged = false;
                      pointList[index] = newP;
                      savedDataController.state =
                          SavedData(pointList: pointList, routeList: routeList);
                    },
                  );
                },
              )
            : ListView.builder(
                itemCount: savedData.routeList.length,
                itemBuilder: (context, index) {
                  RoutePass r = savedData.routeList[index];
                  return RoutePassCard(
                    r: r,
                    pointList: savedData.pointList,
                    setNewPointList: (List<Point> newPointList) {
                      ref.read(widget.savedDataProvider.notifier).state =
                          SavedData(pointList: newPointList, routeList: savedData.routeList);
                    },
                  );
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
                      return StatefulBuilder(builder: (context, setState) {
                        return AlertDialog(
                          title: Text("ルートを作成"),
                          actions: [
                            TextButton(
                                onPressed: () async {
                                  String name = nameController.text;
                                  if (selectedList.length == 0) {
                                    Fluttertoast.showToast(
                                        msg: "１つ以上の地点を選択してください");
                                    return;
                                  } else if (name == "") {
                                    Fluttertoast.showToast(msg: "名前を入力してください");
                                    return;
                                  }
                                  List<int> idList =
                                      selectedList.map((e) => e.id).toList();
                                  String idsStr = idList.join(",");
                                  print("name: ${name}");
                                  print("idsStr: ${idsStr}");
                                  RoutePass newRoutePass = RoutePass(
                                      id: -1, name: name, pointIdsStr: idsStr);
                                  int newID = await GeneralUtil.insertRoute(
                                      widget.db, newRoutePass);
                                  newRoutePass.id = newID;
                                  SavedData savedData = ref
                                      .read(widget.savedDataProvider.notifier)
                                      .state;
                                  savedData.routeList.add(newRoutePass);
                                  ref
                                          .read(widget.savedDataProvider.notifier)
                                          .state =
                                      SavedData(
                                          pointList: savedData.pointList,
                                          routeList: savedData.routeList);
                                  Navigator.of(context).pop();
                                },
                                child: Text("追加")),
                            TextButton(onPressed: () {}, child: Text("キャンセル"))
                          ],
                          content: SingleChildScrollView(
                            child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  TextField(
                                    controller: nameController,
                                  ),
                                  Container(
                                    child: Text("選択済みの地点"),
                                  ),
                                  Container(
                                    height: 160,
                                    width:
                                        MediaQuery.of(context).size.width * 0.7,
                                    child: ListView.builder(
                                      itemCount: selectedList.length,
                                      itemBuilder: (context, index) {
                                        Point p = selectedList[index];
                                        return Card(
                                          key: Key("pointListKey$index"),
                                          child: Container(
                                            padding: const EdgeInsets.symmetric(
                                                horizontal: 8, vertical: 4),
                                            child: Row(
                                              children: [
                                                Expanded(
                                                  child: Text(
                                                    p.name,
                                                    style:
                                                        ConstantValue.titleText,
                                                  ),
                                                ),
                                                IconButton(
                                                  icon:
                                                      const Icon(Icons.remove),
                                                  onPressed: () {
                                                    selectedList.remove(p);
                                                    copyedPointList.add(p);
                                                    setState(() {});
                                                  },
                                                )
                                                // Text("緯度: ${p.latitude}"),
                                                // Text("経度: ${p.longitude}")
                                              ],
                                            ),
                                          ),
                                        );
                                      },
                                    ),
                                  ),
                                  Container(
                                    child: Text("登録済みの地点"),
                                  ),
                                  Container(
                                    height: 160,
                                    width:
                                        MediaQuery.of(context).size.width * 0.7,
                                    child: ListView.builder(
                                      itemCount: copyedPointList.length,
                                      itemBuilder: (context, index) {
                                        Point p = copyedPointList[index];
                                        return Card(
                                          key: Key("pointListKey$index"),
                                          child: Container(
                                            padding: const EdgeInsets.symmetric(
                                                horizontal: 8, vertical: 4),
                                            child: Row(
                                              children: [
                                                Expanded(
                                                  child: Text(
                                                    p.name,
                                                    style:
                                                        ConstantValue.titleText,
                                                  ),
                                                ),
                                                IconButton(
                                                  icon: const Icon(Icons.add),
                                                  onPressed: () {
                                                    selectedList.add(p);
                                                    copyedPointList.remove(p);
                                                    setState(() {});
                                                  },
                                                )
                                                // Text("緯度: ${p.latitude}"),
                                                // Text("経度: ${p.longitude}")
                                              ],
                                            ),
                                          ),
                                        );
                                      },
                                    ),
                                  ),
                                ]),
                          ),
                        );
                      });
                    });
              },
            )
          : Container(),
    );
  }

  void addPoint(Point p) {
    setState(() {
      copyedPointList.remove(p);
      copyedPointList = [...copyedPointList];
      // selectedList.add(p);
      selectedList = [...selectedList, p];
    });
  }
}
