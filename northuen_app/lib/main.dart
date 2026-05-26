import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'core/app_theme.dart';
import 'core/config.dart';
import 'screens/splash_screen.dart';
import 'services/api_client.dart';
import 'state/app_state.dart';
import 'state/cart_state.dart';
import 'widgets/global_incoming_call_listener.dart';

final northuenNavigatorKey = GlobalKey<NavigatorState>();

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  if (AppConfig.hasSupabaseRealtime) {
    await Supabase.initialize(
      url: AppConfig.supabaseUrl,
      anonKey: AppConfig.supabaseAnonKey,
    );
  }
  runApp(const NorthuenApp());
}

class NorthuenApp extends StatelessWidget {
  const NorthuenApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        Provider(create: (_) => ApiClient()),
        ChangeNotifierProxyProvider<ApiClient, AppState>(
          create: (context) => AppState(context.read<ApiClient>()),
          update: (_, api, state) => state ?? AppState(api),
        ),
        ChangeNotifierProvider(create: (_) => CartState()),
      ],
      child: MaterialApp(
        navigatorKey: northuenNavigatorKey,
        title: 'Northuen',
        debugShowCheckedModeBanner: false,
        theme: NorthuenTheme.light(),
        builder: (context, child) => GlobalIncomingCallListener(
          navigatorKey: northuenNavigatorKey,
          child: child ?? const SizedBox.shrink(),
        ),
        home: const SplashScreen(),
      ),
    );
  }
}
