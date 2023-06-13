import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:prevent_ride_pass2/point_list.screen.dart';
import 'package:prevent_ride_pass2/setting_screen.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({super.key, required this.title});
  final String title;

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  int _counter = 0;
  List<Marker> markerList = List.empty(growable: true);
  Marker? pickedMarker = null;

  setPickedMarker(LatLng pos) {
    pickedMarker = Marker(
        point: pos,
        builder: (context) => IconButton(
              icon: Icon(Icons.location_on_outlined),
              onPressed: () {
                pickedMarker = null;
                setState(() {});
              },
            ));
  }

  @override
  Widget build(BuildContext context) {
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
                  markers: [pickedMarker ?? emptyMarker],
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
              },
              child: const Icon(Icons.add),
            )
          : Container(),
    );
  }
}
