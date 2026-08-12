import 'package:dio/dio.dart';
import '../config/app_config.dart';
import 'auth_interceptor.dart';

class DioClient {
  late final Dio dio;
  final AuthInterceptor authInterceptor = AuthInterceptor();

  DioClient() {
    dio = Dio(
      BaseOptions(
        baseUrl: AppConfig.baseUrl,
        connectTimeout: const Duration(seconds: 15),
        receiveTimeout: const Duration(seconds: 15),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ),
    );

    dio.interceptors.add(authInterceptor);
    dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) {
        print('\n====================== API REQUEST ======================');
        print('METHOD: ${options.method}');
        print('URL:    ${options.uri}');
        print('HEADERS: ${options.headers}');
        if (options.data != null) {
          print('PAYLOAD: ${options.data}');
        }
        print('=========================================================');
        return handler.next(options);
      },
      onResponse: (response, handler) {
        print('\n====================== API RESPONSE =====================');
        print('METHOD: ${response.requestOptions.method}');
        print('URL:    ${response.requestOptions.uri}');
        print('STATUS: ${response.statusCode}');
        print('BODY:   ${response.data}');
        print('=========================================================');
        return handler.next(response);
      },
      onError: (DioException err, handler) {
        print('\n====================== API ERROR ========================');
        print('METHOD: ${err.requestOptions.method}');
        print('URL:    ${err.requestOptions.uri}');
        print('STATUS: ${err.response?.statusCode}');
        print('ERROR:  ${err.message}');
        print('BODY:   ${err.response?.data}');
        print('=========================================================');
        return handler.next(err);
      },
    ));
  }
}
