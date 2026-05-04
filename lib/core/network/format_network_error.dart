import 'dart:io';

import 'package:dio/dio.dart';

/// Short user-facing text (avoids dumping Dio’s long paragraph on screen).
String formatNetworkError(Object e) {
  if (e is DioException) {
    final type = e.type;
    if (type == DioExceptionType.badResponse) {
      final c = e.response?.statusCode;
      final msg = e.message;
      if (msg == 'SESSION_EXPIRED_REDIRECT' ||
          (c != null && c >= 300 && c < 400)) {
        return 'Sesión caducada o cerrada en el servidor. Vuelve a iniciar sesión.';
      }
      if (c == 502) {
        return 'Puerta de enlace no disponible (502). El panel o el proxy no responden.';
      }
      if (c == 503) {
        return 'Servicio no disponible (503).';
      }
      if (c == 504) {
        return 'Tiempo de espera agotado (504).';
      }
      if (c != null) {
        return 'Error del servidor (HTTP $c).';
      }
    }
    if (type == DioExceptionType.connectionTimeout ||
        type == DioExceptionType.sendTimeout ||
        type == DioExceptionType.receiveTimeout ||
        type == DioExceptionType.connectionError) {
      return 'Sin conexión con el servidor.';
    }
    if (type == DioExceptionType.unknown && e.error is SocketException) {
      return 'Sin conexión con el servidor.';
    }
    final msg = e.message;
    if (msg != null && msg.length < 120) {
      return msg;
    }
    return 'Error de red. Inténtalo de nuevo.';
  }
  final s = e.toString();
  if (s.length > 200) {
    return 'Error inesperado.';
  }
  return s;
}
