import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:prevent_ride_pass2/ConstantValue.dart';
import 'package:prevent_ride_pass2/model/Point.dart';
import 'package:prevent_ride_pass2/model/Route.dart';

class RoutePassCard extends StatelessWidget {
  const RoutePassCard({
    super.key,
    required this.r,
  });

  final RoutePass r;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Container(
        padding: ConstantValue.cardPadding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(r.name, style: ConstantValue.titleText),
            // Text("緯度: " + p.latitude.toString()),
            // Text("経度: " + p.longitude.toString())
          ],
        ),
      ),
    );
  }
}
