import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'screens/create_group_screen.dart';
import 'screens/group_detail.dart';
import 'services/offline_service.dart';
import 'services/supabase_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Hive.initFlutter();
  await OfflineService.init();
  await Supabase.initialize(
    url: 'https://YOUR_PROJECT.supabase.co',
    anonKey: 'YOUR_ANON_KEY',
  );
  runApp(MukandoApp());
}

class MukandoApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'MukandoZW',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: HomeScreen(),
      debugShowCheckedModeBanner: false,
    );
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
  void initState() {
    super.initState();
    loadGroups();
  }

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
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("MukandoZW - My Groups"),
            if(isOffline) Text("OFFLINE MODE - Will sync later", style: TextStyle(fontSize: 10, color: Colors.yellow))
          ],
        ),
        backgroundColor: Colors.blue[900],
        actions: [
          IconButton(icon: Icon(Icons.cloud_sync), onPressed: () async { await OfflineService.syncAll(); loadGroups(); }),
          IconButton(icon: Icon(Icons.refresh), onPressed: loadGroups)
        ],
      ),
      body: loading
        ? Center(child: CircularProgressIndicator())
          : groups.isEmpty
            ? Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                  Icon(Icons.group_add, size: 80, color: Colors.grey),
                  SizedBox(height: 16),
                  Text(isOffline? "No groups offline yet" : "No groups yet", style: TextStyle(fontSize: 18)),
                  Text("Tap + to name your first group - Works offline!"),
                ]))
              : RefreshIndicator(
                onRefresh: () async => loadGroups(),
                child: ListView.builder(
                  itemCount: groups.length,
                  itemBuilder: (_, i) {
                    var g = groups[i];
                    bool notSynced = g['synced'] == false;
                    String typeLabel = g['type']=='rotating'?'Type1 Rotating': g['type']=='savingsLoans'?'Type2 Savings+Loans': g['type']=='grocery'?'Type3 Grocery': 'Type4 Project';
                    return Card(
                      child: ListTile(
                        leading: Stack(children: [
                          CircleAvatar(backgroundColor: Colors.blue[900], child: Text(g['name'][0].toUpperCase(), style: TextStyle(color: Colors.white))),
                          if(notSynced) Positioned(right: 0, child: Icon(Icons.cloud_off, size: 14, color: Colors.orange))
                        ]),
                        title: Row(children: [
                          Expanded(child: Text(g['name'], style: TextStyle(fontWeight: FontWeight.bold))),
                          if(notSynced) Container(padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2), decoration: BoxDecoration(color: Colors.orange, borderRadius: BorderRadius.circular(10)), child: Text("OFFLINE", style: TextStyle(fontSize: 8, color: Colors.white)))
                        ]),
                        subtitle: Text("$typeLabel • \$${g['monthly_amount']}/mo"),
                        trailing: Icon(Icons.arrow_forward),
                        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => GroupDetailScreen(groupName: g['name'], groupType: g['type']))),
                      ),
                    );
                  },
                ),
              ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          await Navigator.push(context, MaterialPageRoute(builder: (_) => CreateGroupScreen()));
          loadGroups();
        },
        label: Text("NEW GROUP - Name it!"),
        icon: Icon(Icons.add),
        backgroundColor: Colors.blue[900],
      ),
    );
  }
}
