import 'dart:async';
import 'dart:convert';
import 'dart:io';

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
import 'package:prevent_ride_pass2/widget/LoadingWidget.dart';
import 'package:sqflite/sqflite.dart';
import 'package:http/http.dart' as http;

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
  bool locationEnabled = false;
  bool hasNotificationPermission = false;
  bool networkConnect = false;
  bool loading = true;
  bool isSearching = false;
  bool isMapReady = false;
  bool isTracking = true;
  List<dynamic>? searchResult = null;
  TextEditingController searchInputController = TextEditingController();

  final currentLocationProvider = StateProvider<CurrentLocation>((ref) {
    return CurrentLocation(latitude: 0, longitude: 0);
  });

  final savedDataProvider = StateProvider<SavedData>((ref) {
    return SavedData(pointList: [], routeList: []);
  });

  AutoDisposeStreamProvider<LocationData>? currentLocationStateProvider = null;
  AutoDisposeFutureProvider<SavedData>? savedDataStateProvider = null;

  int _counter = 0;
  List<Marker> markerList = List.empty(growable: true);
  Marker? pickedMarker = null;
  Marker? activeMarker = null;
  List<Marker> acitvePointMarkerList = [];
  Marker emptyMarker =
      Marker(point: LatLng(0, 0), builder: (context) => Container());

  setPickedMarker(LatLng pos) {
    pickedMarker = Marker(
        point: pos,
        builder: (context) => GestureDetector(
              child: RotationTransition(
                  turns: AlwaysStoppedAnimation(
                      -1 * (mapController!.rotation / 360)),
                  child: Icon(Icons.location_on_outlined)),
              onLongPress: () {
                pickedMarker = null;
                setState(() {});
              },
            ));
  }

  void setUp() async {
    // locationEnabled = await checkPermission();
    database ??= await GeneralUtil.getAppDatabase();

    Future<bool> networkConnectFuture = GeneralUtil.checkNetworkConnect();
    var locationState = await ph.Permission.location.status;
    if (!(locationState == ph.PermissionStatus.denied)) {
      locationEnabled = true;
      print("has location permission");
      injectProvider();
    } else {
      var request = await ph.Permission.location.request();
      print(request);
      if (request == ph.PermissionStatus.denied ||
          request == ph.PermissionStatus.permanentlyDenied) {
        print("show exit dialog");
        showDialog(
          context: context,
          builder: (context) {
            return AlertDialog(
              content: Column(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: const [Text("現在位置へのアクセスを許可してください")]),
              actions: [
                TextButton(
                    onPressed: () {
                      exit(1);
                    },
                    child: Text("OK"))
              ],
            );
          },
        );
      } else {
        print("arrowed locaiton permission");
        locationEnabled = true;
        injectProvider();
      }
    }
    var notificationState = await ph.Permission.notification.status;
    print("notificatio state ${notificationState}");
    // Map<ph.Permission, ph.PermissionStatus> statuses =
    //     await [ph.Permission.location, ph.Permission.notification].request();
    // // iOSの場合はこのif文では不十分
    // for (ph.Permission p in statuses.keys) {
    //   print("permission $p");
    // }
    // for (ph.PermissionStatus state in statuses.values) {
    //   print("state: ${state}");
    // }
    // if (statuses[ph.Permission.location] == PermissionStatus.granted) {
    //   print("X");
    //   locationEnabled = true;
    // }
    // if (statuses[ph.Permission.notification] == PermissionStatus.granted) {
    //   hasNotificationPermission = true;
    //   print("Y");
    // }
    // Future<bool> permissionStateFuture = GeneralUtil.checkLocationPermission();
    // Future<bool> notificationPermissionState =
    //     GeneralUtil.checkNotificationPermission();
    Future f = Future.wait([
      networkConnectFuture,
      // permissionStateFuture,
      // notificationPermissionState
    ]);
    f.then((value) {
      List<bool> resultList = value as List<bool>;
      networkConnect = resultList[0];
      // locationEnabled = resultList[1];
      // hasNotificationPermission = resultList[2];
      print("f.then");
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
              pointList: ref.read(savedDataProvider).pointList,
            )));
    // 今の段階では値を受け取ていないが将来的に使う事になりそう
    if (result == null) return;
    Point p = result as Point;
    print("result: ${p.name}");
    LatLng? lng = pickedMarker?.point;
    if (lng != null &&
        lng.latitude == p.latitude &&
        lng.longitude == p.longitude) {
      pickedMarker = null;
    }
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
    mapController!.move(LatLng(p.latitude, p.longitude), mapController!.zoom);
    setState(() {});
  }

  Future<void> searchPlace(String query) {
    if (query == "") return Future.value();
    isSearching = true;
    setState(() {});
    String url = ConstantValue.GASbaseURL + "?query=" + query;
    return http.get(Uri.parse(url)).then((value) {
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
      setState(() {});
    });
  }

  void injectProvider() {
    print("injectProvider");
    currentLocationStateProvider =
        StreamProvider.autoDispose<LocationData>((ref) {
      // Geolocatorを使うコード
      // LocationSettings locationSettings =
      //     const LocationSettings(accuracy: LocationAccuracy.best);
      // return Geolocator.getPositionStream(locationSettings: locationSettings)
      //     .map((pos) {
      //   ref.read(currentLocationProvider.notifier).state = pos;
      //   print("lat: ${pos.latitude} lon: ${pos.longitude}");
      //   return pos;
      // });

      Location location = Location();
      location.enableBackgroundMode(enable: true);

      return location.onLocationChanged.map((LocationData locationData) {
        if (locationData != null) {
          print(
              "locationData latitude: ${locationData.latitude} longitude: ${locationData.longitude}");
          ref.read(currentLocationProvider.notifier).state = CurrentLocation(
              latitude: locationData.latitude!,
              longitude: locationData.longitude!);
        }
        SavedData savedData = ref.read(savedDataProvider.notifier).state;
        print("YYY: ${savedData.pointList.length}");
        List<Point> activeList = ref
            .read(savedDataProvider.notifier)
            .state
            .pointList
            .where((element) => element.isActive)
            .toList();
        CurrentLocation currentLocation =
            ref.read(currentLocationProvider.notifier).state;
        activeList.forEach((point) {
          double distance = Geolocator.distanceBetween(
              point.latitude,
              point.longitude,
              currentLocation.latitude,
              currentLocation.longitude);
          print("distance: $distance ringed: ${point.isRinged}");
          if (distance <= Setting.th_meter && !point.isRinged) {
            print("通知を出す処理");
            GeneralUtil.notify(
              title: "${point.name}に近づきました",
              body: "目的地に近づきました",
              id: point.latitude.toInt(),
            );
            point.isRinged = true;
            int idx = savedData.pointList.indexOf(point);
            List<Point> newPointList = savedData.pointList;
            if (idx != -1) {
              newPointList[idx] = point;
              ref.read(savedDataProvider.notifier).state = SavedData(
                  pointList: newPointList, routeList: savedData.routeList);
            }
          }
        });
        return locationData;
      });
    });
// これらはこの画面でしか使う予定はないので共有する必要はない

    savedDataStateProvider = FutureProvider.autoDispose<SavedData>((ref) async {
      database ??= await GeneralUtil.getAppDatabase();
      // Future<List<Map<String, dynamic>>> dataList =
      late SavedData data;
      Future f1 = database!
          .rawQuery("select * from ${ConstantValue.pointTable}")
          .then((value) {
        List<Point> pointList = List.generate(value.length, (index) {
          String name = value[index]["name"] as String;
          double latitude = double.parse(value[index]["latitude"] as String);
          double longitude = double.parse(value[index]["longitude"] as String);
          return Point(name: name, latitude: latitude, longitude: longitude);
        });
        data = SavedData(pointList: pointList, routeList: []);
        ref.read(savedDataProvider.notifier).state = data;
      });

      // Future f2 = database!
      //     .rawQuery("select * from ${ConstantValue.routeTable}")
      //     .then((value) {
      //   List<RoutePass> routeList = List.generate(value.length, (index) {
      //     String name = value[index]["name"] as String;
      //     List<Point> pointList = value[index]["pointList"] as List<Point>;
      //     return RoutePass(name: name, pointList: pointList);
      //   });
      //   print("routeList size: ${routeList.length}");
      // });

      // await Future.wait([f1, f2]).then((value) {
      //   data = SavedData(pointList: value[0], routeList: value[1]);
      //   ref.read(savedDataProvider.notifier).state = data;
      // });
      await f1;
      return Future.value(data);
    });
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    mapController = MapController();
    setUp();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    mapController?.dispose();
    super.dispose();
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
    ref.watch(currentLocationStateProvider!);
    ref.watch(savedDataStateProvider!);
    final currentLocation = ref.watch(currentLocationProvider);
    final savedData = ref.watch(savedDataProvider);
    final savedDataController = ref.read(savedDataProvider.notifier);
    // mapController.move(
    //     LatLng(currentLocation.latitude, currentLocation.longitude), 12);
    // print("build ${currentLocation.latitude} ${currentLocation.longitude}");
    if (isMapReady && isTracking) {
      mapController!.move(
          LatLng(currentLocation.latitude, currentLocation.longitude),
          mapController!.zoom);
    }

    acitvePointMarkerList =
        savedData.pointList.where((element) => element.isActive).map((point) {
      return Marker(
        point: LatLng(point.latitude, point.longitude),
        builder: (context) => RotationTransition(
          turns: AlwaysStoppedAnimation(-1 * (mapController!.rotation / 360)),
          child: Icon(
            Icons.location_on_outlined,
            color: Colors.red,
          ),
        ),
      );
    }).toList();

    WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
      print("postFrameCallback");
      List<Point> activeList =
          savedData.pointList.where((element) => element.isActive).toList();
      print("activeList size: ${activeList.length}");
      activeList.forEach((point) {
        double distance = Geolocator.distanceBetween(
            point.latitude,
            point.longitude,
            currentLocation.latitude,
            currentLocation.longitude);
        print("distance: $distance");
        if (distance <= Setting.th_meter && !point.isRinged) {
          print("通知を出す処理");
          GeneralUtil.notify(
            title: "${point.name}に近づきました",
            body: "目的地に近づきました",
            id: point.latitude.toInt(),
          );
          // どうやらbuild時にステートを更新するとbuildが永遠に続いてエラーがでるみたい
          point.isRinged = true;
          int idx = savedData.pointList.indexOf(point);
          List<Point> newPointList = savedData.pointList;
          if (idx != -1) {
            newPointList[idx] = point;
            savedDataController.state = SavedData(
                pointList: newPointList, routeList: savedData.routeList);
          }
        }
      });
    });

    // if (mapController.state.mounted) {
    //   mapController.move(
    //       LatLng(currentLocation.latitude, currentLocation.longitude),
    //       mapController.zoom);
    // }
    // Marker(point: LatLng(1, 1), builder: (context) => Container());
    return Scaffold(
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.settings_outlined),
            onPressed: () {
              // 設定画面へ遷移
              Navigator.of(context).push(MaterialPageRoute(
                builder: (context) => SettingScreen(),
              ));
            },
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.list_outlined),
              onPressed: () {
                // 登録地点一覧画面へ
                navigateToPointListScreen(context);
                // Navigator.of(context).push(MaterialPageRoute(
                //     builder: (context) => PointListScreen(
                //           type: 1,
                //           db: database!,
                //           savedDataProvider: savedDataProvider,
                //         )));
              },
            ),
            IconButton(
              icon: const Icon(Icons.route_outlined),
              onPressed: () {
                // 登録ルート一覧へ
                Navigator.of(context).push(MaterialPageRoute(
                    builder: (context) => PointListScreen(
                          type: 2,
                          db: database!,
                          savedDataProvider: savedDataProvider,
                          pointList: [],
                        )));
              },
            ),
          ],
        ),
        body: Center(
          child: Stack(
            children: <Widget>[
              loading ||
                      currentLocation.latitude == 0 &&
                          currentLocation.longitude == 0
                  ? const LoadingWidget()
                  : networkConnect && locationEnabled
                      ? FlutterMap(
                          mapController: mapController,
                          options: MapOptions(
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
                                // print(p0);
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
                                print("tapped");
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
                                ...acitvePointMarkerList,
                                (currentLocation.latitude != 0 &&
                                        currentLocation.longitude != 0)
                                    ? Marker(
                                        point: LatLng(currentLocation.latitude,
                                            currentLocation.longitude),
                                        builder: (context) {
                                          print("current location marker");
                                          print(
                                              "controller rotation: ${mapController!.rotation}");
                                          return RotationTransition(
                                            turns: AlwaysStoppedAnimation(-1 *
                                                (mapController!.rotation /
                                                    360)),
                                            child: const Icon(
                                                Icons.person_pin_outlined),
                                          );
                                        },
                                      )
                                    : emptyMarker
                              ],
                            )
                          ],
                        )
                      : MessageWidget(
                          netState: networkConnect,
                          permissionState: locationEnabled),
              // 検索バー
              Align(
                alignment: AlignmentDirectional.topCenter,
                child: Container(
                  decoration: BoxDecoration(color: Colors.white),
                  child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          padding: ConstantValue.p8,
                          height: 66,
                          width: MediaQuery.of(context).size.width - 80,
                          child: TextField(
                              controller: searchInputController,
                              style: const TextStyle(fontSize: 18),
                              decoration: InputDecoration(
                                  contentPadding: ConstantValue.p8,
                                  hintText: "場所を検索",
                                  border: OutlineInputBorder(
                                      borderRadius:
                                          BorderRadius.circular(10)))),
                        ),
                        !isSearching
                            ? IconButton(
                                icon: Icon(Icons.search_outlined),
                                onPressed: () {
                                  print(searchInputController.text);
                                  searchPlace(searchInputController.text);
                                },
                              )
                            : CircularProgressIndicator()
                      ]),
                ),
              ),
              searchResult != null
                  ? AnimatedPositioned(
                      duration: const Duration(seconds: 1),
                      bottom: searchResult == null ? -300 : 20,
                      child: Container(
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
                            String building_name =
                                itemData['address_components'][0]['short_name'];
                            String address = itemData['formatted_address'];
                            // print(itemData['geometry']['location']['lat']);

                            double lat = itemData['geometry']['location']['lat']
                                as double;
                            double lon = itemData['geometry']['location']['lng']
                                as double;

                            return Card(
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10)),
                              child: GestureDetector(
                                onTap: () {
                                  isTracking = false;
                                  setState(() {});
                                  mapController!.move(
                                      LatLng(lat, lon), mapController!.zoom);
                                },
                                child: Container(
                                  padding: ConstantValue.cardPadding,
                                  width:
                                      MediaQuery.of(context).size.width * 0.8,
                                  height: 200,
                                  child: Column(children: [
                                    Text(
                                      building_name,
                                      style: ConstantValue.titleText,
                                    ),
                                    Text(
                                      address,
                                      style: TextStyle(fontSize: 14),
                                    )
                                  ]),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    )
                  : Container()
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
                                  onPressed: () {
                                    if (pickedMarker == null) return;
                                    // 追加
                                    print("name: " + editingController.text);
                                    print(
                                        "latitude: ${pickedMarker?.point.latitude} longitude: ${pickedMarker?.point.longitude}");
                                    Point p = Point(
                                        name: editingController.text,
                                        latitude: pickedMarker!.point.latitude,
                                        longitude:
                                            pickedMarker!.point.longitude);
                                    print("add point: ${p.toString()}");
                                    // insertPoint(p);
                                    GeneralUtil.insertPoint(database!, p);
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
            SizedBox(
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
}

class MessageWidget extends StatelessWidget {
  bool netState;
  bool permissionState;
  MessageWidget(
      {super.key, required this.netState, required this.permissionState});
  @override
  Widget build(BuildContext context) {
    print("netState: $netState");
    print("locationState: $permissionState");
    String msg = "問題が発生しました。";
    if (!netState) {
      msg = "ネットワークに接続されていません";
    } else if (!permissionState) {
      msg = "パーミッションが許可されていません。";
    }
    return Center(
      child: Text(
        msg,
        style: ConstantValue.titleText,
      ),
    );
  }
}
