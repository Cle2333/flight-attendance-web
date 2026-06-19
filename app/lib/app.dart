import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'screens/login_screen.dart';
import 'screens/main_navigation.dart';
import 'state/app_state.dart';
import 'theme/app_theme.dart';

class FlightAttendanceApp extends StatelessWidget {
  final AppState appState;
  const FlightAttendanceApp({super.key, required this.appState});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      title: '航班打卡',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      initialBinding: BindingsBuilder(() {
        Get.put<AppState>(appState, permanent: true);
      }),
      home: const _Root(),
    );
  }
}

class _Root extends StatelessWidget {
  const _Root();

  @override
  Widget build(BuildContext context) {
    final state = Get.find<AppState>();
    return Obx(() {
      if (!state.booted.value) {
        return const Scaffold(
          backgroundColor: AppColors.bg,
          body: Center(child: CircularProgressIndicator()),
        );
      }
      final hasSession =
          state.currentUser.value != null || state.isLocalMode.value;
      if (!hasSession) {
        return const LoginScreen();
      }
      return const MainNavigation();
    });
  }
}
