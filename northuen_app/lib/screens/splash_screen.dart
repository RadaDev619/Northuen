import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/app_theme.dart';
import '../state/app_state.dart';
import '../widgets/northuen_ui.dart';
import 'auth_screen.dart';
import 'role_home_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  bool _started = false;
  late final AnimationController _animation = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
  )..forward();

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_started) {
      _started = true;
      _restore(context.read<AppState>(), Navigator.of(context));
    }
  }

  Future<void> _restore(AppState app, NavigatorState navigator) async {
    await app.restore();
    if (!mounted) return;
    navigator.pushReplacement(
      MaterialPageRoute(
        builder: (_) =>
            app.authenticated ? const RoleHomeScreen() : const AuthScreen(),
      ),
    );
  }

  @override
  void dispose() {
    _animation.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final fade = CurvedAnimation(parent: _animation, curve: Curves.easeOut);
    return Scaffold(
      backgroundColor: NorthuenTheme.primary,
      body: SafeArea(
        child: FadeTransition(
          opacity: fade,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 30),
            child: Column(
              children: [
                const Spacer(flex: 3),
                ScaleTransition(
                  scale: Tween<double>(begin: .82, end: 1).animate(fade),
                  child: const NorthuenBrandMark(size: 88, inverse: true),
                ),
                const SizedBox(height: 22),
                const Text(
                  'Northuen',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 38,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'One App. Every Delivery.',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 10),
                const Text(
                  'Food  •  Shops  •  Parcels  •  Pick & Drop',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.white70, fontSize: 13),
                ),
                const Spacer(flex: 3),
                const SizedBox(
                  width: 28,
                  height: 28,
                  child: CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 2.5,
                  ),
                ),
                const SizedBox(height: 18),
                const Text(
                  'Delivery built for Bhutan',
                  style: TextStyle(
                    color: Colors.white70,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
