
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';

import 'firebase_options.dart';
import 'database/app_database.dart';
import 'services/sample_event_remote_service.dart';
import 'repositories/sample_event_repository.dart';
import 'pages/sample_list_page.dart';
import 'theme/app_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  final database = AppDatabase();

  final remoteService = SampleEventRemoteService();

  final repository = SampleEventRepository(
    database: database,
    remoteService: remoteService,
  );

  runApp(SampleTrackApp(repository: repository));
}

class SampleTrackApp extends StatelessWidget {
  const SampleTrackApp({
    super.key,
    required this.repository,
  });

  final SampleEventRepository repository;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SampleTrack',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      home: SampleListPage(repository: repository),
    );
  }
}
