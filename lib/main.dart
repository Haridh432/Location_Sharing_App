import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'providers/location_provider.dart';
import 'screens/home_screen.dart';
import 'screens/username_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const LiveLocationShareApp());
}

class LiveLocationShareApp extends StatelessWidget {
  const LiveLocationShareApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => LocationProvider()..initialize(),
      child: MaterialApp(
        title: 'Live Location Share',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          useMaterial3: true,
          brightness: Brightness.dark,
          scaffoldBackgroundColor: const Color(0xFF0F172A),
          colorScheme: const ColorScheme.dark(
            primary: Color(0xFF0284C7),
            secondary: Color(0xFF10B981),
            surface: Color(0xFF1E293B),
          ),
          fontFamily: 'Roboto',
        ),
        home: const RootScreenController(),
      ),
    );
  }
}

class RootScreenController extends StatelessWidget {
  const RootScreenController({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<LocationProvider>(
      builder: (context, provider, _) {
        if (!provider.isInitialized) {
          return const Scaffold(
            backgroundColor: Color(0xFF0F172A),
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(
                    width: 48,
                    height: 48,
                    child: CircularProgressIndicator(
                      color: Color(0xFF0284C7),
                      strokeWidth: 3,
                    ),
                  ),
                  SizedBox(height: 24),
                  Text(
                    'Live Location Share',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        if (!provider.hasUsername) {
          return const UsernameScreen();
        }

        return const HomeScreen();
      },
    );
  }
}
