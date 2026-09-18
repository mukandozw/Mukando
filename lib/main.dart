import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'screens/create_group_screen.dart';
import 'screens/group_detail.dart';
import 'services/offline_service.dart';
import 'services/supabase_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await OfflineService.init();
  await Supabase.initialize(
    url: 'https://dmlqxgsmsrhccukoegtw.supabase.co',
    anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImRtbHF4Z3Ntc3JoY2N1a29lZ3R3Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3ODk3MzQwNjksImV4cCI6MjEwNTMxMDA2OX0.8pXf-PtnEKsZvXbpxXAxehJqGcCniaALYMUNZZr-zzc',
  );
  runApp(MukandoApp());
}

class MukandoApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(title: 'MukandoZW', theme: ThemeData(primarySwatch: Colors.blue), home: HomeScreen(), debugShowCheckedModeBanner: false);
  }
}

class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List groups = [];
  bool loading = true;
  bool isOffline = false;
  @override
  void initState() { super.initState(); loadGroups(); }
  loadGroups() async {
    setState(()=> loading = true);
    var online = await OfflineService.isOnline();
    setState(()=> isOffline =!online);
    var data = await SupabaseService.getGroups();
    setState(() { groups = data; loading = false; });
    if(online) await OfflineService.syncAll();
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text("MukandoZW - My Groups"), if(isOffline) Text("OFFLINE MODE - Will sync", style: TextStyle(fontSize: 10, color: Colors.yellow))]), backgroundColor: Colors.blue[900], actions: [IconButton(icon: Icon(Icons.sync), onPressed: () async { await OfflineService.syncAll(); loadGroups(); })]),
      body: loading? Center(child: CircularProgressIndicator()) : groups.isEmpty? Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(Icons.group_add, size: 80, color: Colors.grey), Text("No groups - Tap + to create"), Text("Works offline in Bindura!", style: TextStyle(fontSize: 12))])) : ListView.builder(itemCount: groups.length, itemBuilder: (_, i){ var g = groups[i]; bool notSynced = g['synced']==false; return Card(child: ListTile(leading: CircleAvatar(backgroundColor: Colors.blue[900], child: Text(g['name'][0].toUpperCase(), style: TextStyle(color: Colors.white))), title: Row(children: [Expanded(child: Text(g['name'], style: TextStyle(fontWeight: FontWeight.bold))), if(notSynced) Container(padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2), decoration: BoxDecoration(color: Colors.orange, borderRadius: BorderRadius.circular(10)), child: Text("OFFLINE", style: TextStyle(fontSize: 8, color: Colors.white)))]), subtitle: Text("${g['type']} • \$${g['monthly_amount']}/mo"), trailing: Icon(Icons.arrow_forward), onTap: ()=> Navigator.push(context, MaterialPageRoute(builder: (_)=> GroupDetailScreen(groupName: g['name'], groupType: g['type']))))); }),
      floatingActionButton: FloatingActionButton.extended(onPressed: () async { await Navigator.push(context, MaterialPageRoute(builder: (_)=> CreateGroupScreen())); loadGroups(); }, label: Text("NEW GROUP"), icon: Icon(Icons.add), backgroundColor: Colors.blue[900]),
    );
  }
}
