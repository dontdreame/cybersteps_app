import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../features/splash/splash_screen.dart';
import '../features/home/home_screen.dart';
import '../features/auth/login_email_screen.dart';
import '../features/auth/login_phone_screen.dart';
import '../features/auth/login_otp_screen.dart';
import '../state/providers.dart';
import '../services/auth/auth_session.dart';

class AppRouter {
  AppRouter._();

  static final routerProvider = Provider<GoRouter>((ref) {
    final session = ref.watch(authSessionProvider);

    return GoRouter(
      initialLocation: SplashScreen.routePath,
      refreshListenable: session,
      redirect: (context, state) {
        final loc = state.matchedLocation;

        final isSplash = loc == SplashScreen.routePath;
        final isLogin = loc.startsWith(LoginEmailScreen.routePath);

        // During bootstrap, keep splash
        if (session.status == AuthStatus.unknown) {
          return isSplash ? null : SplashScreen.routePath;
        }

        // Not logged in → force /login (except already on login routes)
        if (!session.isAuthed) {
          if (isLogin) return null;
          return LoginEmailScreen.routePath;
        }

        // Logged in → prevent visiting login routes
        if (session.isAuthed && isLogin) {
          return HomeScreen.routePath;
        }

        return null;
      },
      routes: [
        GoRoute(
          path: SplashScreen.routePath,
          name: SplashScreen.routeName,
          builder: (context, state) => const SplashScreen(),
        ),
        GoRoute(
          path: HomeScreen.routePath,
          name: HomeScreen.routeName,
          builder: (context, state) => const HomeScreen(),
        ),
        GoRoute(
          path: LoginEmailScreen.routePath,
          name: LoginEmailScreen.routeName,
          builder: (context, state) => const LoginEmailScreen(),
          routes: [
            GoRoute(
              path: 'phone',
              name: LoginPhoneScreen.routeName,
              builder: (context, state) => const LoginPhoneScreen(),
            ),
            GoRoute(
              path: 'otp',
              name: LoginOtpScreen.routeName,
              builder: (context, state) => const LoginOtpScreen(),
            ),
          ],
        ),
      ],
      errorBuilder: (context, state) => Scaffold(
        body: Center(
          child: Text(
            'Route error: ${state.error}',
            textDirection: TextDirection.rtl,
          ),
        ),
      ),
    );
  });
}
