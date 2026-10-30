import 'package:flutter/foundation.dart';

import '../repositories/dashboard_repository.dart';

class DashboardViewModel extends ChangeNotifier {
  DashboardViewModel(this.repository);

  final DashboardRepository repository;

  String get title => 'Dashboard';
  String get placeholder =>
      'Your buying workspace will be configured when dashboard requirements are provided.';
}
