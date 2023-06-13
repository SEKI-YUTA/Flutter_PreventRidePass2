import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:prevent_ride_pass2/ConstantValue.dart';
import 'package:prevent_ride_pass2/model/Point.dart';

class PointCard extends StatelessWidget {
  const PointCard({
    super.key,
    required this.p,
  });

  final Point p;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Container(
        padding: ConstantValue.cardPadding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  p.name,
                  style: ConstantValue.titleText,
                ),
                IconButton(
                  icon: const Icon(Icons.map_outlined),
                  onPressed: () {
                    // 地図で場所を表示
                  },
                )
              ],
            ),
            Text("緯度: " + p.latitude.toString()),
            Text("経度: " + p.longitude.toString())
          ],
        ),
      ),
    );
  }
}
