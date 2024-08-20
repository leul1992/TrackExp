import 'package:flutter/material.dart';
import 'package:trackexp/models/trip.dart';
import 'package:trackexp/screens/backup/detail_change.dart';
import 'package:trackexp/services/hive_services.dart';
import 'package:trackexp/services/backup_service.dart';

class SyncPage extends StatefulWidget {
  const SyncPage({super.key});

  @override
  _SyncPageState createState() => _SyncPageState();
}

class _SyncPageState extends State<SyncPage> {
  List<Map<String, dynamic>> syncIssues = [];

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  Future<void> _fetchData() async {
    try {
      // Fetch local data
      List<Trip> localTripsData = await HiveService.getTrips();
      List<Map<String, dynamic>> localTrips =
          localTripsData.map((trip) => trip.toJson()).toList();

      // Fetch remote data
      Map<String, dynamic> remoteData = await BackupService.fetchData(context);
      List<Map<String, dynamic>> remoteTrips =
          List<Map<String, dynamic>>.from(remoteData['trips']);

      // Find discrepancies
      _findSyncIssues(localTrips, remoteTrips);
    } catch (e) {
      // Handle error
      print("Error fetching data: $e");
    }
  }

  void _findSyncIssues(List<Map<String, dynamic>> localTrips,
      List<Map<String, dynamic>> remoteTrips) {
    Set localIds = localTrips.map((trip) => trip['id']).toSet();
    Set remoteIds = remoteTrips.map((trip) => trip['_id']).toSet();

    List<Map<String, dynamic>> syncIssues = [];

    // Local Only
    syncIssues.addAll(localTrips
        .where((trip) => !remoteIds.contains(trip['id']))
        .map((trip) => {'source': 'local', 'localData': trip})
        .toList());

    // Remote Only
    syncIssues.addAll(remoteTrips
        .where((trip) => !localIds.contains(trip['_id']))
        .map((trip) => {'source': 'remote', 'remoteData': trip})
        .toList());

    // Conflicts
    for (var localTrip in localTrips) {
      var matchingRemoteTrip = remoteTrips.firstWhere(
          (trip) => trip['_id'] == localTrip['id'],
          orElse: () => {});

      if (matchingRemoteTrip.isNotEmpty &&
          !_areTripsEqual(localTrip, matchingRemoteTrip)) {
        syncIssues.add({
          'source': 'conflict',
          'localData': localTrip,
          'remoteData': matchingRemoteTrip,
        });
      }
    }

    setState(() {
      print("sync issue $syncIssues");
      this.syncIssues = syncIssues;
    });
  }

  bool _areTripsEqual(Map<String, dynamic> local, Map<String, dynamic> remote) {
    return local['name'] == remote['name'] &&
        local['start_date'] == remote['start_date'] &&
        local['end_date'] == remote['end_date'] &&
        local['total_money'] == remote['total_money'];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: syncIssues.isEmpty
          ? const Center(child: Text('No sync issues found'))
          : ListView.builder(
              itemCount: syncIssues.length,
              itemBuilder: (context, index) {
                final issue = syncIssues[index];
                final trip = issue['localData'] ?? issue['remoteData'];

                return ListTile(
                  title: Text(trip['name'] ?? 'Unknown'),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => DiscrepancyDetailPage(
                          localData: issue['localData'],
                          remoteData: issue['remoteData'],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
    );
  }
}
