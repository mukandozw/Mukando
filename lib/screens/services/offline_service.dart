import 'package:hive_flutter/hive_flutter.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

class OfflineService {
  static late Box offlineBox;
  static late Box membersBox;
  static late Box groupsBox;

  static Future<void> init() async {
    await Hive.initFlutter();
    offlineBox = await Hive.openBox('offline_queue');
    membersBox = await Hive.openBox('members_local');
    groupsBox = await Hive.openBox('groups_local');
  }

  // Check internet
  static Future<bool> isOnline() async {
    var result = await Connectivity().checkConnectivity();
    return result != ConnectivityResult.none;
  }

  // Save offline when no internet
  static Future<void> saveOffline(String table, Map data) async {
    String localId = const Uuid().v4();
    data['local_id'] = localId;
    data['synced'] = false;
    data['created_at'] = DateTime.now().toIso8601String();

    if (table == 'members') {
      await membersBox.put(localId, data);
    } else if (table == 'groups') {
      await groupsBox.put(localId, data);
    }

    // Queue for sync
    await offlineBox.add({'table': table, 'data': data, 'local_id': localId});

    // Try sync if online
    if (await isOnline()) {
      await syncAll();
    }
  }

  // Sync all queued when internet comes
  static Future<void> syncAll() async {
    if (!await isOnline()) return;

    for (int i = offlineBox.length - 1; i >= 0; i--) {
      var item = offlineBox.getAt(i);
      if (item == null) continue;
      try {
        Map<String, dynamic> toSync = Map<String, dynamic>.from(item['data']);
        toSync.remove('local_id');
        toSync.remove('synced');
        
        await Supabase.instance.client.from(item['table']).insert(toSync);
        
        // Remove from queue after success
        await offlineBox.deleteAt(i);
      } catch (e) {
        print("Sync failed: $e");
      }
    }
  }

  static List getLocalGroups() {
    return groupsBox.values.toList();
  }

  static List getLocalMembers(String groupName) {
    return membersBox.values.where((m) => m['group_name'] == groupName).toList();
  }
}
