import 'package:flutter/material.dart';

import 'src/services/app_environment.dart';
import 'src/ui/workbench_app.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final environment = await AppEnvironment.create();
  runApp(WorkbenchApp(environment: environment));
}
