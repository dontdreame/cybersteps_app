import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/http/dio_client.dart';

final dioProvider = Provider<Dio>((ref) => DioClient.create());

/// App-level placeholders for future:
/// final authStateProvider = StateNotifierProvider<AuthNotifier, AuthState>(...);
