import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'router/app_router.dart';
import 'ui/theme/app_theme.dart';

class CyberStepsApp extends ConsumerWidget {
  const CyberStepsApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Force Arabic + RTL for Patch 0 (you can expand locales later).
    return MaterialApp.router(
      debugShowCheckedModeBanner: false,
      title: 'CyberSteps',
      theme: AppTheme.light(),
      locale: const Locale('ar'),
      supportedLocales: const [Locale('ar')],
      localizationsDelegates: [
  GlobalMaterialLocalizations.delegate,
  GlobalWidgetsLocalizations.delegate,
  GlobalCupertinoLocalizations.delegate,
],
      routerConfig: AppRouter.router,
      builder: (context, child) {
        return Directionality(
          textDirection: TextDirection.rtl,
          child: child ?? const SizedBox.shrink(),
        );
      },
    );
  }
}
