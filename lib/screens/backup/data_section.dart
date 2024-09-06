import 'package:flutter/material.dart';

class SectionWidget extends StatelessWidget {
  final String title;
  final Map<String, dynamic>? data;
  final bool isLocal;
  final String category;
  final Function(String field, String source) onCopyToMerged;

  const SectionWidget({
    super.key,
    required this.title,
    required this.data,
    required this.isLocal,
    required this.category,
    required this.onCopyToMerged,
  });

  @override
  Widget build(BuildContext context) {
    print("local data ${category} ${data}");
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8.0),
      decoration: BoxDecoration(
        color: isLocal ? Colors.lightBlue[50] : Colors.lightGreen[50],
        border: Border.all(color: isLocal ? Colors.blueAccent : Colors.green),
        borderRadius: BorderRadius.circular(8.0),
      ),
      child: SingleChildScrollView(
        child: Column(
          children: [
            _buildTitle(context),
            if (category == "Trips") ...[
              _buildField('Name', data?['name'], 'name'),
              _buildField('Start Date', data?['start_date'], 'start_date'),
              _buildField('End Date', data?['end_date'], 'end_date'),
              _buildField('Total Money', data?['total_money']?.toString(),
                  'total_money'),
            ] else if (category == "Expenses") ...[
              _buildField('Expense Name', data?['name'], 'name'),
              _buildField('Amount', data?['amount']?.toString(), 'amount'),
              _buildField('Is Sale', data?['is_sale']?.toString(), 'is_sale'),
              _buildField('Sold Amount', data?['sold_amount'].toString(), 'sold_amount'),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildTitle(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(8.0),
      decoration: BoxDecoration(
        color: isLocal ? Colors.blueAccent : Colors.green,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(8.0)),
      ),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleLarge?.copyWith(
              color: Colors.white,
            ),
      ),
    );
  }

  Widget _buildField(String label, String? value, String field) {
    return ListTile(
      title: Text(label),
      subtitle: Text(value ?? ''),
      trailing: IconButton(
        icon: const Icon(Icons.copy),
        onPressed: () => onCopyToMerged(field, isLocal ? 'local' : 'remote'),
      ),
    );
  }
}
