import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'control_plane/control_plane_page.dart';
import 'core/backend_config.dart';
import 'core/evento_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  if (BackendConfig.isConfigured) {
    await Supabase.initialize(
      url: BackendConfig.supabaseUrl,
      publishableKey: BackendConfig.supabasePublishableKey,
    );
  }

  runApp(const EventoControlPlanePreviewApp());
}

class EventoControlPlanePreviewApp extends StatelessWidget {
  const EventoControlPlanePreviewApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'EVENTO Control Plane V1',
      theme: buildEventoTheme(),
      home: BackendConfig.isConfigured
          ? const EventoControlPlanePage()
          : const _BackendMissingPage(),
    );
  }
}

class _BackendMissingPage extends StatelessWidget {
  const _BackendMissingPage();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Text(
            'EVENTO backend configuration is missing. Build with SUPABASE_URL and SUPABASE_PUBLISHABLE_KEY.',
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }
}
