import 'package:flutter/material.dart';
import 'package:flutter/material.dart';
import 'package:flutter/src/widgets/framework.dart';
import 'package:flutter/src/widgets/placeholder.dart';
import 'package:prevent_ride_pass2/ConstantValue.dart';
import 'package:prevent_ride_pass2/model/Setting.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingScreen extends StatefulWidget {
  SettingScreen({super.key, required this.setting, required this.cacllback});
  Setting setting;
  Function(Setting s) cacllback;

  @override
  State<SettingScreen> createState() => _SettingScreenState();
}

class _SettingScreenState extends State<SettingScreen> {
  int notifyDistance = 500;
  SharedPreferences? preferences;

  @override
  void initState() {
    super.initState();
    setUp();
  }

  void setUp() async {
    preferences = await SharedPreferences.getInstance();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(),
      body: Column(mainAxisAlignment: MainAxisAlignment.start, children: [
        DropDownSettingItem(
            label: "通知する距離",
            defaultVal: notifyDistance,
            itemMap: const {
              "100m": 100,
              "300m": 300,
              "500m": 500,
              "800m": 800,
              "1000m": 1000
            },
            onValueChange: (int val) {
              if (widget.setting == null) print("setting is null");
              Setting newSetting = widget.setting.copyWith(thMeter: val);
              newSetting = newSetting.copyWith(faliled: false);
              print("onValchange" + val.toString());
              preferences!.setString(
                  ConstantValue.settingStrKey, newSetting.toJson().toString());
              widget.cacllback(newSetting);
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
