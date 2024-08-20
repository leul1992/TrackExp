import 'package:flutter/material.dart';
import 'package:trackexp/models/trip.dart';
import 'package:trackexp/screens/local/detail_page.dart';
import 'package:trackexp/services/hive_services.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  Future<List<Trip>>? tripsFuture;

  @override
  void initState() {
    super.initState();
    _refreshTrips();
  }

  Future<void> _refreshTrips() async {
    setState(() {
      tripsFuture = HiveService.getTrips();
    });
  }

  Future<void> _navigateAndRefreshOnReturn(
      BuildContext context, Widget page) async {
    final result = await Navigator.of(context).push(
      MaterialPageRoute(builder: (context) => page),
    );
    if (result == true) {
      _refreshTrips(); // Refresh trips after returning from AddTripForm
    }
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: _refreshTrips,
      child: Column(
        children: [
          Expanded(
            child: FutureBuilder<List<Trip>>(
              future: tripsFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                } else if (snapshot.hasError) {
                  return const Center(child: Text('Error'));
                } else if (snapshot.data == null || snapshot.data!.isEmpty) {
                  return const Center(child: Text('No data available'));
                } else {
                  final trips = snapshot.data!;
                  return Padding(
                    padding: const EdgeInsets.all(10.0),
                    child: GridView.builder(
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        crossAxisSpacing: 8.0,
                        mainAxisSpacing: 8.0,
                        childAspectRatio: 2.0,
                      ),
                      itemCount: trips.length,
                      itemBuilder: (context, index) {
                        return TripCard(
                          trip: trips[index],
                          key: ValueKey(trips[index].id),
                          onTripSelected: () {
                            _navigateAndRefreshOnReturn(
                              context,
                              DetailView(
                                key: ValueKey(trips[index].id),
                                tripId: trips[index].id,
                                onTripUpdated: _refreshTrips,
                              ),
                            );
                          },
                        );
                      },
                    ),
                  );
                }
              },
            ),
          ),
        ],
      ),
    );
  }
}

class TripCard extends StatelessWidget {
  final Trip trip;
  final VoidCallback onTripSelected;

  const TripCard({super.key, required this.trip, required this.onTripSelected});

  @override
  Widget build(BuildContext context) {
    late Color cardColor;
    late Color indicatorColor;

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
      default:
        cardColor = Colors.white;
        indicatorColor = Colors.grey;
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
            onTap: onTripSelected,
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
