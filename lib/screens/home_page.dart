import 'package:flutter/material.dart';
import 'package:trackexp/screens/detail_page.dart';
import 'package:trackexp/services/database_helper.dart';

enum TripStatus { notStarted, inProgress, ended }

class Trip {
  final int id;
  final String name;
  final double totalMoney;
  final String startDate;
  final String endDate;

  Trip({
    required this.id,
    required this.name,
    required this.totalMoney,
    required this.startDate,
    required this.endDate,
  });

  TripStatus getStatus() {
    final now = DateTime.now();
    final tripStartDate = DateTime.parse(startDate);
    final tripEndDate = DateTime.parse(endDate);

    if (now.isBefore(tripStartDate)) {
      return TripStatus.notStarted;
    } else if (now.isAfter(tripStartDate) && now.isBefore(tripEndDate)) {
      return TripStatus.inProgress;
    } else {
      return TripStatus.ended;
    }
  }
}

class HomePage extends StatefulWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  @override
  void initState() {
    super.initState();
    _refreshTrips();
  }
  Future<void> _refreshTrips() async {
    setState(() {
    });
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: _refreshTrips,
      child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 1.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  IconButton(
                    onPressed: _refreshTrips,
                    icon: const Icon(Icons.refresh),
                  ),
                ],
              ),
            ),
            Expanded(
      child: FutureBuilder<List<Map<String, dynamic>>>(
        future: DatabaseHelper.instance.getTrips(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return const Center(child: Text('Error'));
          } else if (snapshot.data == null || snapshot.data!.isEmpty) {
            return const Center(child: Text('No data available'));
          } else {
            final trips = snapshot.data!
                .map((e) => Trip(
                      id: e['id'],
                      name: e['name'],
                      totalMoney: e['total_money'],
                      startDate: e['start_date'],
                      endDate: e['end_date'],
                    ))
                .toList();
            return Padding(
              padding: const EdgeInsets.all(10.0),
              child: GridView.builder(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 8.0,
                  mainAxisSpacing: 8.0,
                  childAspectRatio: 2.0, // Adjust this value as needed for card aspect ratio
                ),
                itemCount: trips.length,
                itemBuilder: (context, index) {
                  return TripCard(
                    trip: trips[index],
                    key: ValueKey<int>(trips[index].id), // Use ValueKey with trip ID
                  );
                },
              ),
            );
          }
        },
          ),
      ),
          ]
    ),
    );
  }
}


class TripCard extends StatelessWidget {
  final Trip trip;

  const TripCard({super.key, required this.trip});

  @override
  Widget build(BuildContext context) {
    Color cardColor;
    Color indicatorColor;
    switch (trip.getStatus()) {
      case TripStatus.notStarted:
        cardColor = const Color.fromARGB(255, 196, 249, 196);
        indicatorColor = Colors.green;
        break;
      case TripStatus.inProgress:
        cardColor = const Color.fromARGB(255, 242, 249, 196);
        indicatorColor = Colors.yellow;
        break;
      case TripStatus.ended:
        cardColor = const Color.fromARGB(255, 250, 214, 214);
        indicatorColor = Colors.red;
        break;
    }

    return Stack(
      children: [
        Card(
          color: cardColor.withOpacity(1),
          margin: const EdgeInsets.all(4.0),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8.0),
          ),
          child: ListTile(
            title: Text(
              trip.name,
              overflow: TextOverflow.ellipsis,
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('${trip.totalMoney}'),
                Text(trip.startDate),
              ],
            ),
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (BuildContext context) {
                    return DetailView(key: ValueKey<int>(trip.id), tripId: trip.id);
                  },
                ),
              );
            },
          ),
        ),
        Positioned(
          top: 0, // Adjust as needed
          right: 3.0, // Adjust as needed
          child: Container(
            width: 32.0,
            height: 16.0,
            decoration: BoxDecoration(
              color: indicatorColor, // Color for the indicator
              borderRadius: BorderRadius.circular(4.0),
              border: Border.all(
                color: Colors.white, // Common border color
                width: 1.0,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
