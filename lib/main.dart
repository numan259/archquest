import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'constants/strings.dart';
import 'providers/app_state_provider.dart';
import 'providers/progress_provider.dart';
import 'screens/splash_screen.dart';
import 'screens/subjects_screen.dart';
import 'services/content_loader.dart';
import 'services/progress_service.dart';
import 'theme/app_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final progressService = ProgressService();
  await progressService.init();

  runApp(ArchQuestApp(
      progressService: progressService, home: const SplashScreen()));
}

class ArchQuestApp extends StatelessWidget {
  const ArchQuestApp({super.key, required this.progressService, this.home});

  final ProgressService progressService;

  /// Entry screen. The real app passes [SplashScreen]; tests omit it to boot
  /// straight to the Subjects screen (avoiding the splash timer).
  final Widget? home;

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AppStateProvider(ContentLoader())),
        ChangeNotifierProvider(create: (_) => ProgressProvider(progressService)),
      ],
      child: MaterialApp(
        title: Strings.appName,
        debugShowCheckedModeBanner: false,
        theme: AppTheme.dark,
        home: home ?? const SubjectsScreen(),
      ),
    );
  }
}
