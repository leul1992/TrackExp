import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:trackexp/screens/backup/edit_backed_data.dart';
import 'package:trackexp/services/backup_service.dart';

class BackupDataPage extends StatefulWidget {
  const BackupDataPage({super.key});

  @override
  _BackupDataPageState createState() => _BackupDataPageState();
}

class _BackupDataPageState extends State<BackupDataPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Backed-Up Data')),
      body: FutureBuilder<Map<String, dynamic>>(
        future: BackupService.fetchData(context),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          } else {
            final trips = snapshot.data?['trips'] ?? [];
            final expenses = snapshot.data?['expenses'] ?? [];

            return ListView(
              children: [
                const Text('Trips:', style: TextStyle(fontWeight: FontWeight.bold)),
                ...trips.map((trip) => ListTile(
                      title: Text(trip['name'] ?? 'Unnamed Trip'),
                      subtitle: Text(
                          'Start Date: ${trip['start_date'] ?? 'Unknown'}'),
                      trailing: IconButton(
                        icon: const Icon(Icons.delete),
                        onPressed: () => _deleteData('trips', trip['_id']),
                      ),
                      onTap: () => _editData(context, 'trips', trip),
                    )),
                const Text('Expenses:',
                    style: TextStyle(fontWeight: FontWeight.bold)),
                ...expenses.map((expense) => ListTile(
                      title: Text(expense['name'] ?? 'Unnamed Expense'),
                      subtitle:
                          Text('Amount: ${expense['amount'] ?? 'Unknown'}'),
                      trailing: IconButton(
                        icon: const Icon(Icons.delete),
                        onPressed: () =>
                            _deleteData('expenses', expense['_id']),
                      ),
                      onTap: () => _editData(context, 'expenses', expense),
                    )),
              ],
            );
          }
        },
      ),
    );
  }

  Future<void> _deleteData(String dataType, String dataId) async {
    final success = await BackupService.deleteData(context, dataType, dataId);
    if (success) {
      Fluttertoast.showToast(msg: '$dataType deleted successfully');
      setState(() {}); // Refresh the data
    } else {
      Fluttertoast.showToast(msg: 'Failed to delete $dataType');
    }
  }

  Future<void> _editData(
      BuildContext context, String dataType, Map<String, dynamic> data) async {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EditDataPage(dataType: dataType, data: data),
      ),
    );
  }
}
