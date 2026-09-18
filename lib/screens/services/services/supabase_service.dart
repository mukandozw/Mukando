import 'package:supabase_flutter/supabase_flutter.dart';
import 'offline_service.dart';

class SupabaseService {
  static final client = Supabase.instance.client;

  // Get groups - online or offline
  static Future<List> getGroups() async {
    try {
      if (await OfflineService.isOnline()) {
        var data = await client.from('groups').select().order('created_at', ascending: false);
        // Cache locally
        for (var g in data) {
          await OfflineService.groupsBox.put(g['name'], g);
        }
        return data;
      } else {
        // OFFLINE - return local
        return OfflineService.groupsBox.values.toList();
      }
    } catch (e) {
      return OfflineService.groupsBox.values.toList();
    }
  }

  // Get members
  static Future<List> getMembers(String groupName) async {
    try {
      if (await OfflineService.isOnline()) {
        var data = await client.from('members').select().eq('group_name', groupName);
        return data;
      } else {
        return OfflineService.getLocalMembers(groupName);
      }
    } catch (e) {
      return OfflineService.getLocalMembers(groupName);
    }
  }

  // Create group
  static Future<void> createGroup(String name, String type, int amount) async {
    Map data = {
      'name': name, 
      'type': type, 
      'monthly_amount': amount, 
      'total_members': 0
    };
    
    if (await OfflineService.isOnline()) {
      await client.from('groups').insert(data);
      await OfflineService.groupsBox.put(name, data);
    } else {
      await OfflineService.saveOffline('groups', data);
    }
  }

  // Add member
  static Future<void> addMember(String groupName, String name, String phone, String type) async {
    Map data = {
      'group_name': groupName, 
      'name': name, 
      'phone': phone, 
      'type': type, 
      'amount': 50, 
      'savings': 0, 
      'personal_interest_ledger': 0
    };
    
    if (await OfflineService.isOnline()) {
      await client.from('members').insert(data);
    } else {
      await OfflineService.saveOffline('members', data);
    }
  }
}
