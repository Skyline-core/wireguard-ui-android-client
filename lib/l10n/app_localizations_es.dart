// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Spanish Castilian (`es`).
class AppLocalizationsEs extends AppLocalizations {
  AppLocalizationsEs([String locale = 'es']) : super(locale);

  @override
  String get appLockedTitle => 'Aplicación bloqueada';

  @override
  String get appUnlockPrompt =>
      'Por favor, autentícate para acceder a WireGuard UI';

  @override
  String get appUnlockButton => 'Desbloquear';

  @override
  String get settingsTitle => 'Ajustes';

  @override
  String get settingsSectionApp => 'Aplicación';

  @override
  String get settingsLanguageTitle => 'Idioma';

  @override
  String get settingsLanguageSystem => 'Automático';

  @override
  String get settingsLanguageEn => 'Inglés';

  @override
  String get settingsLanguageEs => 'Español';

  @override
  String get settingsAppLockTitle => 'Bloqueo Biométrico';

  @override
  String get settingsAppLockSubtitle =>
      'Requiere huella, PIN o Face ID al abrir la aplicación';

  @override
  String get settingsAppLockNotSupported =>
      'Este dispositivo no soporta o no tiene configurado un bloqueo seguro.';

  @override
  String get settingsAppLockAuthReason =>
      'Autentícate para habilitar el bloqueo de la app';

  @override
  String settingsAppLockError(String error) {
    return 'Error al configurar biometría: $error';
  }

  @override
  String get settingsChartPerPeerTitle => 'Mostrar gráfica por peer';

  @override
  String get settingsChartPerPeerSubtitle =>
      'En Tráfico, barras apiladas por cliente (como el panel web). Desactivado: gráfica agregada por tiempo.';

  @override
  String get authSessionNotEstablished => 'Sesión no establecida';

  @override
  String get authOfflineWarning =>
      'Sin conexión, mostrando última información conocida.';

  @override
  String get authSessionExpired =>
      'Tu sesión de WireGuard UI expiró. Por favor, inicia sesión de nuevo.';

  @override
  String get tabHome => 'Inicio';

  @override
  String get tabPeers => 'Peers';

  @override
  String get tabTraffic => 'Tráfico';

  @override
  String get tabSettings => 'Ajustes';

  @override
  String shellOfflineWarning(int days) {
    return 'Sin conexión con el servidor. Datos en caché; solo «Cerrar sesión» disponible. Caduca la sesión tras $days días sin actividad.';
  }

  @override
  String get shellUnappliedChanges =>
      'Hay cambios sin aplicar al túnel (como en la web). Pulsa Aplicar para actualizar wg.conf en el servidor.';

  @override
  String get shellApplySuccess => 'Configuración aplicada en el servidor.';

  @override
  String get shellApplyFallbackError => 'No se pudo aplicar la configuración.';

  @override
  String get shellApplyBtn => 'Aplicar';

  @override
  String get settingsSectionAppearance => 'Apariencia';

  @override
  String get settingsTheme => 'Tema';

  @override
  String get settingsThemeDesc =>
      'Automático sigue el modo claro u oscuro del teléfono.';

  @override
  String get settingsThemeLight => 'Claro';

  @override
  String get settingsThemeDark => 'Oscuro';

  @override
  String get settingsThemeAuto => 'Automático';

  @override
  String get settingsSectionServer => 'Servidor';

  @override
  String get settingsWgInterface => 'Interfaz WireGuard';

  @override
  String get settingsTunnelState => 'Estado del túnel';

  @override
  String get settingsStateActive => 'Activo';

  @override
  String get settingsStateInactive => 'Inactivo';

  @override
  String get settingsLiveMonitoring =>
      'Monitoreo en vivo (logs y estadísticas)';

  @override
  String get settingsLiveMonitoringDesc =>
      'Misma opción que en la web: habilita /api/system-logs, actualización de tráfico en vivo y la entrada Logs en el panel.';

  @override
  String get settingsSystemLogs => 'Logs del sistema';

  @override
  String get settingsSectionApiClient => 'Cliente API';

  @override
  String get settingsServerOrigin => 'Origen del servidor';

  @override
  String get settingsApiPrefix => 'API (origen + base path)';

  @override
  String get settingsPasskeyOrigin => 'Origen passkey (opcional)';

  @override
  String get settingsNotDefined => 'No definido';

  @override
  String get settingsChangeBasePath => 'Cambiar base path';

  @override
  String get settingsChangeBasePathDesc =>
      'El dominio o IP no se edita aquí; solo la ruta del panel.';

  @override
  String get settingsPushNotifications => 'Notificaciones push';

  @override
  String get settingsPushNotificationsDesc =>
      'Peers y túnel vía FCM (el servidor limita la frecuencia)';

  @override
  String get settingsSectionSession => 'Sesión';

  @override
  String get settingsLogout => 'Cerrar sesión';

  @override
  String get settingsUserPrefix => 'Usuario: ';

  @override
  String get settingsDevelopedBy => 'Desarrollado por Skyline';

  @override
  String get commonCancel => 'Cancelar';

  @override
  String get commonSave => 'Guardar';

  @override
  String get commonDelete => 'Eliminar';

  @override
  String get commonRetry => 'Reintentar';

  @override
  String get commonGenericError => 'Error';

  @override
  String get commonDash => '—';

  @override
  String get commonServerDnsParen => '(servidor)';

  @override
  String get loginAppTitle => 'WireGuard UI';

  @override
  String get loginSubtitle => 'Inicia sesión en tu panel';

  @override
  String get loginSnackUrlRequired => 'Indica la URL del panel.';

  @override
  String get loginPanelUrlLabel => 'URL del panel';

  @override
  String get loginPanelUrlHint =>
      'https://dominio.net/wg o 192.168.1.5:51821/wg';

  @override
  String get loginPanelUrlHelper =>
      'IPv4/host local sin scheme → http por defecto. Para HTTPS pon https:// (subruta, p. ej. /wg, en la misma URL).';

  @override
  String get loginPasskeyHttpsCheckboxTitle =>
      'Otro dominio HTTPS para passkeys';

  @override
  String get loginPasskeyHttpsCheckboxSubtitle =>
      'Si entras por IP/LAN pero la passkey está en otro hostname público.';

  @override
  String get loginPasskeyOriginLabel => 'Origen passkey (HTTPS)';

  @override
  String get loginPasskeyOriginHint => 'https://vpn.ejemplo.net';

  @override
  String get loginPasskeyOriginHelper =>
      'Misma URL base HTTPS donde registraste la passkey en el navegador.';

  @override
  String get loginUsernameLabel => 'Usuario';

  @override
  String get loginUsernameHelper =>
      'Opcional para passkey si usas llave descubrible (sin usuario)';

  @override
  String get loginPasswordLabel => 'Contraseña';

  @override
  String get loginRememberSession => 'Recordar sesión';

  @override
  String get loginSubmit => 'Entrar';

  @override
  String get loginSubmitPasskey => 'Entrar con passkey';

  @override
  String get settingsSessionFallback => 'Sesión';

  @override
  String get settingsLiveMonitoringActivated => 'Monitoreo en vivo activado.';

  @override
  String get settingsLiveMonitoringDeactivated =>
      'Monitoreo en vivo desactivado.';

  @override
  String get settingsLiveMonitoringSaveFailed =>
      'No se pudo guardar (¿usuario administrador?). Revisa la sesión.';

  @override
  String get settingsHeroInitialsFallback => 'WG';

  @override
  String get settingsFooterTagline => 'Cliente Flutter · WireGuard UI';

  @override
  String get settingsPanelPathDialogTitle => 'Base path del panel';

  @override
  String get settingsPanelPathServerReadonly => 'Servidor (solo lectura)';

  @override
  String get settingsPanelPathFieldLabel => 'Base path';

  @override
  String get settingsPanelPathFieldHint => 'ej. /wg';

  @override
  String get settingsPanelPathHelper =>
      'Se validará contra la API antes de guardar.';

  @override
  String get settingsPanelPathProbeFailed =>
      'Este path no responde a la API con tu sesión.';

  @override
  String get settingsPanelPathRevertFailed =>
      'No se pudo restablecer la sesión con el nuevo path. Se revirtió el path.';

  @override
  String get settingsPanelPathUpdated =>
      'Base path actualizado; datos recargados.';

  @override
  String get homeSubtitle => 'Panel de control';

  @override
  String get homeOfflineNoCache =>
      'Sin datos en caché. Conecta al menos una vez con el servidor.';

  @override
  String get homeActiveInterface => 'INTERFAZ ACTIVA';

  @override
  String get homeTunnelConnected => 'Conectado';

  @override
  String get homeTunnelInactive => 'Inactivo';

  @override
  String homeTunnelStatsLine(
      String sessionsLabel,
      int online,
      String downloadLabel,
      String downloadBytes,
      String uploadLabel,
      String uploadBytes) {
    return '$sessionsLabel · $online · $downloadLabel: $downloadBytes · $uploadLabel: $uploadBytes';
  }

  @override
  String get homeSessionsOnlineLabel => 'Sesiones en línea';

  @override
  String get homeTrafficDownloadLabel => 'Descarga';

  @override
  String get homeTrafficUploadLabel => 'Subida';

  @override
  String get homeMiniPeersEnabled => 'habilitados';

  @override
  String get homeNewClient => 'Nuevo cliente';

  @override
  String get homePeersHeading => 'PEERS';

  @override
  String get homeSeeAllPeers => 'Ver todos';

  @override
  String get homeZipNoPeers => 'No hay peers para descargar.';

  @override
  String get homeZipReady => 'ZIP listo para guardar o compartir.';

  @override
  String get homeShareZipSubject => 'Configuraciones WireGuard';

  @override
  String get peerSaveStateFailed =>
      'No se pudo guardar el estado del peer en el servidor.';

  @override
  String get peerStatusOff => 'Apagado';

  @override
  String get peerStatusOnline => '● En línea';

  @override
  String get peerStatusDisconnected => 'Desconectado';

  @override
  String get peerTraffic24hBadge => '24 h';

  @override
  String get peersOfflineNoCache => 'Sin datos en caché.';

  @override
  String get peersPageTitle => 'Peers';

  @override
  String get peersSubtitle => 'Clientes registrados';

  @override
  String get peersSearchHint => 'Buscar peer, IP…';

  @override
  String peersChipAll(int count) {
    return 'Todos · $count';
  }

  @override
  String peersChipWithTraffic(int count) {
    return 'Con tráfico · $count';
  }

  @override
  String peersChipNoTraffic(int count) {
    return 'Sin tráfico · $count';
  }

  @override
  String peersChipEnabled(int count) {
    return 'Habilitados · $count';
  }

  @override
  String peersChipDisabled(int count) {
    return 'Deshabilitados · $count';
  }

  @override
  String get peerDetailFallbackTitle => 'Peer';

  @override
  String get peerDetailDeleteFailed =>
      'No se pudo borrar el peer en el servidor.';

  @override
  String get peerToggleSaveFailed =>
      'No se pudo guardar el estado en el servidor.';

  @override
  String get peerQrHint => 'Escanea desde la app WireGuard en tu dispositivo';

  @override
  String get peerSectionConfiguration => 'CONFIGURACIÓN';

  @override
  String get peerRowAllowedIps => 'IPs permitidas';

  @override
  String get peerRowDns => 'DNS';

  @override
  String get peerRowEndpoint => 'Endpoint';

  @override
  String get peerDeleteTileTitle => 'Eliminar cliente';

  @override
  String get peerDeleteTileSubtitle =>
      'Revoca acceso (endpoint /remove-client)';

  @override
  String get peerDeleteConfirmTitle => '¿Eliminar?';

  @override
  String get peerDeleteConfirmBody => 'Esta acción no se puede deshacer.';

  @override
  String get newPeerTitle => 'Nuevo peer';

  @override
  String get newPeerNameLabel => 'Nombre del cliente';

  @override
  String get newPeerIpOptionalLabel => 'IP asignada (opcional)';

  @override
  String get newPeerIpHint => '10.0.0.x · vacío = primera sugerida';

  @override
  String get newPeerSuggestIp => 'Sugerir IP (/api/suggest-client-ips)';

  @override
  String get newPeerNameRequired => 'Nombre requerido';

  @override
  String get newPeerSuggestIpFailed => 'No se pudo obtener IP sugerida';

  @override
  String get newPeerSubmit => 'Crear en wireguard-ui';

  @override
  String get newPeerApplyHint =>
      'Tras crear, pulsa Aplicar (banner o web) si el servidor no aplica wg.conf automáticamente.';

  @override
  String get trafficTitle => 'Tráfico';

  @override
  String trafficUpdatedAge(int seconds) {
    return 'Actualizado · antigüedad ${seconds}s';
  }

  @override
  String get trafficRealtimeHeader => 'VELOCIDAD EN TIEMPO REAL';

  @override
  String get trafficDlShort => 'descarga';

  @override
  String get trafficUlShort => 'subida';

  @override
  String get trafficTab24h => '24h';

  @override
  String get trafficTab7d => '7 días';

  @override
  String get trafficTab30d => '30 días';

  @override
  String get trafficRangeSubtitle24h => 'últimas 24h (estimado en vivo)';

  @override
  String get trafficRangeSubtitle7d => 'últimos 7 días (estimado en vivo)';

  @override
  String get trafficRangeSubtitle30d => 'últimos 30 días (estimado en vivo)';

  @override
  String get trafficBandwidthAggregate => 'Ancho de banda · agregado';

  @override
  String get trafficAxisStart => 'inicio';

  @override
  String get trafficAxisNow => 'ahora';

  @override
  String get trafficEmptyPeerBars => 'Sin datos por peer para este rango.';

  @override
  String get trafficBandwidthPeers => 'Ancho de banda';

  @override
  String get trafficLegendDownloadTop => 'Descarga (arriba)';

  @override
  String get trafficLegendUploadBottom => 'Subida (abajo)';

  @override
  String get trafficPeerPerspectiveNote =>
      'Perspectiva peer: descarga = TX del servidor, subida = RX del servidor.';

  @override
  String get trafficMetricDownload => 'Descarga';

  @override
  String get trafficMetricUpload => 'Subida';

  @override
  String get trafficMetricPeak => 'Pico';

  @override
  String get trafficMetricPeers => 'Peers';

  @override
  String get trafficRankingWindow => 'POR PEER (ventana)';

  @override
  String get trafficRankingKernel => 'POR PEER (kernel)';

  @override
  String get logsTitle => 'Logs';

  @override
  String get logsMonitoringDisabled =>
      'El monitoreo en vivo está desactivado en el servidor (igual que en la web). Actívalo en Ajustes → «Monitoreo en vivo (logs y estadísticas)».';

  @override
  String get logsSearchHint => 'Buscar en logs…';

  @override
  String get logsFilterAll => 'Todos';

  @override
  String get logsLoadFailed =>
      'No se pudieron cargar los logs (403 o sesión). Activa el monitoreo en Ajustes o revisa permisos.';

  @override
  String get logsEmptyWithFilters =>
      'No hay líneas que mostrar con los filtros actuales.';

  @override
  String get profileTitle => 'Mi cuenta';

  @override
  String get profileSessionLoadError =>
      'No se pudo obtener el usuario de la sesión. Vuelve a iniciar sesión.';

  @override
  String get profilePasswordStrengthNone => 'Fortaleza: sin contraseña nueva';

  @override
  String get profilePasswordStrengthShort => 'Fortaleza: corta';

  @override
  String get profilePasswordStrengthImprove => 'Fortaleza: mejorable';

  @override
  String get profilePasswordStrengthMedium => 'Fortaleza: media';

  @override
  String get profilePasswordStrengthGood => 'Fortaleza: buena';

  @override
  String get profileSaveFailed => 'No se pudo guardar';

  @override
  String get profileRelogin => 'Vuelve a iniciar sesión.';

  @override
  String get profileSavedOk => 'Cambios guardados.';

  @override
  String get profileSectionAccount => 'Datos de tu cuenta';

  @override
  String get profileSectionPasskeys => 'Passkeys';

  @override
  String get profileAccountHint =>
      'Solo modifica tu propio usuario. Si cambias contraseña, se cerrará la sesión.';

  @override
  String get profileFieldDisplayName => 'NOMBRE PARA MOSTRAR';

  @override
  String get profileFieldUsername => 'NOMBRE DE USUARIO';

  @override
  String get profileFieldEmail => 'CORREO ELECTRÓNICO';

  @override
  String get profileFieldNewPassword => 'NUEVA CONTRASEÑA';

  @override
  String get profileNewPasswordHint => 'Vacío para mantener la actual';

  @override
  String get profilePasswordShow => 'Mostrar';

  @override
  String get profilePasswordHide => 'Ocultar';

  @override
  String get profileSaveChanges => 'Guardar cambios';

  @override
  String get profilePasskeysHintOn =>
      'Registra passkeys en este dispositivo o renombra / quita las ya guardadas.';

  @override
  String get profilePasskeysHintOff =>
      'Las passkeys están desactivadas en la configuración del servidor. Actívalas en el panel web (ajustes globales) para poder registrar llaves.';

  @override
  String get profileNoPasskeys => 'No hay passkeys en esta cuenta.';

  @override
  String get profilePasskeyRenameTooltip => 'Renombrar';

  @override
  String get profilePasskeyDeleteTooltip => 'Eliminar';

  @override
  String get profileAddPasskeyNameLabel => 'NOMBRE (EJ: IPHONE, YUBIKEY)';

  @override
  String get profileAddPasskeyNameHint =>
      'Nombre (ej: iPhone, MacBook, YubiKey)';

  @override
  String get profileAddPasskey => 'Agregar passkey';

  @override
  String get profileRemovePasskeyTitle => 'Quitar passkey';

  @override
  String profileRemovePasskeyBody(String name) {
    return '¿Eliminar \"$name\"? Las sesiones de esta cuenta se invalidan.';
  }

  @override
  String get profileRenamePasskeyTitle => 'Renombrar passkey';

  @override
  String get profileRenamePasskeyFieldLabel => 'Nombre';

  @override
  String get profileRenamePasskeyFieldHint => 'ej. iPhone, YubiKey';

  @override
  String get profilePasskeyRemoved => 'Passkey eliminada.';

  @override
  String get profileNameUpdated => 'Nombre actualizado.';

  @override
  String get profileEnterPasskeyName => 'Escribe un nombre para esta passkey.';

  @override
  String get profilePasskeyRegisterFailed => 'No se pudo registrar la passkey';

  @override
  String get profilePasskeyRegisteredOk =>
      'Passkey registrada en este dispositivo.';

  @override
  String get profilePasskeyDuplicate =>
      'Esta llave ya está registrada para tu cuenta.';

  @override
  String profilePasskeyDomainHint(String detail) {
    return 'No se pudo validar el dominio para passkeys ($detail). Revisa «Origen passkey» en Ajustes si entras por IP o otro host.';
  }

  @override
  String get profilePasskeyDeviceUnsupported =>
      'Este dispositivo no permite crear passkeys.';
}
