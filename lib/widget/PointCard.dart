import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:prevent_ride_pass2/ConstantValue.dart';
import 'package:prevent_ride_pass2/model/Point.dart';

class PointCard extends StatefulWidget {
  PointCard(
      {super.key,
      required this.p,
      required this.changeActiveState,
      required this.deleteCallback,
      required this.updateCallback});
  final Point p;
  Function changeActiveState;
  Function(int id) deleteCallback;
  Function(int id, String newName) updateCallback;

  @override
  State<PointCard> createState() => _PointCardState();
}

class _PointCardState extends State<PointCard> {
  late bool active;
  TextEditingController editingController = TextEditingController();
  bool titleEditEnabled = false;

  @override
  void initState() {
    active = widget.p.isActive;
    editingController.text = widget.p.name;
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onLongPressEnd: (details) {
        final pos = details.globalPosition;
        showMenu(
            context: context,
            position: RelativeRect.fromLTRB(pos.dx, pos.dy, 0, 0),
            items: [
              PopupMenuItem(
                child: const Text("削除"),
                onTap: () {
                  print("delete tapped");
                  Future.delayed(Duration.zero, () {
                    _showDeleteDialog(context);
                  });
                },
              ),
              PopupMenuItem(
                child: const Text("編集"),
                onTap: () {
                  // widget.updateCallback();
                    titleEditEnabled = true;
                  setState(() {
                  });
                },
              )
            ]);
      },
      child: Card(
        child: Container(
          padding: ConstantValue.cardPadding,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    width: MediaQuery.of(context).size.width * 0.8,
                    child: TextField(
                      onSubmitted: (text) {
                        _updateTitle(text);
                        widget.updateCallback(widget.p.id, text);
                        setState(() {
                          titleEditEnabled = false;
                        });
                      },
                      enabled: titleEditEnabled,
                      controller: editingController,
                      style: ConstantValue.titleText,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.map_outlined),
                    onPressed: () {
                      // 地図で場所を表示
                      Navigator.pop(context, widget.p);
                    },
                  )
                ],
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    children: [
                      Text("緯度: " + widget.p.latitude.toString()),
                      Text("経度: " + widget.p.longitude.toString())
                    ],
                  ),
                  Switch(
                      value: active,
                      onChanged: (val) => setState(() {
                            active = val;
                            widget.changeActiveState(val);
                          }))
                ],
              )
            ],
          ),
        ),
      ),
    );
  }

  void _showDeleteDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("本当に削除しますか？"),
          actions: [
            TextButton(
              onPressed: () {
                // 削除
                widget.deleteCallback(widget.p.id);
                Navigator.pop(context);
              },
              child: const Text("削除する"),
            ),
            TextButton(
                onPressed: () {
                  // キャンセル
                },
                child: const Text("キャンセル"))
          ],
        );
      },
    );
  }

  void _updateTitle(String text) {
    setState(() {
      widget.p.name = text;
    });
  }
}
