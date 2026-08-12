import 'package:dio/dio.dart';
import '../storage/token_storage.dart';

class AuthInterceptor extends Interceptor {
  String? _accessToken;
  String? _refreshToken;
  final TokenStorage _tokenStorage;

  /// Set by AuthNotifier so an unrecoverable refresh failure can force a
  /// logout/redirect instead of leaving the UI thinking it's still logged in.
  void Function()? onSessionExpired;

  AuthInterceptor({String? initialToken, TokenStorage? tokenStorage})
      : _accessToken = initialToken,
        _tokenStorage = tokenStorage ?? TokenStorage();

  void setTokens({required String accessToken, required String refreshToken}) {
    _accessToken = accessToken;
    _refreshToken = refreshToken;
  }

  void clearTokens() {
    _accessToken = null;
    _refreshToken = null;
  }

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    if (_accessToken != null && _accessToken!.isNotEmpty) {
      options.headers['Authorization'] = 'Bearer $_accessToken';
    }
    return handler.next(options);
  }

  @override
  Future<void> onError(DioException err, ErrorInterceptorHandler handler) async {
    if (err.response?.statusCode == 401 && _refreshToken != null) {
      try {
        // Attempt automatic refresh token exchange
        final dio = Dio(BaseOptions(baseUrl: err.requestOptions.baseUrl));
        final response = await dio.post('/api/auth/refresh', data: {
          'refreshToken': _refreshToken,
        });

        if (response.statusCode == 200 && response.data != null) {
          final newAccessToken = response.data['accessToken'] as String;
          final newRefreshToken = response.data['refreshToken'] as String;
          _accessToken = newAccessToken;
          _refreshToken = newRefreshToken;
          await _tokenStorage.saveTokens(accessToken: newAccessToken, refreshToken: newRefreshToken);

          // Retry the original request
          final retryOptions = err.requestOptions;
          retryOptions.headers['Authorization'] = 'Bearer $newAccessToken';
          final retriedResponse = await dio.fetch(retryOptions);
          return handler.resolve(retriedResponse);
        }
      } catch (e) {
        clearTokens();
        await _tokenStorage.clear();
        onSessionExpired?.call();
      }
    }
    return handler.next(err);
  }
}
