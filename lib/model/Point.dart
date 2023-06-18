class Point {
  late String name;
  late double latitude;
  late double longitude;
  bool isActive = false;
  bool isRinged = false;
  Point({required this.name, required this.latitude, required this.longitude});

  @override
  String toString() {
    // TODO: implement toString
    return "name: $name latitude: $latitude longitude: $longitude";
  }
}
