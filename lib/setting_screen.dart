import 'package:flutter/material.dart';
import 'package:flutter/material.dart';
import 'package:flutter/src/widgets/framework.dart';
import 'package:flutter/src/widgets/placeholder.dart';

class SettingScreen extends StatefulWidget {
  const SettingScreen({super.key});

  @override
  State<SettingScreen> createState() => _SettingScreenState();
}

class _SettingScreenState extends State<SettingScreen> {
  int notifyDistance = 500;
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(),
      body: Column(mainAxisAlignment: MainAxisAlignment.start, children: [
        DropDownSettingItem(
            label: "通知する距離",
            defaultVal: notifyDistance,
            itemMap: const {"500m": 500, "800m": 800, "1000m": 1000},
            onValueChange: (int val) {
              print("onValchange" + val.toString());
              notifyDistance = val;
              setState(() {});
            })
      ]),
    );
  }
}

class DropDownSettingItem extends StatefulWidget {
  String label;
  int defaultVal;
  Map<String, Object> itemMap;
  Function(int) onValueChange;
  DropDownSettingItem(
      {super.key,
      required this.label,
      required this.defaultVal,
      required this.itemMap,
      required this.onValueChange});

  @override
  State<DropDownSettingItem> createState() => _DropDownSettingItemState();
}

class _DropDownSettingItemState extends State<DropDownSettingItem> {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text("通知する距離"),
          DropdownButton(
              value: widget.defaultVal,
              items: widget.itemMap.entries
                  .map((e) => DropdownMenuItem(
                        child: Text(e.key),
                        value: e.value,
                      ))
                  .toList(),
              onChanged: (val) {
                widget.defaultVal = val as int;
                widget.onValueChange(val);
                // setState(() {});
                // print(widget.defaultVal);
              })
        ],
      ),
    );
  }
}
