import 'package:flutter/material.dart';
import '../services/supabase_service.dart';
import '../services/offline_service.dart';

class CreateGroupScreen extends StatefulWidget {
  @override
  _CreateGroupScreenState createState() => _CreateGroupScreenState();
}

class _CreateGroupScreenState extends State<CreateGroupScreen> {
  TextEditingController nameCtrl = TextEditingController();
  TextEditingController amountCtrl = TextEditingController(text: "50");
  String selectedType = 'savingsLoans';

  Map<String, String> typeNames = {
    'rotating': 'Type 1: Rotating (Round)',
    'savingsLoans': 'Type 2: Savings + Loans - FLAGSHIP 90%',
    'grocery': 'Type 3: Grocery - Bulk Buy',
    'project': 'Type 4: Project - Goal Locked',
  };

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Name Your Group"), backgroundColor: Colors.blue[900]),
      body: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            FutureBuilder<bool>(
              future: OfflineService.isOnline(),
              builder: (_, snap){
                bool offline = snap.data == false;
                return offline? Container(width: double.infinity, padding: EdgeInsets.all(8), color: Colors.orange[100], child: Text("⚠️ OFFLINE - Group will save locally & sync later", style: TextStyle(color: Colors.orange[900]))): SizedBox();
              }
            ),
            SizedBox(height: 10),
            TextField(
              controller: nameCtrl,
              decoration: InputDecoration(labelText: "Group Name", hintText: "e.g. Bindura Teachers", border: OutlineInputBorder(), prefixIcon: Icon(Icons.group)),
            ),
            SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: selectedType,
              decoration: InputDecoration(labelText: "Type", border: OutlineInputBorder()),
              items: typeNames.entries.map((e) => DropdownMenuItem(value: e.key, child: Text(e.value, style: TextStyle(fontSize: 12)))).toList(),
              onChanged: (v) => setState(() => selectedType = v!),
            ),
            SizedBox(height: 16),
            TextField(controller: amountCtrl, decoration: InputDecoration(labelText: "Monthly Amount", border: OutlineInputBorder(), prefixText: "\$ "), keyboardType: TextInputType.number),
            SizedBox(height: 12),
            Container(
              padding: EdgeInsets.all(10),
              color: Colors.blue[50],
              child: Text(
                selectedType == 'rotating'? "Type 1: Each month one person gets all."
                : selectedType == 'savingsLoans'? "Type 2 FLAGSHIP: Save, borrow 90% instantly. Interest goes back to YOU."
                : selectedType == 'grocery'? "Type 3: Vote what to buy, bulk discount, receipt proof."
                : "Type 4: Lock money for Borehole, Roof, Fees - goal based.",
                style: TextStyle(fontSize: 12),
              ),
            ),
            Spacer(),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.blue[900], minimumSize: Size(double.infinity, 56)),
              onPressed: () async {
                String gName = nameCtrl.text.trim().toLowerCase().replaceAll(RegExp(r'\s+'), '_');
                if (gName.isEmpty) { ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Enter group name!"))); return; }
                int amt = int.tryParse(amountCtrl.text)??50;
                await SupabaseService.createGroup(gName, selectedType, amt);
                bool online = await OfflineService.isOnline();
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(online? "Group '$gName' created!" : "Saved OFFLINE! Will sync when data comes"), backgroundColor: online? Colors.green : Colors.orange));
                Navigator.pop(context);
              },
              child: Text("CREATE GROUP", style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }
}
