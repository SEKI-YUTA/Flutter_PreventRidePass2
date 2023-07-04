import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:prevent_ride_pass2/util/DBHelper.dart';
import 'package:prevent_ride_pass2/util/NotificationHelper.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:location/location.dart';
import 'package:permission_handler/permission_handler.dart' as ph;
import 'package:prevent_ride_pass2/ConstantValue.dart';
import 'package:prevent_ride_pass2/model/CurrentLocation.dart';
import 'package:prevent_ride_pass2/model/Point.dart';
import 'package:prevent_ride_pass2/model/SavedData.dart';
import 'package:prevent_ride_pass2/model/Setting.dart';
import 'package:prevent_ride_pass2/point_list.screen.dart';
import 'package:prevent_ride_pass2/setting_screen.dart';
import 'package:prevent_ride_pass2/util/GeneralUtil.dart';
import 'package:prevent_ride_pass2/util/RequirePemisson.dart';
import 'package:prevent_ride_pass2/widget/LoadingWidget.dart';
import 'package:sqflite/sqflite.dart';
import 'package:http/http.dart' as http;
import 'package:visibility_detector/visibility_detector.dart';

// https://github.com/SEKI-YUTA/Flutter_PreventRidePass/blob/master/lib/map_screen.dart
// 最終的にこれで解決↓
// https://github.com/Baseflow/flutter-geolocator/issues/1189
// https://pub.dev/packages/sqflite
// これらはこの画面でしか使う予定はないので共有する必要はない

Database? database;
// MapController? mapController;

class MapScreen extends ConsumerStatefulWidget {
  const MapScreen({super.key, required this.title});
  final String title;

  @override
  _MapScreenState createState() => _MapScreenState();
}

class _MapScreenState extends ConsumerState<MapScreen>
    with WidgetsBindingObserver {
  // late Database database;
  MapController? mapController;
  // 権限関連
  bool backgroundLocationEnabled = false;
  bool locationEnabled = false;
  bool hasNotificationPermission = false;
  // ネットに接続されているか
  bool networkConnect = false;
  // 現在位置を取得中であるか
  bool loading = true;
  // 検索中であるか
  bool isSearching = false;
  // マップの用意ができているか
  bool isMapReady = false;
  // 現在位置の移動を追従するか
  bool isTracking = true;
  // 検索結果をスワイプで表示非表示を管理
  bool searchResultShowing = true;

  Setting setting = ConstantValue.defaultSetting;
  SharedPreferences? preferences;
  List<dynamic>? searchResult;
  TextEditingController searchInputController = TextEditingController();
  List<Marker> markerList = List.empty(growable: true);
  Marker? pickedMarker;
  Marker? activeMarker;
  Marker? searchResultMarker;
  List<Marker> acitvePointMarkerList = [];
  Marker emptyMarker =
      Marker(point: LatLng(0, 0), builder: (context) => Container());
  Location? location;

  AutoDisposeStreamProvider<LocationData>? currentLocationStateProvider;
  AutoDisposeFutureProvider<SavedData>? savedDataStateProvider;
  final currentLocationProvider = StateProvider<CurrentLocation>((ref) {
    return CurrentLocation(latitude: 0, longitude: 0);
  });
  final savedDataProvider = StateProvider<SavedData>((ref) {
    return SavedData(pointList: [], routeList: []);
  });

  setPickedMarker(LatLng pos) {
    pickedMarker = Marker(
        point: pos,
        builder: (context) => GestureDetector(
              child: RotationTransition(
                  turns: AlwaysStoppedAnimation(
                      -1 * (mapController!.rotation / 360)),
                  child: const Icon(Icons.location_on_outlined)),
              onLongPress: () {
                pickedMarker = null;
                setState(() {});
              },
            ));
  }

  setActiveMarker(Point p) {
    activeMarker = Marker(
        point: LatLng(p.latitude, p.longitude),
        builder: (context) => RotationTransition(
              turns:
                  AlwaysStoppedAnimation(-1 * (mapController!.rotation / 360)),
              child: GestureDetector(
                child: const Icon(
                  Icons.location_pin,
                  color: Colors.blue,
                ),
              ),
            ));
  }

  setSearchResultMarker(Point p) {
    searchResultMarker = Marker(
        point: LatLng(p.latitude, p.longitude),
        builder: (context) => RotationTransition(
              turns:
                  AlwaysStoppedAnimation(-1 * (mapController!.rotation / 360)),
              child: GestureDetector(
                child: const Icon(
                  Icons.location_pin,
                  color: Colors.deepOrange,
                ),
              ),
            ));
  }

  void setUp() async {
    preferences = await SharedPreferences.getInstance();
    String? settingStr = preferences!.getString(ConstantValue.settingStrKey);
    print("settingStr: $settingStr");
    if (settingStr != null) {
      Map<String, dynamic> map = json.decode(settingStr);
      int thMeter = map["thMeter"];
      bool failed = map["failed"];
      setting = Setting(thMeter: thMeter, faliled: failed);
      // setting = Setting.fromJson(json.decode(settingStr));
    }
    database ??= await GeneralUtil.getAppDatabase();

    Future<bool> networkConnectFuture = GeneralUtil.checkNetworkConnect();
    Location location = Location();
    PermissionStatus requestPermission = await location.requestPermission();
    print("location permission: ${requestPermission}");
    if (requestPermission == PermissionStatus.granted) {
      locationEnabled = true;
    } else {
      GeneralUtil.showExitDialog(context, "現在位置へのアクセスが必須です", () {
        exit(1);
      });
    }
    NotificationHelper.setUpNotification();
    hasNotificationPermission =
        (await NotificationHelper.checkNotificationPermission())!;
    if (!hasNotificationPermission) {
      GeneralUtil.showExitDialog(context, "通知へのアクセスを許可してください", () {
        exit(1);
      });
    }
    if (hasNotificationPermission && locationEnabled) injectProvider();
    Future f = Future.wait([
      networkConnectFuture,
    ]);
    f.then((value) {
      List<bool> resultList = value as List<bool>;
      networkConnect = resultList[0];
      loading = false;
      setState(() {});
    });
  }

  Future<void> navigateToPointListScreen(BuildContext context) async {
    final result = await Navigator.of(context).push(MaterialPageRoute(
        builder: (context) => PointListScreen(
              type: 1,
              db: database!,
              savedDataProvider: savedDataProvider,
              routeList: [],
              pointList: ref.read(savedDataProvider).pointList,
            )));
    if (result == null) return;
    Point p = result as Point;
    LatLng? lng = pickedMarker?.point;
    if (lng != null &&
        lng.latitude == p.latitude &&
        lng.longitude == p.longitude) {
      pickedMarker = null;
    }
    setActiveMarker(p);
    mapController!.move(LatLng(p.latitude, p.longitude), mapController!.zoom);
    isTracking = false;
    setState(() {});
  }

  Future<void> searchPlace(String query) {
    if (query == "") return Future.value();
    isSearching = true;
    setState(() {});
    String url = "${ConstantValue.GASbaseURL}?query= + $query";
    http.get(Uri.parse(url)).then((value) {
      Map<String, dynamic> jsonData = json.decode(value.body);
      List<dynamic> tmpList = (jsonData['results']);
      if (jsonData['status'].toLowerCase() == "ok") {
        searchResult = tmpList;
        print("found ${jsonData['results'].length}");
        print(
            "found ${jsonData['results'][0]['address_components'][0]['long_name']}");
      } else {
        searchResult = null;
        Fluttertoast.showToast(msg: "該当する場所が見つかりませんでした");
      }
      isSearching = false;
      searchResultShowing = true;
      setState(() {});
    });
    return Future.value(null);
  }

  void injectProvider() async {
    print("injectProvider");
    location = Location();
    backgroundLocationEnabled = false;
    try {
      backgroundLocationEnabled =
          await location!.enableBackgroundMode(enable: true);
    } catch (e) {
      backgroundLocationEnabled = false;
    }
    // backgroundLocationEnabled = await location!.isBackgroundModeEnabled();
    if (backgroundLocationEnabled) {
      location!.enableBackgroundMode(enable: true);
    } else {
      location!.enableBackgroundMode(enable: false);
    }
    currentLocationStateProvider =
        StreamProvider.autoDispose<LocationData>((ref) {
      return location!.onLocationChanged.map((LocationData locationData) {
        print(
            "locationData latitude: ${locationData.latitude} longitude: ${locationData.longitude}");
        ref.read(currentLocationProvider.notifier).state = CurrentLocation(
            latitude: locationData.latitude!,
            longitude: locationData.longitude!);
        SavedData savedData = ref.read(savedDataProvider.notifier).state;
        List<Point> activeList = ref
            .read(savedDataProvider.notifier)
            .state
            .pointList
            .where((element) => element.isActive)
            .toList();
        CurrentLocation currentLocation =
            ref.read(currentLocationProvider.notifier).state;
        for (Point point in activeList) {
          double distance = Geolocator.distanceBetween(
              point.latitude,
              point.longitude,
              currentLocation.latitude,
              currentLocation.longitude);
          print("distance: $distance ringed: ${point.isRinged}");
          if (distance <= setting.thMeter && !point.isRinged) {
            // if (distance <= Setting.th_meter && !point.isRinged) {
            print("通知を出す処理");
            NotificationHelper.showNotificaton(
                1, "${point.name}に近づきました", "目的地に近づきました", null);
            point.isRinged = true;
            point.isActive = false;
            int idx = savedData.pointList.indexOf(point);
            List<Point> newPointList = savedData.pointList;
            if (idx != -1) {
              newPointList[idx] = point;
              ref.read(savedDataProvider.notifier).state = SavedData(
                  pointList: newPointList, routeList: savedData.routeList);
            }
          }
        }
        return locationData;
      });
    });

    savedDataStateProvider = FutureProvider.autoDispose<SavedData>((ref) async {
      database ??= await GeneralUtil.getAppDatabase();
      // Future<List<Map<String, dynamic>>> dataList =
      late SavedData data;
      Future f1 = database!
          .rawQuery("select * from ${ConstantValue.pointTable}")
          .then((value) {
        List<Point> pointList = List.generate(value.length, (index) {
          int id = value[index]["id"] as int;
          String name = value[index]["name"] as String;
          double latitude = double.parse(value[index]["latitude"] as String);
          double longitude = double.parse(value[index]["longitude"] as String);
          return Point(
              id: id, name: name, latitude: latitude, longitude: longitude);
        });
        data = SavedData(pointList: pointList, routeList: []);
        ref.read(savedDataProvider.notifier).state = data;
      });

      await f1;
      return Future.value(data);
    });
  }

  void saveSetting() async {
    preferences = await SharedPreferences.getInstance();
    print("save: ${setting.toJson()}");
    preferences!
        .setString(ConstantValue.settingStrKey, setting.toJson().toString());
    // preferences.setString(ConstantValue.settingStrKey, setting.toString());
  }

  @override
  void initState() {
    WidgetsBinding.instance.addObserver(this);
    super.initState();
    mapController = MapController();
    setUp();
  }

  @override
  void dispose() {
    super.dispose();
    WidgetsBinding.instance.removeObserver(this);
    mapController?.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    print("state $state");
    switch (state) {
      case AppLifecycleState.resumed:
        setState(() {});
        break;
      case AppLifecycleState.paused:
        saveSetting();
        List<Point> activePointList = ref
            .read(savedDataProvider.notifier)
            .state
            .pointList
            .where((ele) => ele.isActive)
            .toList();
        print("acitve location: ${activePointList.length}");
        if (activePointList.length > 0 && backgroundLocationEnabled) {
          location!.enableBackgroundMode(enable: true);
        } else {
          location!.enableBackgroundMode(enable: false);
        }
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    bool flg = (currentLocationStateProvider != null) &&
        (savedDataStateProvider != null);
    print("flg: $flg");
    return flg ? providedWidget() : blankWidget();
  }

  Widget blankWidget() {
    return Scaffold(appBar: AppBar(), body: Container());
  }

  Widget providedWidget() {
    print("providedWidget");
    ref.watch(savedDataStateProvider!);
    ref.watch(currentLocationStateProvider!);
    final currentLocation = ref.watch(currentLocationProvider);
    final savedData = ref.watch(savedDataProvider);
    final savedDataController = ref.read(savedDataProvider.notifier);
    if (isMapReady && isTracking) {
      mapController!.move(
          LatLng(currentLocation.latitude, currentLocation.longitude),
          mapController!.zoom);
    }

    acitvePointMarkerList = savedData.pointList
        .where((element) => element.isActive || element.isRinged)
        .map((point) {
      int distance = Geolocator.distanceBetween(point.latitude, point.longitude,
              currentLocation.latitude, currentLocation.longitude)
          .toInt();
      return Marker(
        width: 60,
        height: 60,
        point: LatLng(point.latitude, point.longitude),
        builder: (context) => ActiveMarkerChild(distance),
      );
    }).toList();

    return Scaffold(
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.settings_outlined),
            onPressed: () {
              // 設定画面へ遷移
              Navigator.of(context).push(MaterialPageRoute(
                builder: (context) => SettingScreen(
                  setting: setting,
                  cacllback: (s) {
                    // UIを更新しやんからsetStateいらん
                    setting = s;
                  },
                ),
              ));
            },
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.list_outlined),
              onPressed: () {
                // 登録地点一覧画面へ
                navigateToPointListScreen(context);
              },
            ),
            // 一旦ルート機能はなし
            // IconButton(
            //   icon: const Icon(Icons.route_outlined),
            //   onPressed: () {
            //     // 登録ルート一覧へ
            //     Navigator.of(context).push(MaterialPageRoute(
            //         builder: (context) => PointListScreen(
            //               type: 2,
            //               db: database!,
            //               savedDataProvider: savedDataProvider,
            //               pointList: [],
            //             )));
            //   },
            // ),
          ],
        ),
        body: Center(
          child: Stack(
            children: <Widget>[
              loading ||
                      currentLocation.latitude == 0 &&
                          currentLocation.longitude == 0
                  ? const LoadingWidget()
                  : networkConnect
                      ? FlutterMap(
                          mapController: mapController,
                          options: MapOptions(
                              maxZoom: 18,
                              zoom: 15,
                              onMapReady: () {
                                print("on Map ready");
                                isMapReady = true;
                                mapController!.move(
                                    LatLng(currentLocation.latitude,
                                        currentLocation.longitude),
                                    mapController!.zoom);
                              },
                              onMapEvent: (MapEvent p0) {
                                // ユーザーが自ら地図を動かした際に現在地の移動をトラッキングしないようにする
                                if (p0 is MapEventMove &&
                                    p0.source == MapEventSource.onDrag) {
                                  isTracking = false;
                                  setState(() {});
                                }
                              },
                              center: LatLng(currentLocation.latitude,
                                  currentLocation.longitude),
                              onPositionChanged: (position, hasGesture) {
                                print("position changed");
                              },
                              onTap: (tapPosition, point) {
                                // タップした位置にピンを指す(２回タップすると１回目の場所は消える)
                                setPickedMarker(point);
                                setState(() {});
                              },
                              interactiveFlags: InteractiveFlag.all,
                              enableScrollWheel: true,
                              scrollWheelVelocity: 0.00001),
                          children: [
                            TileLayer(
                              urlTemplate:
                                  // 'https://cyberjapandata.gsi.go.jp/xyz/std/{z}/{x}/{y}.png',
                                  'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                            ),
                            MarkerLayer(
                              markers: [
                                pickedMarker ?? emptyMarker,
                                activeMarker ?? emptyMarker,
                                searchResultMarker ?? emptyMarker,
                                ...acitvePointMarkerList,
                                (currentLocation.latitude != 0 &&
                                        currentLocation.longitude != 0)
                                    ? Marker(
                                        point: LatLng(currentLocation.latitude,
                                            currentLocation.longitude),
                                        builder: (context) {
                                          print(
                                              "controller rotation: ${mapController!.rotation}");
                                          return RotationTransition(
                                            turns: AlwaysStoppedAnimation(-1 *
                                                (mapController!.rotation /
                                                    360)),
                                            child:
                                                ConstantValue.locationMarker1,
                                          );
                                        },
                                      )
                                    : emptyMarker
                              ],
                            )
                          ],
                        )
                      : Center(
                          child: Text(
                            "ネットワークに接続されていません",
                            style: ConstantValue.titleText,
                          ),
                        ),
              // 検索バー
              Align(
                alignment: AlignmentDirectional.topCenter,
                child: Container(
                  decoration: const BoxDecoration(color: Colors.white),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 8),
                              // height: 60,
                              width: MediaQuery.of(context).size.width - 60,
                              child: TextFormField(
                                  // textInputAction: TextInputAction.search,
                                  onFieldSubmitted: (value) =>
                                      searchPlace(value),
                                  controller: searchInputController,
                                  style: const TextStyle(fontSize: 18),
                                  decoration: InputDecoration(
                                      contentPadding:
                                          const EdgeInsets.fromLTRB(8, 0, 0, 0),
                                      hintText: "場所を検索",
                                      border: OutlineInputBorder(
                                          borderRadius:
                                              BorderRadius.circular(10)))),
                            ),
                            Container(
                              width: 50,
                              height: 50,
                              child: !isSearching
                                  ? IconButton(
                                      icon: const Icon(Icons.search_outlined),
                                      onPressed: () {
                                        searchPlace(searchInputController.text);
                                      },
                                    )
                                  : const Center(
                                      child: CircularProgressIndicator()),
                            )
                          ]),
                      backgroundLocationEnabled
                          ? Container()
                          : Container(
                              padding: const EdgeInsets.fromLTRB(0, 0, 0, 8),
                              child: const Text(
                                "バックグラウンドでの位置情報の取得が許可されていません",
                                style: TextStyle(
                                    color: Colors.red,
                                    fontWeight: FontWeight.bold),
                              ),
                            ),
                    ],
                  ),
                ),
              ),
              AnimatedPositioned(
                duration: const Duration(milliseconds: 400),
                left: 0,
                bottom:
                    (searchResult != null && searchResultShowing) ? 20 : -160,
                curve: Curves.bounceInOut,
                child: GestureDetector(
                  onPanUpdate: (details) {
                    if (details.delta.dy > 0 && details.delta.distance > 5) {
                      // 下方向にスワイプした時
                      print("hide");
                      searchResultShowing = false;
                      setState(() {});
                    }
                    if (details.delta.dy < 0 && details.delta.distance > 5) {
                      // 上方向にスワイプしたとき
                      print("show");
                      searchResultShowing = true;
                      setState(() {});
                    }
                  },
                  child: searchResult != null
                      ? Container(
                          height: 200,
                          width: MediaQuery.of(context).size.width,
                          child: ListView.builder(
                            scrollDirection: Axis.horizontal,
                            itemCount: searchResult!.length,
                            itemBuilder: (context, index) {
                              Map<String, dynamic> itemData =
                                  searchResult![index];
                              // print(
                              //     );
                              String buildingName =
                                  itemData['address_components'][0]
                                      ['short_name'];
                              String address = itemData['formatted_address'];
                              // print(itemData['geometry']['location']['lat']);

                              double lat = itemData['geometry']['location']
                                  ['lat'] as double;
                              double lon = itemData['geometry']['location']
                                  ['lng'] as double;

                              return VisibilityDetector(
                                key: Key("searchResult:${index.toString()}"),
                                onVisibilityChanged: (visilityInfo) {
                                  if (visilityInfo.visibleFraction == 1) {
                                    isTracking = false;
                                    setSearchResultMarker(Point(
                                        id: 0,
                                        name: "",
                                        latitude: lat,
                                        longitude: lon));
                                    mapController!.move(
                                        LatLng(lat, lon), mapController!.zoom);
                                    setState(() {});
                                  }
                                },
                                child: Card(
                                  margin: EdgeInsets.fromLTRB(
                                      index == 0 ? 24 : 16,
                                      0,
                                      index == searchResult!.length - 1
                                          ? 24
                                          : 0,
                                      0),
                                  shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(10)),
                                  child: GestureDetector(
                                    onTap: () {
                                      isTracking = false;
                                      setState(() {});
                                      mapController!.move(LatLng(lat, lon),
                                          mapController!.zoom);
                                    },
                                    child: Container(
                                      padding: ConstantValue.cardPadding,
                                      width: MediaQuery.of(context).size.width *
                                          0.8,
                                      height: 200,
                                      child: Column(children: [
                                        Text(
                                          buildingName,
                                          style: ConstantValue.titleText,
                                        ),
                                        Text(
                                          address,
                                          style: const TextStyle(fontSize: 14),
                                        )
                                      ]),
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                        )
                      : Container(),
                ),
              )
            ],
          ),
        ),
        floatingActionButton: Column(
          mainAxisAlignment: MainAxisAlignment.end,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            pickedMarker != null
                ? FloatingActionButton(
                    heroTag: "fab_add",
                    onPressed: () {
                      // 追加メニューを下から表示
                      showDialog(
                        context: context,
                        builder: (context) {
                          TextEditingController editingController =
                              TextEditingController();
                          return AlertDialog(
                            title: const Text("場所を登録"),
                            actions: [
                              TextButton(
                                  onPressed: () async {
                                    if (pickedMarker == null) return;
                                    // 追加
                                    print("name: " + editingController.text);
                                    print(
                                        "latitude: ${pickedMarker?.point.latitude} longitude: ${pickedMarker?.point.longitude}");
                                    Point p = Point(
                                        id: 0,
                                        name: editingController.text,
                                        latitude: pickedMarker!.point.latitude,
                                        longitude:
                                            pickedMarker!.point.longitude);
                                    print("add point: ${p.toString()}");
                                    // insertPoint(p);
                                    int insertedId = await DBHelper.insertPoint(
                                        database!, p);
                                    p.id = insertedId;
                                    List<Point> tmpList = savedData.pointList;
                                    tmpList.add(p);
                                    print("tmp list size: ${tmpList.length}");
                                    savedDataController.state = SavedData(
                                        pointList: tmpList,
                                        routeList: savedData.routeList);
                                    print(
                                        "inserted length: ${savedDataController.state.pointList.length}");
                                    Navigator.of(context).pop();
                                  },
                                  child: const Text("追加")),
                              TextButton(
                                  onPressed: () {
                                    // キャンセル
                                    Navigator.of(context).pop();
                                  },
                                  child: const Text("キャンセル")),
                            ],
                            content: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Container(
                                    child: TextField(
                                        decoration: ConstantValue
                                            .createPlaceholderDecoration(
                                                "場所の名前"),
                                        controller: editingController),
                                  )
                                ]),
                          );
                        },
                      );
                    },
                    child: const Icon(Icons.add),
                  )
                : Container(),
            const SizedBox(
              height: 12,
            ),
            FloatingActionButton(
              heroTag: "fab_track",
              child: Icon(isTracking
                  ? Icons.my_location_outlined
                  : Icons.location_disabled_outlined),
              onPressed: () {
                isTracking = true;
                setState(() {});
              },
            ),
          ],
        ));
  }

  Container ActiveMarkerChild(int distance) {
    return Container(
      child: Stack(
        children: [
          const Icon(
            Icons.location_on_outlined,
            size: 50,
            color: Colors.red,
          ),
          Positioned(
            bottom: 20,
            child: Container(
              decoration: BoxDecoration(color: Colors.white.withAlpha(140)),
              child: Text(
                "${distance}m",
                textAlign: TextAlign.center,
              ),
            ),
          )
        ],
      ),
    );
  }
}
