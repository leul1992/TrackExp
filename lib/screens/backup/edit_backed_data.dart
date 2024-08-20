import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:trackexp/services/backup_service.dart';

class EditDataPage extends StatefulWidget {
  final String dataType;
  final Map<String, dynamic> data;

  const EditDataPage({super.key, required this.dataType, required this.data});

  @override
  _EditDataPageState createState() => _EditDataPageState();
}

class _EditDataPageState extends State<EditDataPage> {
  late TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(
        text: widget.data['name'] ?? widget.data['description']);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Edit ${widget.dataType}')),
      body: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          children: [
            TextField(
              controller: _controller,
              decoration: const InputDecoration(labelText: 'Name/Description'),
            ),
            // Add other fields as necessary
            ElevatedButton(
              onPressed: _saveData,
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _saveData() async {
    final updatedData = {
      ...widget.data,
      'name': _controller.text, // Update other fields as necessary
    };

    final success = await BackupService.updateData(widget.dataType, updatedData);

    if (success) {
      Fluttertoast.showToast(msg: '${widget.dataType} updated successfully');
      Navigator.pop(context);
    } else {
      Fluttertoast.showToast(msg: 'Failed to update ${widget.dataType}');
    }
  }
}
