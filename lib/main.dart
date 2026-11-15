import 'package:flutter/material.dart';
import 'api.dart';
import 'theme/colors.dart';
import 'screens/auth/login_screen.dart';
import 'main_app.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Api.init();
  runApp(const InventoryApp());
}

class InventoryApp extends StatelessWidget {
  const InventoryApp({super.key});

  @override
  Widget build(BuildContext context) {
    final loggedIn = Api.token != null && Api.token!.isNotEmpty;
    return MaterialApp(
      title: 'Inventory Manager',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      initialRoute: loggedIn ? '/home' : '/login',
      routes: {
        '/login': (_) => const LoginScreen(),
        '/home': (_) => const MainApp(),
      },
    );
  }
}
