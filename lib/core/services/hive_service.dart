import 'package:hive_flutter/hive_flutter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final hiveServiceProvider = Provider<HiveService>((ref) {
  return HiveService();
});

abstract interface class IHiveService {
  Future<void> initialize();
  Future<void> saveData(String boxName, String key, dynamic value);
  Future<dynamic> getData(String boxName, String key);
  Future<void> deleteData(String boxName, String key);
  Future<void> deleteBox(String boxName);
  Future<void> clearAllBoxes();
}

class HiveService implements IHiveService {
  static final HiveService _instance = HiveService._internal();

  factory HiveService() {
    return _instance;
  }

  HiveService._internal();

  @override
  Future<void> initialize() async {
    await Hive.initFlutter();
  }

  @override
  Future<void> saveData(String boxName, String key, dynamic value) async {
    final box = await Hive.openBox(boxName);
    await box.put(key, value);
  }

  @override
  Future<dynamic> getData(String boxName, String key) async {
    final box = await Hive.openBox(boxName);
    return box.get(key);
  }

  @override
  Future<void> deleteData(String boxName, String key) async {
    final box = await Hive.openBox(boxName);
    await box.delete(key);
  }

  @override
  Future<void> deleteBox(String boxName) async {
    await Hive.deleteBoxFromDisk(boxName);
  }

  @override
  Future<void> clearAllBoxes() async {
    await Hive.deleteFromDisk();
  }
}
