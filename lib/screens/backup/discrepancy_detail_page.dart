import 'package:flutter/material.dart';
import 'package:trackexp/models/expense.dart';
import 'package:trackexp/models/trip.dart';
import 'package:trackexp/screens/backup/data_section.dart';
import 'package:trackexp/screens/backup/merged_data_section.dart';
import 'package:trackexp/services/backup_service.dart';
import 'package:trackexp/services/hive_services.dart';

class DiscrepancyDetailPage extends StatefulWidget {
  final Map<String, dynamic>? localData;
  final Map<String, dynamic>? remoteData;
  final List<Map<String, dynamic>> expenses;
  final bool allowCategoryToggle;

  const DiscrepancyDetailPage({
    super.key,
    this.localData,
    this.remoteData,
    required this.expenses,
    this.allowCategoryToggle = true,
  });

  @override
  _DiscrepancyDetailPageState createState() => _DiscrepancyDetailPageState();
}

class _DiscrepancyDetailPageState extends State<DiscrepancyDetailPage> {
  final TextEditingController _mergedNameController = TextEditingController();
  final TextEditingController _mergedStartDateOrIsSaleController =
      TextEditingController();
  final TextEditingController _mergedEndDateOrSoldAmountController =
      TextEditingController();
  final TextEditingController _mergedTotalMoneyController =
      TextEditingController();

  String _currentCategory = "Trips";

  @override
  void initState() {
    super.initState();
    _updateMergedControllers();
    if (!widget.allowCategoryToggle) {
      _currentCategory = "Expenses";
    }
  }

  void _updateMergedControllers() {
    if (_currentCategory == "Trips") {
      var local = widget.localData ?? {};
      var remote = widget.remoteData ?? {};

      _mergedNameController.text =
          local['name'] == remote['name'] ? local['name'] ?? '' : '';
      _mergedStartDateOrIsSaleController.text =
          local['start_date'] == remote['start_date']
              ? local['start_date'] ?? ''
              : '';
      _mergedEndDateOrSoldAmountController.text =
          local['end_date'] == remote['end_date']
              ? local['end_date'] ?? ''
              : '';
      _mergedTotalMoneyController.text =
          local['total_money'] == remote['total_money']
              ? local['total_money']?.toString() ?? ''
              : '';
    } else if (_currentCategory == "Expenses") {
      var local = widget.localData ?? {};
      var remote = widget.remoteData ?? {};

      _mergedNameController.text =
          local['name'] == remote['name'] ? local['name'] ?? '' : '';
      _mergedTotalMoneyController.text = local['amount'] == remote['amount']
          ? local['amount']?.toString() ?? ''
          : '';
      _mergedStartDateOrIsSaleController.text =
          local['is_sale'] == remote['is_sale']
              ? local['is_sale']?.toString() ?? ''
              : '';
      _mergedEndDateOrSoldAmountController.text =
          local['sold_amount'] == remote['sold_amount']
              ? local['sold_amount']?.toString() ?? ''
              : '';
    }
  }

  @override
  void dispose() {
    _mergedNameController.dispose();
    _mergedStartDateOrIsSaleController.dispose();
    _mergedEndDateOrSoldAmountController.dispose();
    _mergedTotalMoneyController.dispose();
    super.dispose();
  }

  void _syncData() async {
    // check if the fields are empty
    if (_mergedNameController.text.isEmpty ||
        _mergedStartDateOrIsSaleController.text.isEmpty ||
        _mergedEndDateOrSoldAmountController.text.isEmpty ||
        double.tryParse(_mergedTotalMoneyController.text) == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill in all the required fields')),
      );
      return;
    }
    if (_currentCategory == "Trips") {
      // sync for trips
      final mergedData = {
        '_id': widget.localData?['id'] ?? widget.remoteData?['_id'],
        'name': _mergedNameController.text,
        'start_date': _mergedStartDateOrIsSaleController.text,
        'end_date': _mergedEndDateOrSoldAmountController.text,
        'total_money': double.tryParse(_mergedTotalMoneyController.text) ?? 0.0,
      };

      final mergedTrip = Trip(
        id: mergedData['_id'] ?? '',
        name: mergedData['name'],
        startDate: mergedData['start_date'],
        endDate: mergedData['end_date'],
        totalMoney: mergedData['total_money'],
      );

      if (widget.localData != null) {
        await HiveService.updateTrip(mergedTrip);
      } else {
        await HiveService.insertTrip(mergedTrip);
      }

      if (widget.remoteData != null) {
        await BackupService.updateData('trips', mergedData);
      } else {
        await BackupService.addData('trips', mergedData);
      }
    } else if (_currentCategory == "Expenses") {
      // sync for expenses
      // Helper function to convert value to bool
bool _parseBool(dynamic value) {
  if (value == null) return false;
  if (value is bool) return value;
  if (value is String) {
    // Handle common string representations
    return value.toLowerCase() == 'true';
  }
  if (value is int) {
    // Handle integer representations (0 and 1)
    return value != 0;
  }
  return false; // Default value for unsupported types
}
      final mergedExpenseData = {
        '_id': widget.localData?['id'] ?? widget.remoteData?['_id'],
        'trip_id':
            widget.localData?['trip_id'] ?? widget.remoteData?['trip_id'],
        'name': _mergedNameController.text,
        'amount': double.tryParse(_mergedTotalMoneyController.text) ?? 0.0,
        'is_sale': _parseBool(_mergedStartDateOrIsSaleController.text),
        'sold_amount':
            double.tryParse(_mergedEndDateOrSoldAmountController.text) ?? 0.0,
      };

      final mergedData = Expense(
        id: mergedExpenseData['_id'] ?? '',
        tripId: mergedExpenseData['trip_id'],
        name: mergedExpenseData['name'],
        amount: mergedExpenseData['amount'],
        isSale: mergedExpenseData['is_sale'],
        soldAmount: mergedExpenseData['sold_amount'],
      );

      if (widget.localData != null) {
        await HiveService.updateExpense(mergedData);
      } else {
        await HiveService.insertExpense(mergedData);
      }

      if (widget.remoteData != null) {
        await BackupService.updateData('expenses', mergedExpenseData);
      } else {
        await BackupService.addData('expenses', mergedExpenseData);
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Expense synced successfully')),
      );
    }

    Navigator.of(context).pop();
  }

  void _onCategoryChanged(String category) {
    setState(() {
      _currentCategory = category;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        foregroundColor: Colors.white,
        title: const Text('Change Details'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          children: [
            if (widget.allowCategoryToggle) ...[
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ElevatedButton(
                    onPressed: () => _onCategoryChanged("Trips"),
                    child: const Text("Trip"),
                  ),
                  const SizedBox(width: 16),
                  ElevatedButton(
                    onPressed: () => _onCategoryChanged("Expenses"),
                    child: const Text("Expenses"),
                  ),
                ],
              ),
            ],
            Expanded(
              child:
                  (_currentCategory == "Trips" || !widget.allowCategoryToggle)
                      ? Row(
                          children: [
                            Expanded(
                              child: SectionWidget(
                                title: 'Local',
                                data: widget.localData,
                                isLocal: true,
                                category: _currentCategory,
                                onCopyToMerged: _copyToMerged,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: SectionWidget(
                                title: 'Remote',
                                data: widget.remoteData,
                                isLocal: false,
                                category: _currentCategory,
                                onCopyToMerged: _copyToMerged,
                              ),
                            ),
                          ],
                        )
                      : _buildExpenseList(),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: (_currentCategory == "Trips" ||
                      !widget.allowCategoryToggle)
                  ? MergedSectionWidget(
                      category: _currentCategory,
                      mergedNameController: _mergedNameController,
                      mergedStartDateController:
                          _mergedStartDateOrIsSaleController,
                      mergedEndDateController:
                          _mergedEndDateOrSoldAmountController,
                      mergedTotalMoneyController: _mergedTotalMoneyController,
                    )
                  : Text("choose the expense to sync"),
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

  void _copyToMerged(String field, String source) {
    setState(() {
      var local = widget.localData ?? {};
      var remote = widget.remoteData ?? {};
      var value = source == 'local' ? local[field] : remote[field];

      if (_currentCategory == "Trips") {
        // Handling fields for trips
        switch (field) {
          case 'name':
            _mergedNameController.text = value ?? '';
            break;
          case 'start_date':
            _mergedStartDateOrIsSaleController.text = value ?? '';
            break;
          case 'end_date':
            _mergedEndDateOrSoldAmountController.text = value ?? '';
            break;
          case 'total_money':
            _mergedTotalMoneyController.text = value?.toString() ?? '';
            break;
        }
      } else if (_currentCategory == "Expenses") {
        // Handling fields for expenses
        switch (field) {
          case 'name':
            _mergedNameController.text = value ?? '';
            break;
          case 'amount':
            _mergedTotalMoneyController.text = value?.toString() ?? '';
            break;
          case 'is_sale':
            _mergedStartDateOrIsSaleController.text = value?.toString() ?? '';
            break;
          case 'sold_amount':
            _mergedEndDateOrSoldAmountController.text = value?.toString() ?? '';
            break;
        }
      }
    });
  }

  Widget _buildExpenseList() {
    return ListView.builder(
      itemCount: widget.expenses.length,
      itemBuilder: (context, index) {
        final expense = widget.expenses[index];
        return ListTile(
          title: Text(
              expense['localData']?['name'] ?? expense['remoteData']?['name']),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => DiscrepancyDetailPage(
                  localData: expense['localData'],
                  remoteData: expense['remoteData'],
                  expenses: const [],
                  allowCategoryToggle: false, // No toggle for expense details
                ),
              ),
            );
          },
        );
      },
    );
  }
}
