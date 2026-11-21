import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'screens/login_screen.dart';
import 'screens/vehicle_list_screen.dart';
import 'services/auth_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await AuthService.init();
  runApp(
    const ProviderScope(child: StarkVmsApp()),
  );
}

class StarkVmsApp extends StatelessWidget {
  const StarkVmsApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ShadApp(
      title: 'Stark Group VMS',
      debugShowCheckedModeBanner: false,
      themeMode: ThemeMode.light,
      theme: ShadThemeData(
        brightness: Brightness.light,
        colorScheme: const ShadSlateColorScheme.light(),
      ),
      home: AuthService.isLoggedIn
          ? const VehicleListScreen()
          : const LoginScreen(),
    );
  }
}
