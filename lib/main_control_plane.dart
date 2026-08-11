import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'control_plane/contract_center_page.dart';
import 'control_plane/control_plane_page.dart';
import 'control_plane/quote_center_page.dart';
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
          ? const _ControlPlaneShell()
          : const _BackendMissingPage(),
    );
  }
}

class _ControlPlaneShell extends StatefulWidget {
  const _ControlPlaneShell();

  @override
  State<_ControlPlaneShell> createState() => _ControlPlaneShellState();
}

class _ControlPlaneShellState extends State<_ControlPlaneShell> {
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _index,
        children: const [
          EventoControlPlanePage(),
          EventoQuoteCenterPage(),
          EventoContractCenterPage(),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (value) => setState(() => _index = value),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.dashboard_outlined),
            selectedIcon: Icon(Icons.dashboard),
            label: 'Control',
          ),
          NavigationDestination(
            icon: Icon(Icons.request_quote_outlined),
            selectedIcon: Icon(Icons.request_quote),
            label: 'Quotes',
          ),
          NavigationDestination(
            icon: Icon(Icons.description_outlined),
            selectedIcon: Icon(Icons.description),
            label: 'Contracts',
          ),
        ],
      ),
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
