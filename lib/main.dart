
import 'dart:convert';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

void main() {
  runApp(EasyPrintApp());
}

class EasyPrintApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'EasyPrint',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: OrderHomePage(),
    );
  }
}

class Order {
  String id;
  String fileName;
  String filePath;
  String color;
  String sided;
  String size;
  int copies;
  String name;
  String phone;
  String notes;
  String status;
  String createdAt;

  Order({
    required this.id,
    required this.fileName,
    required this.filePath,
    required this.color,
    required this.sided,
    required this.size,
    required this.copies,
    required this.name,
    required this.phone,
    required this.notes,
    required this.status,
    required this.createdAt,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'fileName': fileName,
        'filePath': filePath,
        'color': color,
        'sided': sided,
        'size': size,
        'copies': copies,
        'name': name,
        'phone': phone,
        'notes': notes,
        'status': status,
        'createdAt': createdAt,
      };

  static Order fromJson(Map<String, dynamic> j) => Order(
        id: j['id'],
        fileName: j['fileName'],
        filePath: j['filePath'],
        color: j['color'],
        sided: j['sided'],
        size: j['size'],
        copies: j['copies'],
        name: j['name'],
        phone: j['phone'],
        notes: j['notes'],
        status: j['status'],
        createdAt: j['createdAt'],
      );
}

class OrderHomePage extends StatefulWidget {
  @override
  _OrderHomePageState createState() => _OrderHomePageState();
}

class _OrderHomePageState extends State<OrderHomePage> {
  PlatformFile? _pickedFile;
  String _color = 'Black & White';
  String _sided = 'Single-sided';
  String _size = 'A4';
  int _copies = 1;
  final _nameCtl = TextEditingController();
  final _phoneCtl = TextEditingController();
  final _notesCtl = TextEditingController();
  List<Order> _orders = [];

  @override
  void initState() {
    super.initState();
    _loadOrders();
  }

  Future<void> _loadOrders() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString('easyprint_orders_v1');
    if (raw != null) {
      final list = json.decode(raw) as List;
      setState(() {
        _orders = list.map((e) => Order.fromJson(e)).toList();
      });
    }
  }

  Future<void> _saveOrders() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = json.encode(_orders.map((o) => o.toJson()).toList());
    await prefs.setString('easyprint_orders_v1', raw);
  }

  Future<void> _pickFile() async {
    final res = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'jpg', 'jpeg', 'png'],
      withData: false,
    );
    if (res != null && res.files.isNotEmpty) {
      setState(() {
        _pickedFile = res.files.first;
      });
    }
  }

  Future<String> _copyFileToAppDir(PlatformFile file) async {
    final appDir = await getApplicationDocumentsDirectory();
    final uuid = Uuid().v4();
    final dest = File('${appDir.path}/${uuid}_${file.name}');
    // if file.path is available, copy; otherwise use bytes
    if (file.path != null) {
      final src = File(file.path!);
      await src.copy(dest.path);
    } else if (file.bytes != null) {
      await dest.writeAsBytes(file.bytes!);
    } else {
      throw Exception('No file source available');
    }
    return dest.path;
  }

  void _submitOrder() async {
    if (_pickedFile == null) {
      _showSnack('Please pick a file to print.');
      return;
    }
    if (_nameCtl.text.trim().isEmpty || _phoneCtl.text.trim().isEmpty) {
      _showSnack('Please enter name and phone.');
      return;
    }

    final copiedPath = await _copyFileToAppDir(_pickedFile!);
    final order = Order(
      id: 'E${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}',
      fileName: _pickedFile!.name,
      filePath: copiedPath,
      color: _color,
      sided: _sided,
      size: _size,
      copies: _copies,
      name: _nameCtl.text.trim(),
      phone: _phoneCtl.text.trim(),
      notes: _notesCtl.text.trim(),
      status: 'Pending',
      createdAt: DateTime.now().toIso8601String(),
    );
    setState(() {
      _orders.add(order);
      // reset form
      _pickedFile = null;
      _color = 'Black & White';
      _sided = 'Single-sided';
      _size = 'A4';
      _copies = 1;
      _nameCtl.clear();
      _phoneCtl.clear();
      _notesCtl.clear();
    });
    await _saveOrders();
    _showSnack('Order submitted! ID: ${order.id}');
  }

  void _showSnack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  void _openAdmin() {
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => AdminPage(
      orders: _orders,
      onUpdate: (updated) async {
        setState(() {
          _orders = updated;
        });
        await _saveOrders();
      },
    )));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('EasyPrint'),
        actions: [
          IconButton(icon: Icon(Icons.admin_panel_settings), onPressed: _openAdmin),
        ],
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(12),
        child: Column(
          children: [
            Card(
              child: Padding(
                padding: EdgeInsets.all(12),
                child: Column(
                  children: [
                    ListTile(
                      leading: Icon(Icons.attach_file),
                      title: Text(_pickedFile?.name ?? 'No file selected'),
                      subtitle: Text('PDF / JPG / PNG'),
                      trailing: ElevatedButton(
                        onPressed: _pickFile,
                        child: Text('Pick File'),
                      ),
                    ),
                    Row(
                      children: [
                        Expanded(child: DropdownButtonFormField<String>(
                          value: _color,
                          items: ['Black & White', 'Color'].map((e)=>DropdownMenuItem(value:e, child: Text(e))).toList(),
                          onChanged: (v)=>setState(()=>_color=v!),
                          decoration: InputDecoration(labelText: 'Color'),
                        )),
                        SizedBox(width: 8),
                        Expanded(child: DropdownButtonFormField<String>(
                          value: _sided,
                          items: ['Single-sided','Double-sided'].map((e)=>DropdownMenuItem(value:e, child: Text(e))).toList(),
                          onChanged: (v)=>setState(()=>_sided=v!),
                          decoration: InputDecoration(labelText: 'Sides'),
                        )),
                      ],
                    ),
                    SizedBox(height:8),
                    Row(
                      children: [
                        Expanded(child: DropdownButtonFormField<String>(
                          value: _size,
                          items: ['A4','A3'].map((e)=>DropdownMenuItem(value:e, child: Text(e))).toList(),
                          onChanged: (v)=>setState(()=>_size=v!),
                          decoration: InputDecoration(labelText: 'Page size'),
                        )),
                        SizedBox(width:8),
                        Container(width:120, child: TextFormField(
                          initialValue: _copies.toString(),
                          keyboardType: TextInputType.number,
                          decoration: InputDecoration(labelText: 'Copies'),
                          onChanged: (v){
                            final n = int.tryParse(v) ?? 1;
                            setState(()=>_copies = n.clamp(1, 999));
                          },
                        )),
                      ],
                    ),
                    SizedBox(height:8),
                    TextFormField(controller: _nameCtl, decoration: InputDecoration(labelText: 'Your name')),
                    SizedBox(height:8),
                    TextFormField(controller: _phoneCtl, decoration: InputDecoration(labelText: 'Phone'), keyboardType: TextInputType.phone),
                    SizedBox(height:8),
                    TextFormField(controller: _notesCtl, decoration: InputDecoration(labelText: 'Notes (optional)'), maxLines: 2),
                    SizedBox(height:12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        ElevatedButton(onPressed: _submitOrder, child: Text('Submit Order')),
                      ],
                    )
                  ],
                ),
              ),
            ),
            SizedBox(height:10),
            Align(alignment: Alignment.centerLeft, child: Text('My Orders', style: TextStyle(fontSize:18, fontWeight: FontWeight.bold))),
            SizedBox(height:8),
            ..._orders.reversed.map((o)=>ListTile(
              title: Text('${o.id} — ${o.fileName}'),
              subtitle: Text('${o.copies}x ${o.size} • ${o.color} • ${o.sided}\nStatus: ${o.status}'),
              isThreeLine: true,
            )).toList(),
            SizedBox(height:40),
          ],
        ),
      ),
    );
  }
}

class AdminPage extends StatefulWidget {
  final List<Order> orders;
  final ValueChanged<List<Order>> onUpdate;
  AdminPage({required this.orders, required this.onUpdate});

  @override
  _AdminPageState createState() => _AdminPageState();
}

class _AdminPageState extends State<AdminPage> {
  late List<Order> _orders;

  @override
  void initState() {
    super.initState();
    _orders = List.from(widget.orders);
  }

  void _changeStatus(Order o) {
    final idx = _orders.indexWhere((x)=>x.id==o.id);
    if(idx==-1) return;
    showModalBottomSheet(context: context, builder: (_) {
      return Wrap(
        children: [
          ListTile(title: Text('Change status for ${o.id}')),
          ListTile(leading: Icon(Icons.hourglass_empty), title: Text('Pending'), onTap: (){ setState(()=>_orders[idx].status='Pending'); widget.onUpdate(_orders); Navigator.pop(context); }),
          ListTile(leading: Icon(Icons.print), title: Text('Printing'), onTap: (){ setState(()=>_orders[idx].status='Printing'); widget.onUpdate(_orders); Navigator.pop(context); }),
          ListTile(leading: Icon(Icons.check_circle), title: Text('Ready'), onTap: (){ setState(()=>_orders[idx].status='Ready'); widget.onUpdate(_orders); Navigator.pop(context); }),
          ListTile(leading: Icon(Icons.done_all), title: Text('Completed'), onTap: (){ setState(()=>_orders[idx].status='Completed'); widget.onUpdate(_orders); Navigator.pop(context); }),
        ],
      );
    });
  }

  void _exportOrderFile(Order o) async {
    // attempt to open the file using platform mechanisms is out of scope.
    _show('File path: ${o.filePath}');
  }

  void _show(String s){
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(s)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Admin - Orders'),
      ),
      body: ListView.builder(
        itemCount: _orders.length,
        itemBuilder: (_,i){
          final o = _orders[_orders.length-1-i];
          return Card(
            child: ListTile(
              title: Text('${o.id} — ${o.fileName}'),
              subtitle: Text('${o.name} • ${o.phone}\n${o.copies}x ${o.size} • ${o.color} • ${o.sided}\nStatus: ${o.status}'),
              isThreeLine: true,
              onTap: ()=>_changeStatus(o),
              trailing: IconButton(icon: Icon(Icons.download), onPressed: ()=>_exportOrderFile(o)),
            ),
          );
        },
      ),
    );
  }
}
