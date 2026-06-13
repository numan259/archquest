import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'constants/strings.dart';
import 'providers/app_state_provider.dart';
import 'providers/progress_provider.dart';
import 'screens/subjects_screen.dart';
import 'services/content_loader.dart';
import 'services/progress_service.dart';
import 'theme/app_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final progressService = ProgressService();
  await progressService.init();

  runApp(ArchQuestApp(progressService: progressService));
}

class ArchQuestApp extends StatelessWidget {
  const ArchQuestApp({super.key, required this.progressService});

  final ProgressService progressService;

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
        home: const SubjectsScreen(),
      ),
    );
  }
}
