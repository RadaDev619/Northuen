import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/app_theme.dart';
import '../state/app_state.dart';
import '../widgets/northuen_ui.dart';

class HomeDashboardScreen extends StatelessWidget {
  const HomeDashboardScreen({
    super.key,
    required this.onPickDrop,
    required this.onFood,
    required this.onShop,
    required this.onParcel,
  });

  final VoidCallback onPickDrop;
  final VoidCallback onFood;
  final VoidCallback onShop;
  final VoidCallback onParcel;

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AppState>().user;
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 28),
      children: [
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Deliver to',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  const SizedBox(height: 3),
                  const Row(
                    children: [
                      Icon(
                        Icons.location_on_rounded,
                        color: NorthuenTheme.orange,
                        size: 18,
                      ),
                      SizedBox(width: 5),
                      Text(
                        'Thimphu, Bhutan',
                        style: TextStyle(fontWeight: FontWeight.w800),
                      ),
                      Icon(Icons.keyboard_arrow_down_rounded),
                    ],
                  ),
                ],
              ),
            ),
            CircleAvatar(
              radius: 21,
              backgroundColor: NorthuenTheme.primary.withValues(alpha: .1),
              child: Text(
                _firstName(
                  user?.fullName ?? 'N',
                ).characters.first.toUpperCase(),
                style: const TextStyle(
                  color: NorthuenTheme.primary,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 18),
        Text(
          'Kuzuzangpo, ${_firstName(user?.fullName ?? 'there')}',
          style: Theme.of(context).textTheme.headlineSmall,
        ),
        const SizedBox(height: 4),
        Text(
          'What can we deliver for you today?',
          style: Theme.of(
            context,
          ).textTheme.bodyLarge?.copyWith(color: NorthuenTheme.muted),
        ),
        const SizedBox(height: 16),
        InkWell(
          onTap: onFood,
          borderRadius: BorderRadius.circular(8),
          child: const IgnorePointer(
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Search food, shops and products',
                prefixIcon: Icon(Icons.search_rounded),
                suffixIcon: Icon(Icons.tune_rounded),
              ),
            ),
          ),
        ),
        const SizedBox(height: 22),
        const NorthuenSectionHeader(
          title: 'Services',
          subtitle: 'One app for every local delivery',
        ),
        const SizedBox(height: 12),
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisSpacing: 10,
          mainAxisSpacing: 10,
          childAspectRatio: 1.55,
          children: [
            _ServiceItem(
              icon: Icons.restaurant_rounded,
              label: 'Food',
              subtitle: 'Meals from local kitchens',
              color: NorthuenTheme.orange,
              onTap: onFood,
            ),
            _ServiceItem(
              icon: Icons.storefront_rounded,
              label: 'Shops',
              subtitle: 'Browse nearby stores',
              color: NorthuenTheme.teal,
              onTap: onShop,
            ),
            _ServiceItem(
              icon: Icons.shopping_basket_rounded,
              label: 'Grocery',
              subtitle: 'Daily essentials delivered',
              color: NorthuenTheme.success,
              onTap: onShop,
            ),
            _ServiceItem(
              icon: Icons.route_rounded,
              label: 'Pick & Drop',
              subtitle: 'Runner for local errands',
              color: NorthuenTheme.primary,
              onTap: onPickDrop,
            ),
          ],
        ),
        const SizedBox(height: 10),
        _ParcelServiceCard(onTap: onParcel),
        const SizedBox(height: 22),
        _PromoBanner(onTap: onPickDrop),
        const SizedBox(height: 24),
        NorthuenSectionHeader(
          title: 'Fast local delivery',
          subtitle: 'Built for daily errands around Bhutan',
          actionLabel: 'Explore',
          onAction: onFood,
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _BenefitCard(
                icon: Icons.payments_outlined,
                title: 'Cash on delivery',
                caption: 'Pay when your order arrives',
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _BenefitCard(
                icon: Icons.location_searching_rounded,
                title: 'Live tracking',
                caption: 'Follow your runner in real time',
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: _BenefitCard(
                icon: Icons.support_agent_rounded,
                title: 'Direct contact',
                caption: 'Chat or call your runner',
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _BenefitCard(
                icon: Icons.verified_user_outlined,
                title: 'Reliable service',
                caption: 'Clear status at every step',
              ),
            ),
          ],
        ),
      ],
    );
  }

  static String _firstName(String value) => value.trim().split(' ').first;
}

class _ServiceItem extends StatelessWidget {
  const _ServiceItem({
    required this.icon,
    required this.label,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(13),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: .1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(icon, color: color, size: 22),
                  ),
                  const Spacer(),
                  Icon(Icons.arrow_forward_rounded, color: color, size: 18),
                ],
              ),
              const Spacer(),
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ParcelServiceCard extends StatelessWidget {
  const _ParcelServiceCard({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: NorthuenTheme.orange.withValues(alpha: .1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.inventory_2_outlined,
                  color: NorthuenTheme.orange,
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Send a parcel',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    SizedBox(height: 3),
                    Text(
                      'Book a standard parcel delivery with cash on delivery.',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: NorthuenTheme.muted,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.arrow_forward_rounded,
                color: NorthuenTheme.orange,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PromoBanner extends StatelessWidget {
  const _PromoBanner({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: NorthuenTheme.primary,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Need something moved?',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Book a local runner for parcels, documents and errands.',
                  style: TextStyle(color: Colors.white70, height: 1.35),
                ),
                const SizedBox(height: 14),
                FilledButton.icon(
                  style: FilledButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: NorthuenTheme.primary,
                    minimumSize: const Size(0, 40),
                  ),
                  onPressed: onTap,
                  icon: const Icon(Icons.arrow_forward_rounded, size: 18),
                  label: const Text('Book Pick & Drop'),
                ),
              ],
            ),
          ),
          const SizedBox(width: 14),
          const Icon(
            Icons.delivery_dining_rounded,
            color: Colors.white,
            size: 64,
          ),
        ],
      ),
    );
  }
}

class _BenefitCard extends StatelessWidget {
  const _BenefitCard({
    required this.icon,
    required this.title,
    required this.caption,
  });
  final IconData icon;
  final String title;
  final String caption;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: NorthuenTheme.teal),
            const SizedBox(height: 12),
            Text(title, style: const TextStyle(fontWeight: FontWeight.w800)),
            const SizedBox(height: 3),
            Text(caption, style: Theme.of(context).textTheme.bodySmall),
          ],
        ),
      ),
    );
  }
}
