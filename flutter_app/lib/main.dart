import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'core/api/api_client.dart';
import 'core/auth/auth_provider.dart';
import 'core/router.dart';
import 'core/theme.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  final auth = AuthProvider();
  ApiClient.instance.onUnauthorized = auth.handleSessionExpired;
  auth.bootstrap();
  runApp(ReturnLoadApp(auth: auth));
}

/// Removes Android's stretch/glow overscroll effect so content no longer
/// visually detaches from its background when the user overscrolls.
/// RefreshIndicators keep working normally.
class _NoStretchScrollBehavior extends MaterialScrollBehavior {
  const _NoStretchScrollBehavior();

  @override
  Widget buildOverscrollIndicator(
      BuildContext context, Widget child, ScrollableDetails details) {
    return child;
  }
}

class ReturnLoadApp extends StatefulWidget {
  final AuthProvider auth;
  const ReturnLoadApp({super.key, required this.auth});

  @override
  State<ReturnLoadApp> createState() => _ReturnLoadAppState();
}

class _ReturnLoadAppState extends State<ReturnLoadApp> {
  late final _router = buildRouter(widget.auth);

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(
      value: widget.auth,
      child: MaterialApp.router(
        title: 'ReturnLoad',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light(),
        scrollBehavior: const _NoStretchScrollBehavior(),
        routerConfig: _router,
      ),
    );
  }
}
