import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'home_screen.dart';
import 'providers/task_provider.dart';
import 'services/api_service.dart';
import 'services/connectivity_service.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        Provider<ApiService>(
          // For physical devices, use your computer's IP address instead:
          // create: (_) => ApiService(baseUrl: 'http://192.168.0.171:3000/api'),
          // For emulator/simulator, use default (auto-detects platform):
          create: (_) => ApiService(),
        ),
        Provider<ConnectivityService>(create: (_) => ConnectivityService()),
        ChangeNotifierProxyProvider2<
          ApiService,
          ConnectivityService,
          TaskProvider
        >(
          create: (context) => TaskProvider(
            apiService: context.read<ApiService>(),
            connectivityService: context.read<ConnectivityService>(),
          ),
          update: (context, apiService, connectivityService, previous) =>
              previous ??
              TaskProvider(
                apiService: apiService,
                connectivityService: connectivityService,
              ),
        ),
      ],
      child: MaterialApp(
        title: 'Task Management',
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(
            seedColor: Colors.deepPurple,
            brightness: Brightness.light,
          ),
          useMaterial3: true,
        ),

        darkTheme: ThemeData(
          colorScheme: ColorScheme.fromSeed(
            seedColor: Colors.deepPurple,
            brightness: Brightness.dark,
          ),
          useMaterial3: true,
        ),

        themeMode: ThemeMode.system, // 👈 auto light/dark
        home: const HomeScreen(),
        debugShowCheckedModeBanner: false,
      ),
    );
  }
}
