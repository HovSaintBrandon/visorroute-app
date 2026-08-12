import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dio_client.dart';

/// Single shared DioClient (and its AuthInterceptor instance) for the whole
/// app, so login/refresh/logout all drive the same in-memory token state
/// that every repository's requests are authenticated against.
final dioClientProvider = Provider<DioClient>((ref) => DioClient());
