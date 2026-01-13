import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/http/dio_client.dart';
import '../services/auth/token_storage.dart';
import '../services/auth/auth_api.dart';
import '../services/auth/auth_session.dart';

final secureStorageProvider = Provider<FlutterSecureStorage>(
  (ref) => const FlutterSecureStorage(),
);

final tokenStorageProvider = Provider<TokenStorage>(
  (ref) => TokenStorage(ref.watch(secureStorageProvider)),
);

final dioProvider = Provider<Dio>(
  (ref) => DioClient.create(),
);

final authApiProvider = Provider<AuthApi>(
  (ref) => AuthApi(ref.watch(dioProvider)),
);

final authSessionProvider = ChangeNotifierProvider<AuthSession>((ref) {
  return AuthSession(
    tokenStorage: ref.watch(tokenStorageProvider),
    api: ref.watch(authApiProvider),
  );
});
