import 'package:flutter/material.dart';

import 'data/one/one_build_config.dart';
import 'data/one/one_member_gateway.dart';
import 'features/one/one_member_app.dart';
import 'features/one/one_member_controller.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  final config = OneBuildConfig.fromEnvironment();
  runApp(
    OneMemberApp(
      controller: OneMemberController(
        config == null ? null : SupabaseOneMemberGateway(config),
      ),
    ),
  );
}
