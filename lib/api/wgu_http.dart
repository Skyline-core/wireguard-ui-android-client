import 'package:cookie_jar/cookie_jar.dart';
import 'package:dio/dio.dart';
import 'package:dio_cookie_manager/dio_cookie_manager.dart';

import 'wgu_dio_configure_io.dart';
import 'wgu_peer_mutation_push_header.dart';

/// Dio client with persistent cookies for wireguard-ui session handling.
class WireguardHttpClient {
  WireguardHttpClient(this.apiPrefixOrigin) : dio = Dio();

  final String apiPrefixOrigin;
  final Dio dio;

  bool _cookiesReady = false;

  Future<void> initCookies(CookieJar jar) async {
    if (_cookiesReady) return;
    configureCrossOriginCookies(dio);
    dio.interceptors.add(CookieManager(jar));
    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          final t = WguPeerMutationPushHeader.registeredFcmToken;
          if (t != null &&
              t.isNotEmpty &&
              wguRequestsPeerMutationFcmSkip(options.method, options.uri)) {
            options.headers[WguPeerMutationPushHeader.headerName] = t;
          }
          handler.next(options);
        },
      ),
    );
    dio.options.headers['Accept'] = 'application/json';
    dio.options.connectTimeout = const Duration(seconds: 20);
    dio.options.receiveTimeout = const Duration(seconds: 40);
    _cookiesReady = true;
  }

  void dispose() {
    dio.close(force: true);
  }
}
