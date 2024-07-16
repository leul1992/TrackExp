import 'package:flutter/material.dart';
import 'package:trackexp/screens/add_trip.dart';
import 'package:trackexp/services/hive_services.dart';
import 'package:trackexp/utils/temp/analytics_page.dart';
import 'package:trackexp/screens/home_page.dart';
import 'package:trackexp/utils/temp/settings_page.dart';
import 'package:hive_flutter/hive_flutter.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Hive.initFlutter();
  await HiveService.openBoxes();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: RootPage(),
    );
  }
}

class RootPage extends StatefulWidget {
  const RootPage({super.key});

  @override
  State<RootPage> createState() => _RootPageState();
}

class _RootPageState extends State<RootPage> {
  int currentPage = 0;
  
  List<Widget> pages = [
    HomePage(key: UniqueKey()), // Ensure HomePage is a unique widget
    const AnalyticsPage(),
    const SettingsPage(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF58B7B1),
        title: Row(
          children: [
            const Text(
              "TrackExp",
              style: TextStyle(color: Colors.white),
            ),
            const SizedBox(width: 20),
            const Expanded(
              child: TextField(
                style: TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  hintText: 'Search...',
                  hintStyle: TextStyle(color: Colors.white70),
                  border: InputBorder.none,
                ),
              ),
            ),
            IconButton(
              onPressed: () {
                debugPrint("Search");
              },
              icon: const Icon(Icons.search, color: Colors.white),
            ),
          ],
        ),
        actions: [
          IconButton(
            onPressed: () {
              debugPrint("Filter");
            },
            icon: const Icon(Icons.date_range, size: 30, color: Colors.white),
          ),
          IconButton(
            onPressed: () async {
              final result = await showDialog(
                context: context,
                builder: (BuildContext context) {
                  return AlertDialog(
                    content: AddTripForm(
                      refreshTrips: () {
                        // Temporary placeholder
                        // Add your logic here
                        return Future<void>.value();
                      },
                    ),
                  );
                },
              );
              if (result == true) {
                // Refresh trips only if a new trip was added
                setState(() {
                  pages[0] = HomePage(key: UniqueKey()); // Force HomePage to rebuild
                });
              }
            },
            icon: const Icon(Icons.add_box_outlined, size: 30, color: Colors.white),
          ),
        ],
      ),
      body: pages[currentPage],
      bottomNavigationBar: BottomNavigationBar(
        fixedColor: const Color(0xFF58B7B1),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.edit_document), label: 'Analytics'),
          BottomNavigationBarItem(icon: Icon(Icons.settings), label: 'Settings'),
        ],
        onTap: (int index) {
          setState(() {
            currentPage = index;
          });
        },
        currentIndex: currentPage,
      ),
    );
  }
}
