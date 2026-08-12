import 'package:hive_flutter/hive_flutter.dart';

class HiveBoxes {
  static const String zonesBoxName = 'zones_cache';
  static const String studentDataBoxName = 'student_data_cache';
  static const String activeRouteBoxName = 'active_route_cache';
  static const String visitQueueBoxName = 'visit_offline_queue';

  static Future<void> init() async {
    await Hive.initFlutter();
    await Hive.openBox(zonesBoxName);
    await Hive.openBox(studentDataBoxName);
    await Hive.openBox(activeRouteBoxName);
    await Hive.openBox(visitQueueBoxName);
  }

  static Box get zonesBox => Hive.box(zonesBoxName);
  static Box get studentDataBox => Hive.box(studentDataBoxName);
  static Box get activeRouteBox => Hive.box(activeRouteBoxName);
  static Box get visitQueueBox => Hive.box(visitQueueBoxName);
}
