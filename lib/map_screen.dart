import 'dart:async';
import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:path/path.dart';
import 'package:prevent_ride_pass2/ConstantValue.dart';
import 'package:prevent_ride_pass2/model/CurrentLocation.dart';
import 'package:prevent_ride_pass2/model/Point.dart';
import 'package:prevent_ride_pass2/point_list.screen.dart';
import 'package:prevent_ride_pass2/setting_screen.dart';
import 'package:sqflite/sqflite.dart';

// https://github.com/SEKI-YUTA/Flutter_PreventRidePass/blob/master/lib/map_screen.dart
// https://pub.dev/packages/sqflite

// これはこの画面でしか使う予定はないので共有する必要はない
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
      LocationSettings(accuracy: LocationAccuracy.best);
  return Geolocator.getPositionStream(locationSettings: locationSettings)
      .map((pos) {
    print("pos ${pos.latitude} ${pos.longitude}");
    ref.read(currentLocationProvider.notifier).state = pos;
    print("lat: ${pos.latitude} lon: ${pos.longitude}");
    return pos;
  });
});

class MapScreen extends ConsumerStatefulWidget {
  const MapScreen({super.key, required this.title});
  final String title;

  @override
  _MapScreenState createState() => _MapScreenState();
}

class _MapScreenState extends ConsumerState<MapScreen>
    with WidgetsBindingObserver {
  MapController mapController = MapController();
  late Database database;
  bool locationEnabled = false;
  int _counter = 0;
  List<Marker> markerList = List.empty(growable: true);
  Marker? pickedMarker = null;

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

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    setUp();
  }

  void setUp() async {
    locationEnabled = await checkPermission();
    String dbPath = await getDatabasesPath();
    String path = join(dbPath, ConstantValue.dbName);
    database =
        await openDatabase(path, version: 1, onCreate: (db, version) async {
      await db.execute(
          "create table ${ConstantValue.pointTable} (id INTEGER PRIMARY KEY, name TEXT, latitude TEXT, longitude TEXT)");
    });
  }

  void insertPoint(Point p) async {
    if (database == null) return;
    await database.transaction((txn) async {
      int insertedId = await txn.rawInsert(
          "insert into ${ConstantValue.pointTable} (name, latitude, longitude) values (?, ?, ?)",
          [p.name, p.latitude, p.longitude]);
      print("inserted id: $insertedId");
    });
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
    final currentLocation = ref.watch(currentLocationProvider);
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
              Navigator.of(context).push(MaterialPageRoute(
                  builder: (context) => PointListScreen(
                        type: 1,
                      )));
            },
          ),
          IconButton(
            icon: const Icon(Icons.route_outlined),
            onPressed: () {
              // 登録ルート一覧へ
              Navigator.of(context).push(MaterialPageRoute(
                  builder: (context) => PointListScreen(
                        type: 2,
                      )));
            },
          ),
        ],
      ),
      body: Center(
        child: Stack(
          children: <Widget>[
            FlutterMap(
              mapController: mapController,
              options: MapOptions(
                  center: LatLng(34.70880958006056, 135.64355656940705),
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
                  urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                ),
                MarkerLayer(
                  markers: [
                    pickedMarker ?? emptyMarker,
                    (currentLocation.latitude != 0 &&
                            currentLocation.longitude != 0)
                        ? Marker(
                            point: LatLng(currentLocation.latitude,
                                currentLocation.longitude),
                            builder: (context) {
                              return const Icon(Icons.person_pin_outlined);
                            },
                          )
                        : emptyMarker
                  ],
                )
              ],
            )
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
                              insertPoint(p);
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
