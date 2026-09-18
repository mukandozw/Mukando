import 'package:flutter/material.dart';
import '../services/supabase_service.dart';
import '../services/offline_service.dart';

class GroupDetailScreen extends StatefulWidget {
  final String groupName;
  final String groupType;
  GroupDetailScreen({required this.groupName, required this.groupType});
  @override _GroupDetailScreenState createState() => _GroupDetailScreenState();
}

class _GroupDetailScreenState extends State<GroupDetailScreen> {
  List members = [];
  bool isOffline = false;

  @override
  void initState(){ super.initState(); loadMembers(); }

  loadMembers() async {
    isOffline =!await OfflineService.isOnline();
    var data = await SupabaseService.getMembers(widget.groupName);
    setState(()=> members = data);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(widget.groupName), if(isOffline) Text("OFFLINE", style: TextStyle(fontSize: 10, color: Colors.yellow))]),
        backgroundColor: Colors.blue[900]
      ),
      body: Column(children: [
        Container(padding: EdgeInsets.all(16), color: Colors.blue[50], width: double.infinity, child: Text("Type: ${widget.groupType} • ${members.length} Members", style: TextStyle(fontWeight: FontWeight.bold))),
        Expanded(child: members.isEmpty? Center(child: Text("No members yet - Add offline works!")) : ListView.builder(itemCount: members.length, itemBuilder: (_, i){
          var m = members[i];
          bool notSynced = m['synced'] == false;
          return ListTile(
            leading: Stack(children: [CircleAvatar(child: Text(m['name'][0].toUpperCase())), if(notSynced) Positioned(right: 0, child: Icon(Icons.cloud_off, size: 12, color: Colors.orange))]),
            title: Text(m['name']),
            subtitle: Text("${m['phone']} • Savings: \$${m['savings']} ${notSynced? '(offline)' : ''}")
          );
        })),
      ]),
      floatingActionButton: FloatingActionButton(onPressed: () async {
        TextEditingController n = TextEditingController();
        TextEditingController p = TextEditingController();
        showDialog(context: context, builder: (_) => AlertDialog(
          title: Text("Add to ${widget.groupName}"),
          content: Column(mainAxisSize: MainAxisSize.min, children: [
            TextField(controller: n, decoration: InputDecoration(labelText: "Name")),
            TextField(controller: p, decoration: InputDecoration(labelText: "Phone"))
          ]),
          actions: [ElevatedButton(onPressed: () async {
          await SupabaseService.addMember(widget.groupName, n.text, p.text, widget.groupType);
          Navigator.pop(context);
          loadMembers();
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(isOffline? "Saved offline!" : "Member added!")));
        }, child: Text("Add"))]));
      }, child: Icon(Icons.person_add)),
    );
  }
}
