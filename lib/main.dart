import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Supabase.initialize(
    url: 'https://dmlqxgsmsrhccukoegtw.supabase.co',
    anonKey: 'sb_publishable_IdKOzFq9xS3cdGFkP6w-Gw_ouQjlpTW',
  );
  runApp(MukandoZWApp());
}

class MukandoZWApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'MukandoZW',
      theme: ThemeData(primarySwatch: Colors.green, useMaterial3: true),
      home: LoginScreen(),
    );
  }
}

class LoginScreen extends StatefulWidget {
  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final phoneCtrl = TextEditingController(text: '+263');
  final pinCtrl = TextEditingController();
  final nameCtrl = TextEditingController();
  bool isLogin = true;
  bool loading = false;
  final supabase = Supabase.instance.client;

  Future<void> auth() async {
    setState(() => loading = true);
    try {
      final phone = phoneCtrl.text.trim();
      final pin = pinCtrl.text.trim();
      if (phone.length < 10 || pin.length != 4) throw 'Phone + 4 digit PIN needed';
      if (isLogin) {
        final res = await supabase.from('app_users').select().eq('phone', phone).eq('pin', pin).maybeSingle();
        if (res == null) throw 'Wrong phone or PIN';
        final p = await SharedPreferences.getInstance();
        await p.setString('uid', res['id']); await p.setString('name', res['name']); await p.setString('phone', res['phone']);
        Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => Dashboard()));
      } else {
        if (nameCtrl.text.isEmpty) throw 'Enter name';
        final ex = await supabase.from('app_users').select().eq('phone', phone).maybeSingle();
        if (ex != null) throw 'Phone exists, login';
        final ins = await supabase.from('app_users').insert({'phone': phone, 'name': nameCtrl.text.trim(), 'pin': pin}).select().single();
        final p = await SharedPreferences.getInstance();
        await p.setString('uid', ins['id']); await p.setString('name', ins['name']); await p.setString('phone', ins['phone']);
        Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => Dashboard()));
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
    } finally { setState(() => loading = false); }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(gradient: LinearGradient(colors: [Colors.green.shade800, Colors.green.shade300], begin: Alignment.topCenter, end: Alignment.bottomCenter)),
        child: Center(
          child: SingleChildScrollView(
            padding: EdgeInsets.all(24),
            child: Card(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              child: Padding(
                padding: EdgeInsets.all(22),
                child: Column(
                  children: [
                    Icon(Icons.groups, size: 70, color: Colors.green),
                    Text('MukandoZW', style: TextStyle(fontSize: 30, fontWeight: FontWeight.bold)),
                    Text('Digitize Every Mukando', style: TextStyle(color: Colors.grey)),
                    SizedBox(height: 20),
                    if (!isLogin) TextField(controller: nameCtrl, decoration: InputDecoration(labelText: 'Full Name', prefixIcon: Icon(Icons.person), border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)))),
                    if (!isLogin) SizedBox(height: 10),
                    TextField(controller: phoneCtrl, decoration: InputDecoration(labelText: 'Phone +263...', prefixIcon: Icon(Icons.phone), border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))), keyboardType: TextInputType.phone),
                    SizedBox(height: 10),
                    TextField(controller: pinCtrl, decoration: InputDecoration(labelText: '4 Digit PIN', prefixIcon: Icon(Icons.lock), border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))), obscureText: true, maxLength: 4, keyboardType: TextInputType.number),
                    SizedBox(height: 10),
                    SizedBox(width: double.infinity, height: 50, child: ElevatedButton(style: ElevatedButton.styleFrom(backgroundColor: Colors.green, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))), onPressed: loading ? null : auth, child: loading ? CircularProgressIndicator(color: Colors.white) : Text(isLogin ? 'LOGIN' : 'CREATE ACCOUNT', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)))),
                    TextButton(onPressed: () => setState(() => isLogin = !isLogin), child: Text(isLogin ? 'New? Create Account' : 'Have account? Login')),
                    SizedBox(height: 8),
                    Text('Super Admin: +263782707006\nchivurotawanda@gmail.com\n© 2026 MukandoZW', textAlign: TextAlign.center, style: TextStyle(fontSize: 10, color: Colors.grey)),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class Dashboard extends StatefulWidget {
  @override
  _DashboardState createState() => _DashboardState();
}

class _DashboardState extends State<Dashboard> {
  final supabase = Supabase.instance.client;
  List groups = [];
  bool loading = true;
  String userName = '';
  @override
  void initState() { super.initState(); load(); }
  load() async {
    final p = await SharedPreferences.getInstance();
    userName = p.getString('name') ?? '';
    try {
      final res = await supabase.from('groups').select().order('created_at', ascending: false);
      setState(() => groups = res);
    } catch (e) {} finally { setState(() => loading = false); }
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('My Groups - $userName'), backgroundColor: Colors.green, foregroundColor: Colors.white, actions: [IconButton(icon: Icon(Icons.logout), onPressed: () async { final p = await SharedPreferences.getInstance(); await p.clear(); Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => LoginScreen())); })]),
      floatingActionButton: FloatingActionButton.extended(backgroundColor: Colors.green, onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => CreateGroup())).then((_) => load()), icon: Icon(Icons.add, color: Colors.white), label: Text('Create New Group', style: TextStyle(color: Colors.white))),
      body: loading ? Center(child: CircularProgressIndicator()) : groups.isEmpty ? Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(Icons.group_off, size: 80, color: Colors.grey), Text('No groups yet')])) : ListView.builder(padding: EdgeInsets.all(12), itemCount: groups.length, itemBuilder: (c, i) {
        final g = groups[i];
        return Card(child: ListTile(leading: CircleAvatar(backgroundColor: Colors.green, child: Text(g['name'][0].toUpperCase(), style: TextStyle(color: Colors.white))), title: Text(g['name'], style: TextStyle(fontWeight: FontWeight.bold)), subtitle: Text('Members: ${g['total_members'] ?? 0} | \$${g['monthly_amount'] ?? 0}/mo'), trailing: Icon(Icons.arrow_forward_ios, size: 16), onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => GroupPage(group: g))).then((_) => load())));
      }),
    );
  }
}

class CreateGroup extends StatefulWidget {
  @override
  _CreateGroupState createState() => _CreateGroupState();
}

class _CreateGroupState extends State<CreateGroup> {
  final nameCtrl = TextEditingController();
  final cityCtrl = TextEditingController(text: 'Harare');
  final amountCtrl = TextEditingController(text: '100');
  String currency = 'USD';
  bool loading = false;
  final supabase = Supabase.instance.client;
  create() async {
    if (nameCtrl.text.isEmpty) return;
    setState(() => loading = true);
    try {
      final p = await SharedPreferences.getInstance();
      final res = await supabase.from('groups').insert({'name': nameCtrl.text.trim(), 'description': '${cityCtrl.text} | $currency', 'monthly_amount': double.tryParse(amountCtrl.text) ?? 100, 'total_members': 1, 'current_round': 1}).select().single();
      await supabase.from('members').insert({'group_id': res['id'], 'name': p.getString('name') ?? 'Admin', 'phone': p.getString('phone') ?? '', 'position': 1});
      Navigator.pop(context);
    } catch (e) { ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString()))); } finally { setState(() => loading = false); }
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Create Group'), backgroundColor: Colors.green, foregroundColor: Colors.white),
      body: SingleChildScrollView(padding: EdgeInsets.all(20), child: Column(children: [TextField(controller: nameCtrl, decoration: InputDecoration(labelText: 'Group Name *', border: OutlineInputBorder())), SizedBox(height: 12), TextField(controller: cityCtrl, decoration: InputDecoration(labelText: 'City', border: OutlineInputBorder())), SizedBox(height: 12), TextField(controller: amountCtrl, decoration: InputDecoration(labelText: 'Monthly Amount', border: OutlineInputBorder(), prefixText: '\$'), keyboardType: TextInputType.number), SizedBox(height: 12), DropdownButtonFormField(value: currency, decoration: InputDecoration(labelText: 'Currency', border: OutlineInputBorder()), items: ['USD', 'ZWL', 'ZiG'].map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(), onChanged: (v) => setState(() => currency = v!)), SizedBox(height: 20), SizedBox(width: double.infinity, height: 50, child: ElevatedButton(style: ElevatedButton.styleFrom(backgroundColor: Colors.green), onPressed: loading ? null : create, child: Text('CREATE GROUP', style: TextStyle(color: Colors.white))))])),
    );
  }
}

class GroupPage extends StatefulWidget {
  final Map<String, dynamic> group;
  GroupPage({required this.group});
  @override
  _GroupPageState createState() => _GroupPageState();
}

class _GroupPageState extends State<GroupPage> {
  final supabase = Supabase.instance.client;
  List members = [];
  List payments = [];
  bool loading = true;
  @override
  void initState() { super.initState(); load(); }
  load() async {
    try {
      final m = await supabase.from('members').select().eq('group_id', widget.group['id']).order('position');
      final pay = await supabase.from('payments').select().eq('group_id', widget.group['id']).order('paid_at', ascending: false).limit(50);
      setState(() { members = m; payments = pay; });
    } catch (e) {} finally { setState(() => loading = false); }
  }
  void btn1() {
    if (members.isEmpty) return;
    String? sel = members.first['id'];
    final amt = TextEditingController(text: widget.group['monthly_amount'].toString());
    showDialog(context: context, builder: (c) => AlertDialog(title: Text('1. Log Payment'), content: Column(mainAxisSize: MainAxisSize.min, children: [DropdownButtonFormField(value: sel, items: members.map<DropdownMenuItem<String>>((m) => DropdownMenuItem(value: m['id'] as String, child: Text(m['name']))).toList(), onChanged: (v) => sel = v), TextField(controller: amt, decoration: InputDecoration(labelText: 'Amount'), keyboardType: TextInputType.number)]), actions: [TextButton(onPressed: () => Navigator.pop(c), child: Text('Cancel')), ElevatedButton(onPressed: () async { await supabase.from('payments').insert({'group_id': widget.group['id'], 'member_id': sel, 'amount': double.tryParse(amt.text) ?? 0, 'method': 'cash'}); await supabase.from('contributions').insert({'group_id': widget.group['id'], 'member_id': sel, 'amount': double.tryParse(amt.text) ?? 0}); Navigator.pop(c); load(); }, child: Text('Save'))]));
  }
  void btn2() {
    String? sel = members.isNotEmpty ? members.first['id'] : null;
    final amt = TextEditingController(); final intCtrl = TextEditingController(text: '10');
    showDialog(context: context, builder: (c) => AlertDialog(title: Text('2. Log Loan'), content: Column(mainAxisSize: MainAxisSize.min, children: [DropdownButtonFormField(value: sel, items: members.map<DropdownMenuItem<String>>((m) => DropdownMenuItem(value: m['id'] as String, child: Text(m['name']))).toList(), onChanged: (v) => sel = v), TextField(controller: amt, decoration: InputDecoration(labelText: 'Loan Amount'), keyboardType: TextInputType.number), TextField(controller: intCtrl, decoration: InputDecoration(labelText: 'Interest %'), keyboardType: TextInputType.number)]), actions: [TextButton(onPressed: () => Navigator.pop(c), child: Text('Cancel')), ElevatedButton(onPressed: () async { final p = double.tryParse(amt.text) ?? 0; final i = double.tryParse(intCtrl.text) ?? 0; final t = p + (p * i / 100); await supabase.from('rounds').insert({'group_id': widget.group['id'], 'round_number': payments.length + 1, 'beneficiary_id': sel, 'amount': t, 'status': 'active'}); await supabase.from('payments').insert({'group_id': widget.group['id'], 'member_id': sel, 'amount': -p, 'method': 'loan $i%'}); Navigator.pop(c); load(); }, child: Text('Save'))]));
  }
  void btn3() {
    final amt = TextEditingController(); final desc = TextEditingController();
    showDialog(context: context, builder: (c) => AlertDialog(title: Text('3. Expense'), content: Column(mainAxisSize: MainAxisSize.min, children: [TextField(controller: desc, decoration: InputDecoration(labelText: 'Description')), TextField(controller: amt, decoration: InputDecoration(labelText: 'Amount'), keyboardType: TextInputType.number)]), actions: [TextButton(onPressed: () => Navigator.pop(c), child: Text('Cancel')), ElevatedButton(onPressed: () async { await supabase.from('payments').insert({'group_id': widget.group['id'], 'amount': -(double.tryParse(amt.text) ?? 0), 'method': desc.text}); Navigator.pop(c); load(); }, child: Text('Save'))]));
  }
  void btn4() => btn1();
  Future<void> btn5() async {
    final pdf = pw.Document();
    pdf.addPage(pw.Page(build: (pw.Context ctx) => pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [pw.Text('MukandoZW Report', style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold)), pw.Text('Group: ${widget.group['name']}'), pw.SizedBox(height: 10), pw.Text('Members:'), ...members.map((m) => pw.Text('- ${m['name']} ${m['phone']}')), pw.SizedBox(height: 10), pw.Text('Transactions:'), ...payments.take(30).map((t) => pw.Text('${t['paid_at']?.toString().substring(0, 10) ?? ''} - \$${t['amount']} - ${t['method']}')), pw.SizedBox(height: 20), pw.Text('MukandoZW v1.0\nPrivacy: Records only.\nContact: chivurotawanda@gmail.com\n© 2026', style: pw.TextStyle(fontSize: 9, color: PdfColors.grey)) ])));
    await Printing.layoutPdf(onLayout: (f) => pdf.save());
  }
  void btn6() {
    final n = TextEditingController(); final p = TextEditingController(text: '+263');
    showDialog(context: context, builder: (c) => AlertDialog(title: Text('6. Add Member'), content: Column(mainAxisSize: MainAxisSize.min, children: [TextField(controller: n, decoration: InputDecoration(labelText: 'Name')), TextField(controller: p, decoration: InputDecoration(labelText: 'Phone'))]), actions: [TextButton(onPressed: () => Navigator.pop(c), child: Text('Cancel')), ElevatedButton(onPressed: () async { await supabase.from('members').insert({'group_id': widget.group['id'], 'name': n.text, 'phone': p.text, 'position': members.length + 1}); await supabase.from('groups').update({'total_members': members.length + 1}).eq('id', widget.group['id']); Navigator.pop(c); load(); }, child: Text('Add'))]));
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.group['name']), backgroundColor: Colors.green, foregroundColor: Colors.white),
      body: loading ? Center(child: CircularProgressIndicator()) : SingleChildScrollView(
        padding: EdgeInsets.all(14),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Card(color: Colors.green.shade50, child: Padding(padding: EdgeInsets.all(14), child: Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: [Column(children: [Text('Members'), Text('${members.length}', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold))]), Column(children: [Text('Monthly'), Text('\$${widget.group['monthly_amount']}', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold))]), Column(children: [Text('Round'), Text('${widget.group['current_round']}', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold))])]))),
          SizedBox(height: 12), Text('ADMIN - 6 Buttons', style: TextStyle(fontWeight: FontWeight.bold)),
          SizedBox(height: 8),
          GridView.count(crossAxisCount: 2, shrinkWrap: true, physics: NeverScrollableScrollPhysics(), childAspectRatio: 2.6, mainAxisSpacing: 8, crossAxisSpacing: 8, children: [
            ElevatedButton.icon(style: ElevatedButton.styleFrom(backgroundColor: Colors.blue, foregroundColor: Colors.white), icon: Icon(Icons.payments), label: Text('1. Payment', style: TextStyle(fontSize: 11)), onPressed: btn1),
            ElevatedButton.icon(style: ElevatedButton.styleFrom(backgroundColor: Colors.orange, foregroundColor: Colors.white), icon: Icon(Icons.money), label: Text('2. Loan', style: TextStyle(fontSize: 11)), onPressed: btn2),
            ElevatedButton.icon(style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white), icon: Icon(Icons.receipt), label: Text('3. Expense', style: TextStyle(fontSize: 11)), onPressed: btn3),
            ElevatedButton.icon(style: ElevatedButton.styleFrom(backgroundColor: Colors.purple, foregroundColor: Colors.white), icon: Icon(Icons.replay), label: Text('4. Repay', style: TextStyle(fontSize: 11)), onPressed: btn4),
            ElevatedButton.icon(style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white), icon: Icon(Icons.picture_as_pdf), label: Text('5. PDF', style: TextStyle(fontSize: 11)), onPressed: btn5),
            ElevatedButton.icon(style: ElevatedButton.styleFrom(backgroundColor: Colors.teal, foregroundColor: Colors.white), icon: Icon(Icons.person_add), label: Text('6. Add Member', style: TextStyle(fontSize: 11)), onPressed: btn6),
          ]),
          SizedBox(height: 16), Text('Members', style: TextStyle(fontWeight: FontWeight.bold)), ...members.map((m) => ListTile(leading: CircleAvatar(child: Text(m['name'][0])), title: Text(m['name']), subtitle: Text(m['phone'] ?? ''))),
          SizedBox(height: 10), Text('Transactions', style: TextStyle(fontWeight: FontWeight.bold)), ...payments.take(15).map((t) => ListTile(dense: true, title: Text('\$${t['amount']} - ${t['method']}'), subtitle: Text(t['paid_at']?.toString().substring(0, 16) ?? ''))),
        ]),
      ),
    );
  }
}
