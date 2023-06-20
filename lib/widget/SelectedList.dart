import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:prevent_ride_pass2/ConstantValue.dart';
import 'package:prevent_ride_pass2/model/Point.dart';

class SelectedList extends StatelessWidget {
  SelectedList({super.key, required this.selectedList});
  List<Point> selectedList;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 160,
      width: MediaQuery.of(context).size.width * 0.7,
      child: ListView.builder(
        itemCount: selectedList.length,
        itemBuilder: (context, index) {
          print("listview builder");
          Point p = selectedList[index];
          return Card(
            key: Key("pointListKey$index"),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      p.name,
                      style: ConstantValue.titleText,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.remove),
                    onPressed: () {
                      selectedList.remove(p);
                      // copyedPointList.add(p);
                      // setState(() {});
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
    );
  }
}
