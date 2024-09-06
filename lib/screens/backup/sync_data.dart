import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:trackexp/models/expense.dart';
import 'package:trackexp/models/trip.dart';
import 'package:trackexp/screens/backup/discrepancy_detail_page.dart';
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
      // Fetch local data for trips and expenses
      final localTripsData = await HiveService.getTrips();
      final localExpensesData = await HiveService.getAllExpenses();

      // Fetch remote data for trips and expenses
      final remoteData = await BackupService.fetchData(context);

      // Find discrepancies for both trips and expenses
      _findSyncIssues(
        localTripsData.map((trip) => trip.toJson()).toList(),
        List<Map<String, dynamic>>.from(remoteData['trips']),
        localExpensesData.map((expense) => expense.toJson()).toList(),
        List<Map<String, dynamic>>.from(remoteData['expenses']),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error fetching data: $e')),
      );
    }
  }

  void _findSyncIssues(
    List<Map<String, dynamic>> localTrips,
    List<Map<String, dynamic>> remoteTrips,
    List<Map<String, dynamic>> localExpenses,
    List<Map<String, dynamic>> remoteExpenses,
  ) async {
    // Mark this function as async
    final syncIssues = <String, Map<String, dynamic>>{};

    // Check for discrepancies in trips
    _findTripSyncIssues(localTrips, remoteTrips, syncIssues);

    // Check for discrepancies in expenses and associate them with the corresponding trip
    await _findExpenseSyncIssues(
        localExpenses, remoteExpenses, syncIssues); // Use await here

    setState(() {
      this.syncIssues = syncIssues.values.toList();
    });
  }

  void _findTripSyncIssues(
    List<Map<String, dynamic>> localTrips,
    List<Map<String, dynamic>> remoteTrips,
    Map<String, Map<String, dynamic>> syncIssues,
  ) {
    final localTripIds = localTrips.map((trip) => trip['id']).toSet();
    final remoteTripIds = remoteTrips.map((trip) => trip['_id']).toSet();

    // Local Only
    for (var trip
        in localTrips.where((trip) => !remoteTripIds.contains(trip['id']))) {
      syncIssues[trip['id']] = {
        'source': 'local',
        'localData': trip,
        'remoteData': null,
        'expenses': [],
      };
    }

    // Remote Only
    for (var trip
        in remoteTrips.where((trip) => !localTripIds.contains(trip['_id']))) {
      syncIssues[trip['_id']] = {
        'source': 'remote',
        'localData': null,
        'remoteData': trip,
        'expenses': [],
      };
    }

    // Conflicts
    for (var localTrip in localTrips) {
      final matchingRemoteTrip = remoteTrips.firstWhere(
        (trip) => trip['_id'] == localTrip['id'],
        orElse: () => {},
      );

      if (matchingRemoteTrip.isNotEmpty &&
          !_areTripsEqual(localTrip, matchingRemoteTrip)) {
        syncIssues[localTrip['id']] = {
          'source': 'conflict',
          'localData': localTrip,
          'remoteData': matchingRemoteTrip,
          'expenses': [],
        };
      }
    }
  }

  Future<void> _findExpenseSyncIssues(
    List<Map<String, dynamic>> localExpenses,
    List<Map<String, dynamic>> remoteExpenses,
    Map<String, Map<String, dynamic>> syncIssues,
  ) async {
    final localExpenseIds =
        localExpenses.map((expense) => expense['id']).toSet();
    final remoteExpenseIds =
        remoteExpenses.map((expense) => expense['_id']).toSet();

    for (var expense in localExpenses
        .where((expense) => !remoteExpenseIds.contains(expense['id']))) {
      final tripId = expense['trip_id'];

      // Fetch remote data asynchronously before adding to syncIssue
      final localTripData = HiveService.getTrip(tripId)?.toJson();
      final remoteTripData =
          await BackupService.getSpecificData("trips", tripId);

      var syncIssue = syncIssues.putIfAbsent(
        tripId,
        () => {
          'source': 'local',
          'localData': localTripData,
          'remoteData': remoteTripData,
          'expenses': [],
        },
      );

      syncIssue['expenses'].add({
        'source': 'local',
        'localData': expense,
        'remoteData': null,
      });
    }

    for (var expense in remoteExpenses
        .where((expense) => !localExpenseIds.contains(expense['_id']))) {
      final tripId = expense['trip_id'];

      // Fetch remote data asynchronously before adding to syncIssue
      final localTripData = HiveService.getTrip(tripId)?.toJson();
      final remoteTripData =
          await BackupService.getSpecificData("trips", tripId);

      var syncIssue = syncIssues.putIfAbsent(
        tripId,
        () => {
          'source': 'remote',
          'localData': localTripData,
          'remoteData': remoteTripData,
          'expenses': [],
        },
      );

      syncIssue['expenses'].add({
        'source': 'remote',
        'localData': null,
        'remoteData': expense,
      });
    }

    for (var localExpense in localExpenses) {
      final matchingRemoteExpense = remoteExpenses.firstWhere(
        (expense) => expense['_id'] == localExpense['id'],
        orElse: () => {},
      );

      if (matchingRemoteExpense.isNotEmpty &&
          !_areExpensesEqual(localExpense, matchingRemoteExpense)) {
        final tripId = localExpense['trip_id'];

        // Fetch remote data asynchronously before adding to syncIssue
        final localTripData = HiveService.getTrip(tripId)?.toJson();
        final remoteTripData =
            await BackupService.getSpecificData("trips", tripId);

        var syncIssue = syncIssues.putIfAbsent(
          tripId,
          () => {
            'source': 'conflict',
            'localData': localTripData,
            'remoteData': remoteTripData,
            'expenses': [],
          },
        );

        syncIssue['expenses'].add({
          'source': 'conflict',
          'localData': localExpense,
          'remoteData': matchingRemoteExpense,
        });
      }
    }

    setState(() {
      syncIssues.values.toList();
    });
  }

  bool _areTripsEqual(Map<String, dynamic> local, Map<String, dynamic> remote) {
    return local['name'] == remote['name'] &&
        local['start_date'] == remote['start_date'] &&
        local['end_date'] == remote['end_date'] &&
        local['total_money'] == remote['total_money'];
  }

  bool _areExpensesEqual(
      Map<String, dynamic> local, Map<String, dynamic> remote) {
    return local['name'] == remote['name'] &&
        local['amount'] == remote['amount'] &&
        local['is_sale'] == remote['is_sale'] &&
        local['sold_amount'] == remote['sold_amount'];
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
                final expenses =
                    List<Map<String, dynamic>>.from(issue['expenses']);

                return ListTile(
                  title: Text(trip['name']),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => DiscrepancyDetailPage(
                          localData: issue['localData'],
                          remoteData: issue['remoteData'],
                          expenses: expenses,
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
