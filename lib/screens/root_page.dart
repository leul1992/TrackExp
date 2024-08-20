import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:trackexp/provider/login_state_provider.dart';
import 'package:trackexp/screens/local/add_trip.dart';
import 'package:trackexp/screens/backup/sync_data.dart';
import 'package:trackexp/screens/local/home_page.dart';
import 'package:trackexp/screens/profile_sidebar.dart';
import 'package:trackexp/utils/temp/analytics_page.dart';
import 'package:trackexp/utils/temp/settings_page.dart';
import 'package:trackexp/screens/authentication/login_dialog.dart'; // Import the new dialog

class RootPage extends StatefulWidget {
  const RootPage({super.key});

  @override
  State<RootPage> createState() => _RootPageState();
}

class _RootPageState extends State<RootPage> {
  int currentPage = 0;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  final List<Widget> pages = [
    HomePage(key: UniqueKey()),
    const AnalyticsPage(),
    const SettingsPage(),
    const SyncPage(),
  ];

  @override
  Widget build(BuildContext context) {
    bool isLoggedIn = Provider.of<LoginStateProvider>(context).isLoggedIn;

    return Scaffold(
      key: _scaffoldKey,
      appBar: AppBar(
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
          if (isLoggedIn)
            IconButton(
              icon: const Icon(Icons.person, size: 30, color: Colors.white),
              onPressed: () {
                _scaffoldKey.currentState?.openEndDrawer();
              },
            ),
        ],
      ),
      body: pages[currentPage],
      bottomNavigationBar: BottomNavigationBar(
        selectedItemColor: const Color(0xFF58B7B1),
        unselectedItemColor: Colors.grey,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.percent_outlined),
            label: 'Status',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings),
            label: 'Settings',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.backup_outlined),
            label: "BackUp",
          ),
        ],
        onTap: (int index) {
          if (index == 3) {
            bool isLoggedIn = Provider.of<LoginStateProvider>(context, listen: false).isLoggedIn;
            if (!isLoggedIn) {
              showDialog(
                context: context,
                builder: (BuildContext context) {
                  return const LoginDialog();
                },
              );
            } else {
              setState(() {
                currentPage = index;
              });
            }
          } else {
            setState(() {
              currentPage = index;
            });
          }
        },
        currentIndex: currentPage,
      ),
      endDrawer: isLoggedIn ? const ProfileSidebar() : null,
    );
  }
}
