import 'package:flutter/material.dart';

class MergedSectionWidget extends StatelessWidget {
  final String category;
  final TextEditingController mergedNameController;
  final TextEditingController mergedStartDateController;
  final TextEditingController mergedEndDateController;
  final TextEditingController mergedTotalMoneyController;

  const MergedSectionWidget({
    super.key,
    required this.category,
    required this.mergedNameController,
    required this.mergedStartDateController,
    required this.mergedEndDateController,
    required this.mergedTotalMoneyController,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(8.0),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey),
        borderRadius: BorderRadius.circular(8.0),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Merged $category Data',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          if (category == "Trips") ...[
            _buildTextField('Merged Name', mergedNameController),
            _buildTextField('Merged Start Date', mergedStartDateController),
            _buildTextField('Merged End Date', mergedEndDateController),
            _buildTextField('Merged Total Money', mergedTotalMoneyController),
          ] else if (category == "Expenses") ...[
            _buildTextField('Merged Expense Name', mergedNameController),
            _buildTextField('Merged Amount', mergedTotalMoneyController),
            _buildTextField('Merged Is Sale', mergedStartDateController),
            _buildTextField('Merged Sold Amount', mergedEndDateController),
          ],
        ],
      ),
    );
  }

  Widget _buildTextField(String label, TextEditingController controller) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: TextField(
        controller: controller,
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
        ),
      ),
    );
  }
}
