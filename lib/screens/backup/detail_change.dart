import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:trackexp/models/trip.dart';
import 'package:trackexp/services/backup_service.dart';
import 'package:trackexp/services/hive_services.dart';

class DiscrepancyDetailPage extends StatefulWidget {
  final Map<String, dynamic>? localData;
  final Map<String, dynamic>? remoteData;

  const DiscrepancyDetailPage({super.key, this.localData, this.remoteData});

  @override
  _DiscrepancyDetailPageState createState() => _DiscrepancyDetailPageState();
}

class _DiscrepancyDetailPageState extends State<DiscrepancyDetailPage> {
  final TextEditingController _mergedNameController = TextEditingController();
  final TextEditingController _mergedStartDateController =
      TextEditingController();
  final TextEditingController _mergedEndDateController =
      TextEditingController();
  final TextEditingController _mergedTotalMoneyController =
      TextEditingController();

  @override
  void initState() {
    super.initState();
    var local = widget.localData ?? {};
    var remote = widget.remoteData ?? {};
    
  print('Trip JSON: ${jsonEncode(local)}');

    _mergedNameController.text =
        local['name'] == remote['name'] ? local['name'] ?? '' : '';
    _mergedStartDateController.text =
        local['start_date'] == remote['start_date']
            ? local['start_date'] ?? ''
            : '';
    _mergedEndDateController.text =
        local['end_date'] == remote['end_date'] ? local['end_date'] ?? '' : '';
    _mergedTotalMoneyController.text =
        local['total_money'] == remote['total_money']
            ? local['total_money']?.toString() ?? ''
            : '';
  }

  @override
  void dispose() {
    _mergedNameController.dispose();
    _mergedStartDateController.dispose();
    _mergedEndDateController.dispose();
    _mergedTotalMoneyController.dispose();
    super.dispose();
  }

  void _copyToMerged(String field, String source) {
    setState(() {
      var local = widget.localData ?? {};
      var remote = widget.remoteData ?? {};
      var value = source == 'local' ? local[field] : remote[field];

      switch (field) {
        case 'name':
          _mergedNameController.text = value ?? '';
          break;
        case 'start_date':
          _mergedStartDateController.text = value ?? '';
          break;
        case 'end_date':
          _mergedEndDateController.text = value ?? '';
          break;
        case 'total_money':
          _mergedTotalMoneyController.text = value?.toString() ?? '';
          break;
      }
    });
  }

  void _syncData() async {
    final mergedData = {
      '_id': widget.localData?['id'] ?? widget.remoteData?['_id'],
      'name': _mergedNameController.text,
      'start_date': _mergedStartDateController.text,
      'end_date': _mergedEndDateController.text,
      'total_money': double.tryParse(_mergedTotalMoneyController.text) ?? 0.0,
    };

    final mergedTrip = Trip(
      id: mergedData['_id'] ?? '',
      name: mergedData['name'],
      startDate: mergedData['start_date'],
      endDate: mergedData['end_date'],
      totalMoney: mergedData['total_money'],
    );

    print('merged data : ${mergedTrip.id}');
    if (widget.localData != null) {
      await HiveService.updateTrip(mergedTrip);
    } else {
      await HiveService.insertTrip(mergedTrip);
    }

    if (widget.remoteData != null) {
      final remoteData = {...?widget.remoteData, ...mergedData};
      await BackupService.addData('trips', mergedData);
    } else {
      await BackupService.addData('trips', mergedData);
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Data synced successfully')),
    );

    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    var localData = widget.localData ?? {};
    var remoteData = widget.remoteData ?? {};

    return Scaffold(
      appBar: AppBar(title: const Text('Change Details')),
      body: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          children: [
            Expanded(
              child: Row(
                children: [
                  Expanded(
                    child: _buildSection(
                      title: 'Local',
                      data: localData,
                      isLocal: true,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _buildSection(
                      title: 'Remote',
                      data: remoteData,
                      isLocal: false,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: _buildMergedSection(),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _syncData,
        child: const Icon(Icons.sync),
      ),
    );
  }

  Widget _buildSection({
    required String title,
    required Map<String, dynamic> data,
    required bool isLocal,
  }) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: Colors.blueAccent),
        borderRadius: BorderRadius.circular(8.0),
      ),
      child: SingleChildScrollView(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text(
                title,
                style:
                    const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
            ),
            _buildField(
                label: 'Name',
                value: data['name'],
                field: 'name',
                isLocal: isLocal),
            _buildField(
                label: 'Start Date',
                value: data['start_date'],
                field: 'start_date',
                isLocal: isLocal),
            _buildField(
                label: 'End Date',
                value: data['end_date'],
                field: 'end_date',
                isLocal: isLocal),
            _buildField(
                label: 'Total Money',
                value: data['total_money']?.toString(),
                field: 'total_money',
                isLocal: isLocal),
          ],
        ),
      ),
    );
  }

  Widget _buildField({
    required String label,
    required String? value,
    required String field,
    required bool isLocal,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
      child: Row(
        children: [
          // Expanded(
          //     flex: 2, child: Text('$label:', style: TextStyle(fontSize: 14))),
          Expanded(
            flex: 3,
            child: value != null && value.isNotEmpty
                ? Row(
                    children: [
                      Text(value, style: const TextStyle(fontSize: 14)),
                      const Spacer(),
                      IconButton(
                        icon: const Icon(Icons.content_copy_outlined),
                        onPressed: () =>
                            _copyToMerged(field, isLocal ? 'local' : 'remote'),
                        tooltip:
                            isLocal ? 'Copy from local' : 'Copy from remote',
                      ),
                    ],
                  )
                : Container(),
          ),
        ],
      ),
    );
  }

  Widget _buildMergedSection() {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: Colors.green),
        borderRadius: BorderRadius.circular(8.0),
      ),
      child: SingleChildScrollView(
        child: Column(
          children: [
            const Padding(
              padding: EdgeInsets.all(8.0),
              child: Text(
                'Merged',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
            ),
            _buildEditableField(
                label: 'Name',
                controller: _mergedNameController,
                field: 'name'),
            _buildEditableField(
                label: 'Start Date',
                controller: _mergedStartDateController,
                field: 'start_date'),
            _buildEditableField(
                label: 'End Date',
                controller: _mergedEndDateController,
                field: 'end_date'),
            _buildEditableField(
                label: 'Total Money',
                controller: _mergedTotalMoneyController,
                field: 'total_money'),
          ],
        ),
      ),
    );
  }

  Widget _buildEditableField({
    required String label,
    required TextEditingController controller,
    required String field,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
      child: Row(
        children: [
          Expanded(
              flex: 2,
              child: Text('$label:', style: const TextStyle(fontSize: 14))),
          Expanded(
            flex: 3,
            child: TextField(
              controller: controller,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                contentPadding:
                    EdgeInsets.symmetric(vertical: 10, horizontal: 10),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
