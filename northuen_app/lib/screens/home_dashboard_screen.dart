import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:provider/provider.dart';

import '../state/app_state.dart';

class HomeDashboardScreen extends StatelessWidget {
  const HomeDashboardScreen({
    super.key,
    required this.onPickDrop,
    required this.onFood,
  });

  final VoidCallback onPickDrop;
  final VoidCallback onFood;

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AppState>().user;
    const center = LatLng(27.4728, 89.6390);
    return ListView(
      padding: EdgeInsets.zero,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(18, 10, 18, 14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Kuzuzangpo, ${_firstName(user?.fullName ?? 'Chencho')}',
                          style: Theme.of(context).textTheme.headlineSmall
                              ?.copyWith(fontWeight: FontWeight.w900),
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          'Thimphu, Bhutan',
                          style: TextStyle(
                            color: Color(0xFF6B7280),
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                  CircleAvatar(
                    backgroundColor: const Color(0xFFD2AB50),
                    child: Text(
                      _firstName(
                        user?.fullName ?? 'C',
                      ).characters.first.toUpperCase(),
                      style: const TextStyle(
                        color: Color(0xFF1E1E1E),
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 14,
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: .05),
                      blurRadius: 18,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: const Row(
                  children: [
                    Icon(Icons.search_rounded, color: Color(0xFF6B7280)),
                    SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Where do you want to go?',
                        style: TextStyle(
                          color: Color(0xFF6B7280),
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        SizedBox(
          height: 230,
          child: Stack(
            children: [
              GoogleMap(
                initialCameraPosition: CameraPosition(target: center, zoom: 13),
                zoomControlsEnabled: false,
                myLocationButtonEnabled: false,
                scrollGesturesEnabled: false,
                zoomGesturesEnabled: false,
                rotateGesturesEnabled: false,
                tiltGesturesEnabled: false,
                markers: {
                  const Marker(markerId: MarkerId('current'), position: center),
                  const Marker(
                    markerId: MarkerId('driver1'),
                    position: LatLng(27.4779, 89.6362),
                  ),
                  const Marker(
                    markerId: MarkerId('driver2'),
                    position: LatLng(27.4694, 89.6420),
                  ),
                  const Marker(
                    markerId: MarkerId('driver3'),
                    position: LatLng(27.4835, 89.6290),
                  ),
                },
              ),
              Positioned(
                left: 18,
                right: 18,
                bottom: 14,
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(18),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: .10),
                        blurRadius: 24,
                        offset: const Offset(0, 12),
                      ),
                    ],
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.location_on_rounded, color: Color(0xFFD2AB50)),
                      SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Current location: Clock Tower Square',
                          style: TextStyle(fontWeight: FontWeight.w800),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Book a service',
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: 12),
              GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: 2,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 1.18,
                children: [
                  _ServiceCard(
                    icon: Icons.two_wheeler_rounded,
                    title: 'Ride',
                    subtitle: 'Bike and car rides',
                    onTap: onPickDrop,
                  ),
                  _ServiceCard(
                    icon: Icons.inventory_2_rounded,
                    title: 'Parcel Delivery',
                    subtitle: 'Send packages fast',
                    onTap: onPickDrop,
                  ),
                  _ServiceCard(
                    icon: Icons.restaurant_rounded,
                    title: 'Food Delivery',
                    subtitle: 'Local meals nearby',
                    onTap: onFood,
                  ),
                  _ServiceCard(
                    icon: Icons.route_rounded,
                    title: 'Pick & Drop',
                    subtitle: 'Runner for errands',
                    onTap: onPickDrop,
                  ),
                ],
              ),
              const SizedBox(height: 18),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFF1E1E1E),
                  borderRadius: BorderRadius.circular(22),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.payments_rounded, color: Color(0xFFD2AB50)),
                    SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Cash, wallet, QR, and bank transfer options ready for Bhutan pilots.',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  static String _firstName(String value) => value.trim().split(' ').first;
}

class _ServiceCard extends StatelessWidget {
  const _ServiceCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(22),
      child: Ink(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(22),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: .05),
              blurRadius: 16,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: const Color(0xFFD2AB50).withValues(alpha: .18),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(icon, color: const Color(0xFF1E1E1E)),
            ),
            const Spacer(),
            Text(
              title,
              style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: const TextStyle(
                color: Color(0xFF6B7280),
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
