import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:path/path.dart';
import 'package:prevent_ride_pass2/ConstantValue.dart';
import 'package:prevent_ride_pass2/model/Point.dart';
import 'package:prevent_ride_pass2/model/SavedData.dart';
import 'package:prevent_ride_pass2/point_list.screen.dart';
import 'package:prevent_ride_pass2/setting_screen.dart';
import 'package:prevent_ride_pass2/util/GeneralUtil.dart';
import 'package:prevent_ride_pass2/widget/LoadingWidget.dart';
import 'package:sqflite/sqflite.dart';

// https://github.com/SEKI-YUTA/Flutter_PreventRidePass/blob/master/lib/map_screen.dart
// https://pub.dev/packages/sqflite

// これらはこの画面でしか使う予定はないので共有する必要はない
final currentLocationProvider = StateProvider<Position>((ref) {
  return Position(
      longitude: 0,
      latitude: 0,
      timestamp: DateTime.now(),
      accuracy: 0,
      altitude: 0,
      heading: 0,
      speed: 0,
      speedAccuracy: 0);
});
final curretLocationStateProvider = StreamProvider.autoDispose<Position>((ref) {
  LocationSettings locationSettings =
      const LocationSettings(accuracy: LocationAccuracy.best);
  return Geolocator.getPositionStream(locationSettings: locationSettings)
      .map((pos) {
    print("pos ${pos.latitude} ${pos.longitude}");
    ref.read(currentLocationProvider.notifier).state = pos;
    print("lat: ${pos.latitude} lon: ${pos.longitude}");
    return pos;
  });
});
// これらはこの画面でしか使う予定はないので共有する必要はない
final savedDataProvider = StateProvider<SavedData>((ref) {
  return SavedData(pointList: [], routeList: []);
});

final savedDataStateProvider =
    FutureProvider.autoDispose<SavedData>((ref) async {
  if (database == null) {
    database = await GeneralUtil.getAppDatabase();
  }
  // Future<List<Map<String, dynamic>>> dataList =
  late SavedData data;
  await database!
      .rawQuery("select * from ${ConstantValue.pointTable}")
      .then((value) {
    List<Point> pointList = List.generate(value.length, (index) {
      String name = value[index]["name"] as String;
      double latitude = double.parse(value[index]["latitude"] as String);
      double longitude = double.parse(value[index]["longitude"] as String);
      return Point(name: name, latitude: latitude, longitude: longitude);
    });
    print(pointList.length);
    data = SavedData(pointList: pointList, routeList: []);
    ref.read(savedDataProvider.notifier).state = data;
  });

  return Future.value(data);
});

Database? database;

class MapScreen extends ConsumerStatefulWidget {
  const MapScreen({super.key, required this.title});
  final String title;

  @override
  _MapScreenState createState() => _MapScreenState();
}

class _MapScreenState extends ConsumerState<MapScreen>
    with WidgetsBindingObserver {
  MapController mapController = MapController();
  // late Database database;
  bool locationEnabled = false;
  bool networkConnect = false;
  bool loading = true;

  int _counter = 0;
  List<Marker> markerList = List.empty(growable: true);
  Marker? pickedMarker = null;
  Marker? activeMarker = null;

  setPickedMarker(LatLng pos) {
    pickedMarker = Marker(
        point: pos,
        builder: (context) => GestureDetector(
              child: Icon(Icons.location_on_outlined),
              onLongPress: () {
                pickedMarker = null;
                setState(() {});
              },
            ));
  }

  Future<bool> checkPermission() async {
    bool serviceEnabled;
    LocationPermission permission;
    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      // Location services are not enabled don't continue
      // accessing the position and request users of the
      // App to enable the location services.
      return Future.error('Location services are disabled.');
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        // Permissions are denied, next time you could try
        // requesting permissions again (this is also where
        // Android's shouldShowRequestPermissionRationale
        // returned true. According to Android guidelines
        // your App should show an explanatory UI now.
        return Future.error('Location permissions are denied');
      }
    }

    if (permission == LocationPermission.deniedForever) {
      // Permissions are denied forever, handle appropriately.
      return Future.error(
          'Location permissions are permanently denied, we cannot request permissions.');
    }
    bool result = (permission == LocationPermission.whileInUse ||
            permission == LocationPermission.always)
        ? true
        : false;
    return result;
  }

  void setUp() async {
    // locationEnabled = await checkPermission();
    if (database == null) {
      database = await GeneralUtil.getAppDatabase();
    }

    Future<bool> networkConnectFuture = GeneralUtil.checkNetworkConnect();
    Future<bool> permissionStateFuture = checkPermission();
    Future f = Future.wait([networkConnectFuture, permissionStateFuture]);
    f.then((value) {
      List<bool> resultList = value as List<bool>;
      networkConnect = resultList[0];
      locationEnabled = resultList[1];
      loading = false;
    });
  }

  Future<void> navigateToPointListScreen(BuildContext context) async {
    final result = await Navigator.of(context).push(MaterialPageRoute(
        builder: (context) => PointListScreen(
            type: 1, db: database!, savedDataProvider: savedDataProvider)));
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
        builder: (context) => GestureDetector(
              child: const Icon(
                Icons.location_pin,
                color: Colors.red,
              ),
            ));
    setState(() {});
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    setUp();
  }

  @override
  void dispose() {
    // TODO: implement dispose
    super.dispose();
    WidgetsBinding.instance.removeObserver(this);
  }

  @override
  Widget build(BuildContext context) {
    ref.watch(curretLocationStateProvider);
    ref.watch(savedDataStateProvider);
    final currentLocation = ref.watch(currentLocationProvider);
    final savedData = ref.watch(savedDataProvider);
    final savedDataController = ref.read(savedDataProvider.notifier);
    // mapController.move(
    //     LatLng(currentLocation.latitude, currentLocation.longitude), 12);
    var emptyMarker =
        Marker(point: LatLng(1, 1), builder: (context) => Container());
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
                      )));
            },
          ),
        ],
      ),
      body: Center(
        child: Stack(
          children: <Widget>[
            loading
                ? LoadingWidget()
                : networkConnect && locationEnabled
                    ? FlutterMap(
                        mapController: mapController,
                        options: MapOptions(
                            center:
                                LatLng(34.70880958006056, 135.64355656940705),
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
                                'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                          ),
                          MarkerLayer(
                            markers: [
                              pickedMarker ?? emptyMarker,
                              activeMarker ?? emptyMarker,
                              (currentLocation.latitude != 0 &&
                                      currentLocation.longitude != 0)
                                  ? Marker(
                                      point: LatLng(currentLocation.latitude,
                                          currentLocation.longitude),
                                      builder: (context) {
                                        return const Icon(
                                            Icons.person_pin_outlined);
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
                padding: ConstantValue.cardPadding,
                child: Container(
                  decoration: BoxDecoration(color: Colors.white),
                  child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: MediaQuery.of(context).size.width - 80,
                          child: TextField(
                            decoration:
                                ConstantValue.createPlaceholderDecoration(
                                    "場所を検索"),
                          ),
                        ),
                        IconButton(
                          icon: Icon(Icons.search_outlined),
                          onPressed: () {},
                        )
                      ]),
                ),
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: pickedMarker != null
          ? FloatingActionButton(
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
                                  longitude: pickedMarker!.point.longitude);
                              // insertPoint(p);
                              GeneralUtil.insertPoint(database!, p);
                              List<Point> tmpList = savedData.pointList;
                              tmpList.add(p);
                              savedDataController.state = SavedData(
                                  pointList: tmpList,
                                  routeList: savedData.routeList);
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
                      content:
                          Column(mainAxisSize: MainAxisSize.min, children: [
                        Container(
                          child: TextField(
                              decoration:
                                  ConstantValue.createPlaceholderDecoration(
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
    );
  }
}

class MessageWidget extends StatelessWidget {
  bool netState;
  bool permissionState;
  MessageWidget(
      {super.key, required this.netState, required this.permissionState});

  @override
  Widget build(BuildContext context) {
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
