import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'screens/customer_tracking_screen.dart';
import 'screens/runner_navigation_screen.dart';
import 'services/app_config.dart';
import 'services/tracking_api.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  if (AppConfig.hasSupabase) {
    await Supabase.initialize(
      url: AppConfig.supabaseUrl,
      anonKey: AppConfig.supabaseAnonKey,
    );
  }
  runApp(const NorthuenTrackingApp());
}

class NorthuenTrackingApp extends StatelessWidget {
  const NorthuenTrackingApp({super.key});

  static const demoOrderId = '00000000-0000-0000-0000-000000000001';
  static const demoRunnerId = '00000000-0000-0000-0000-000000000002';
  static const pickup = LatLngPoint(lat: 27.4728, lng: 89.6390);
  static const dropoff = LatLngPoint(lat: 27.4850, lng: 89.6250);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Northuen Tracking',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xff166534)),
        useMaterial3: true,
      ),
      home: const _TrackingShell(),
    );
  }
}

class _TrackingShell extends StatefulWidget {
  const _TrackingShell();

  @override
  State<_TrackingShell> createState() => _TrackingShellState();
}

class _TrackingShellState extends State<_TrackingShell> {
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    final pages = [
      const RunnerNavigationScreen(
        orderId: NorthuenTrackingApp.demoOrderId,
        runnerId: NorthuenTrackingApp.demoRunnerId,
        orderStatus: 'accepted',
        pickup: NorthuenTrackingApp.pickup,
        dropoff: NorthuenTrackingApp.dropoff,
      ),
      const CustomerTrackingScreen(
        orderId: NorthuenTrackingApp.demoOrderId,
        pickup: NorthuenTrackingApp.pickup,
        dropoff: NorthuenTrackingApp.dropoff,
      ),
    ];
    return Scaffold(
      body: pages[_index],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (value) => setState(() => _index = value),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.navigation_rounded),
            label: 'Runner',
          ),
          NavigationDestination(
            icon: Icon(Icons.location_searching_rounded),
            label: 'Customer',
          ),
        ],
      ),
    );
  }
}
