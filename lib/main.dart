import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'screens/main_menu.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Lock to landscape (mobile shooters play best horizontally)
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.landscapeLeft,
    DeviceOrientation.landscapeRight,
  ]);
  await SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);

  runApp(const PlasticPlatoonApp());
}

class PlasticPlatoonApp extends StatelessWidget {
  const PlasticPlatoonApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Plastic Platoon',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark().copyWith(
        colorScheme: ColorScheme.dark(
          primary: const Color(0xFF4CAF50),
          secondary: const Color(0xFFFFD54F),
        ),
      ),
      home: const MainMenuScreen(),
    );
  }
}
