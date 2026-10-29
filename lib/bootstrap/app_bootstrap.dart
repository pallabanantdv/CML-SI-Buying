import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter/widgets.dart';

import '../app.dart';
import '../core/di/dependency_injection.dart';

abstract final class AppBootstrap {
  static Future<void> initialize() async {
    try {
      await dotenv.load(fileName: '.env');
    } catch (_) {
      await dotenv.load(fileName: '.env.example');
    }
    final dependencies = await DependencyInjection.create();
    runApp(CmlSiBuyingApp(dependencies: dependencies));
  }
}
