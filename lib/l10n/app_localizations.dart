import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_es.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
      : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
    delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
  ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('es')
  ];

  /// No description provided for @appLockedTitle.
  ///
  /// In es, this message translates to:
  /// **'Aplicación bloqueada'**
  String get appLockedTitle;

  /// No description provided for @appUnlockPrompt.
  ///
  /// In es, this message translates to:
  /// **'Por favor, autentícate para acceder a WireGuard UI'**
  String get appUnlockPrompt;

  /// No description provided for @appUnlockButton.
  ///
  /// In es, this message translates to:
  /// **'Desbloquear'**
  String get appUnlockButton;

  /// No description provided for @settingsTitle.
  ///
  /// In es, this message translates to:
  /// **'Ajustes'**
  String get settingsTitle;

  /// No description provided for @settingsSectionApp.
  ///
  /// In es, this message translates to:
  /// **'Aplicación'**
  String get settingsSectionApp;

  /// No description provided for @settingsLanguageTitle.
  ///
  /// In es, this message translates to:
  /// **'Idioma'**
  String get settingsLanguageTitle;

  /// No description provided for @settingsLanguageSystem.
  ///
  /// In es, this message translates to:
  /// **'Automático'**
  String get settingsLanguageSystem;

  /// No description provided for @settingsLanguageEn.
  ///
  /// In es, this message translates to:
  /// **'Inglés'**
  String get settingsLanguageEn;

  /// No description provided for @settingsLanguageEs.
  ///
  /// In es, this message translates to:
  /// **'Español'**
  String get settingsLanguageEs;

  /// No description provided for @settingsAppLockTitle.
  ///
  /// In es, this message translates to:
  /// **'Bloqueo Biométrico'**
  String get settingsAppLockTitle;

  /// No description provided for @settingsAppLockSubtitle.
  ///
  /// In es, this message translates to:
  /// **'Requiere huella, PIN o Face ID al abrir la aplicación'**
  String get settingsAppLockSubtitle;

  /// No description provided for @settingsAppLockNotSupported.
  ///
  /// In es, this message translates to:
  /// **'Este dispositivo no soporta o no tiene configurado un bloqueo seguro.'**
  String get settingsAppLockNotSupported;

  /// No description provided for @settingsAppLockAuthReason.
  ///
  /// In es, this message translates to:
  /// **'Autentícate para habilitar el bloqueo de la app'**
  String get settingsAppLockAuthReason;

  /// No description provided for @settingsAppLockError.
  ///
  /// In es, this message translates to:
  /// **'Error al configurar biometría: {error}'**
  String settingsAppLockError(String error);

  /// No description provided for @settingsChartPerPeerTitle.
  ///
  /// In es, this message translates to:
  /// **'Mostrar gráfica por peer'**
  String get settingsChartPerPeerTitle;

  /// No description provided for @settingsChartPerPeerSubtitle.
  ///
  /// In es, this message translates to:
  /// **'En Tráfico, barras apiladas por cliente (como el panel web). Desactivado: gráfica agregada por tiempo.'**
  String get settingsChartPerPeerSubtitle;

  /// No description provided for @authSessionNotEstablished.
  ///
  /// In es, this message translates to:
  /// **'Sesión no establecida'**
  String get authSessionNotEstablished;

  /// No description provided for @authOfflineWarning.
  ///
  /// In es, this message translates to:
  /// **'Sin conexión, mostrando última información conocida.'**
  String get authOfflineWarning;

  /// No description provided for @authSessionExpired.
  ///
  /// In es, this message translates to:
  /// **'Tu sesión de WireGuard UI expiró. Por favor, inicia sesión de nuevo.'**
  String get authSessionExpired;

  /// No description provided for @tabHome.
  ///
  /// In es, this message translates to:
  /// **'Inicio'**
  String get tabHome;

  /// No description provided for @tabPeers.
  ///
  /// In es, this message translates to:
  /// **'Peers'**
  String get tabPeers;

  /// No description provided for @tabTraffic.
  ///
  /// In es, this message translates to:
  /// **'Tráfico'**
  String get tabTraffic;

  /// No description provided for @tabSettings.
  ///
  /// In es, this message translates to:
  /// **'Ajustes'**
  String get tabSettings;

  /// No description provided for @shellOfflineWarning.
  ///
  /// In es, this message translates to:
  /// **'Sin conexión con el servidor. Datos en caché; solo «Cerrar sesión» disponible. Caduca la sesión tras {days} días sin actividad.'**
  String shellOfflineWarning(int days);

  /// No description provided for @shellUnappliedChanges.
  ///
  /// In es, this message translates to:
  /// **'Hay cambios sin aplicar al túnel (como en la web). Pulsa Aplicar para actualizar wg.conf en el servidor.'**
  String get shellUnappliedChanges;

  /// No description provided for @shellApplySuccess.
  ///
  /// In es, this message translates to:
  /// **'Configuración aplicada en el servidor.'**
  String get shellApplySuccess;

  /// No description provided for @shellApplyFallbackError.
  ///
  /// In es, this message translates to:
  /// **'No se pudo aplicar la configuración.'**
  String get shellApplyFallbackError;

  /// No description provided for @shellApplyBtn.
  ///
  /// In es, this message translates to:
  /// **'Aplicar'**
  String get shellApplyBtn;

  /// No description provided for @settingsSectionAppearance.
  ///
  /// In es, this message translates to:
  /// **'Apariencia'**
  String get settingsSectionAppearance;

  /// No description provided for @settingsTheme.
  ///
  /// In es, this message translates to:
  /// **'Tema'**
  String get settingsTheme;

  /// No description provided for @settingsThemeDesc.
  ///
  /// In es, this message translates to:
  /// **'Automático sigue el modo claro u oscuro del teléfono.'**
  String get settingsThemeDesc;

  /// No description provided for @settingsThemeLight.
  ///
  /// In es, this message translates to:
  /// **'Claro'**
  String get settingsThemeLight;

  /// No description provided for @settingsThemeDark.
  ///
  /// In es, this message translates to:
  /// **'Oscuro'**
  String get settingsThemeDark;

  /// No description provided for @settingsThemeAuto.
  ///
  /// In es, this message translates to:
  /// **'Automático'**
  String get settingsThemeAuto;

  /// No description provided for @settingsSectionServer.
  ///
  /// In es, this message translates to:
  /// **'Servidor'**
  String get settingsSectionServer;

  /// No description provided for @settingsWgInterface.
  ///
  /// In es, this message translates to:
  /// **'Interfaz WireGuard'**
  String get settingsWgInterface;

  /// No description provided for @settingsTunnelState.
  ///
  /// In es, this message translates to:
  /// **'Estado del túnel'**
  String get settingsTunnelState;

  /// No description provided for @settingsStateActive.
  ///
  /// In es, this message translates to:
  /// **'Activo'**
  String get settingsStateActive;

  /// No description provided for @settingsStateInactive.
  ///
  /// In es, this message translates to:
  /// **'Inactivo'**
  String get settingsStateInactive;

  /// No description provided for @settingsLiveMonitoring.
  ///
  /// In es, this message translates to:
  /// **'Monitoreo en vivo (logs y estadísticas)'**
  String get settingsLiveMonitoring;

  /// No description provided for @settingsLiveMonitoringDesc.
  ///
  /// In es, this message translates to:
  /// **'Misma opción que en la web: habilita /api/system-logs, actualización de tráfico en vivo y la entrada Logs en el panel.'**
  String get settingsLiveMonitoringDesc;

  /// No description provided for @settingsSystemLogs.
  ///
  /// In es, this message translates to:
  /// **'Logs del sistema'**
  String get settingsSystemLogs;

  /// No description provided for @settingsSectionApiClient.
  ///
  /// In es, this message translates to:
  /// **'Cliente API'**
  String get settingsSectionApiClient;

  /// No description provided for @settingsServerOrigin.
  ///
  /// In es, this message translates to:
  /// **'Origen del servidor'**
  String get settingsServerOrigin;

  /// No description provided for @settingsApiPrefix.
  ///
  /// In es, this message translates to:
  /// **'API (origen + base path)'**
  String get settingsApiPrefix;

  /// No description provided for @settingsPasskeyOrigin.
  ///
  /// In es, this message translates to:
  /// **'Origen passkey (opcional)'**
  String get settingsPasskeyOrigin;

  /// No description provided for @settingsNotDefined.
  ///
  /// In es, this message translates to:
  /// **'No definido'**
  String get settingsNotDefined;

  /// No description provided for @settingsChangeBasePath.
  ///
  /// In es, this message translates to:
  /// **'Cambiar base path'**
  String get settingsChangeBasePath;

  /// No description provided for @settingsChangeBasePathDesc.
  ///
  /// In es, this message translates to:
  /// **'El dominio o IP no se edita aquí; solo la ruta del panel.'**
  String get settingsChangeBasePathDesc;

  /// No description provided for @settingsPushNotifications.
  ///
  /// In es, this message translates to:
  /// **'Notificaciones push'**
  String get settingsPushNotifications;

  /// No description provided for @settingsPushNotificationsDesc.
  ///
  /// In es, this message translates to:
  /// **'Peers y túnel vía FCM (el servidor limita la frecuencia)'**
  String get settingsPushNotificationsDesc;

  /// No description provided for @settingsSectionSession.
  ///
  /// In es, this message translates to:
  /// **'Sesión'**
  String get settingsSectionSession;

  /// No description provided for @settingsLogout.
  ///
  /// In es, this message translates to:
  /// **'Cerrar sesión'**
  String get settingsLogout;

  /// No description provided for @settingsUserPrefix.
  ///
  /// In es, this message translates to:
  /// **'Usuario: '**
  String get settingsUserPrefix;

  /// No description provided for @settingsDevelopedBy.
  ///
  /// In es, this message translates to:
  /// **'Desarrollado por Skyline'**
  String get settingsDevelopedBy;

  /// No description provided for @commonCancel.
  ///
  /// In es, this message translates to:
  /// **'Cancelar'**
  String get commonCancel;

  /// No description provided for @commonSave.
  ///
  /// In es, this message translates to:
  /// **'Guardar'**
  String get commonSave;

  /// No description provided for @commonDelete.
  ///
  /// In es, this message translates to:
  /// **'Eliminar'**
  String get commonDelete;

  /// No description provided for @commonRetry.
  ///
  /// In es, this message translates to:
  /// **'Reintentar'**
  String get commonRetry;

  /// No description provided for @commonGenericError.
  ///
  /// In es, this message translates to:
  /// **'Error'**
  String get commonGenericError;

  /// No description provided for @commonDash.
  ///
  /// In es, this message translates to:
  /// **'—'**
  String get commonDash;

  /// No description provided for @commonServerDnsParen.
  ///
  /// In es, this message translates to:
  /// **'(servidor)'**
  String get commonServerDnsParen;

  /// No description provided for @loginAppTitle.
  ///
  /// In es, this message translates to:
  /// **'WireGuard UI'**
  String get loginAppTitle;

  /// No description provided for @loginSubtitle.
  ///
  /// In es, this message translates to:
  /// **'Inicia sesión en tu panel'**
  String get loginSubtitle;

  /// No description provided for @loginSnackUrlRequired.
  ///
  /// In es, this message translates to:
  /// **'Indica la URL del panel.'**
  String get loginSnackUrlRequired;

  /// No description provided for @loginPanelUrlLabel.
  ///
  /// In es, this message translates to:
  /// **'URL del panel'**
  String get loginPanelUrlLabel;

  /// No description provided for @loginPanelUrlHint.
  ///
  /// In es, this message translates to:
  /// **'https://dominio.net/wg o 192.168.1.5:51821/wg'**
  String get loginPanelUrlHint;

  /// No description provided for @loginPanelUrlHelper.
  ///
  /// In es, this message translates to:
  /// **'IPv4/host local sin scheme → http por defecto. Para HTTPS pon https:// (subruta, p. ej. /wg, en la misma URL).'**
  String get loginPanelUrlHelper;

  /// No description provided for @loginPasskeyHttpsCheckboxTitle.
  ///
  /// In es, this message translates to:
  /// **'Otro dominio HTTPS para passkeys'**
  String get loginPasskeyHttpsCheckboxTitle;

  /// No description provided for @loginPasskeyHttpsCheckboxSubtitle.
  ///
  /// In es, this message translates to:
  /// **'Si entras por IP/LAN pero la passkey está en otro hostname público.'**
  String get loginPasskeyHttpsCheckboxSubtitle;

  /// No description provided for @loginPasskeyOriginLabel.
  ///
  /// In es, this message translates to:
  /// **'Origen passkey (HTTPS)'**
  String get loginPasskeyOriginLabel;

  /// No description provided for @loginPasskeyOriginHint.
  ///
  /// In es, this message translates to:
  /// **'https://vpn.ejemplo.net'**
  String get loginPasskeyOriginHint;

  /// No description provided for @loginPasskeyOriginHelper.
  ///
  /// In es, this message translates to:
  /// **'Misma URL base HTTPS donde registraste la passkey en el navegador.'**
  String get loginPasskeyOriginHelper;

  /// No description provided for @loginUsernameLabel.
  ///
  /// In es, this message translates to:
  /// **'Usuario'**
  String get loginUsernameLabel;

  /// No description provided for @loginUsernameHelper.
  ///
  /// In es, this message translates to:
  /// **'Opcional para passkey si usas llave descubrible (sin usuario)'**
  String get loginUsernameHelper;

  /// No description provided for @loginPasswordLabel.
  ///
  /// In es, this message translates to:
  /// **'Contraseña'**
  String get loginPasswordLabel;

  /// No description provided for @loginRememberSession.
  ///
  /// In es, this message translates to:
  /// **'Recordar sesión'**
  String get loginRememberSession;

  /// No description provided for @loginSubmit.
  ///
  /// In es, this message translates to:
  /// **'Entrar'**
  String get loginSubmit;

  /// No description provided for @loginSubmitPasskey.
  ///
  /// In es, this message translates to:
  /// **'Entrar con passkey'**
  String get loginSubmitPasskey;

  /// No description provided for @settingsSessionFallback.
  ///
  /// In es, this message translates to:
  /// **'Sesión'**
  String get settingsSessionFallback;

  /// No description provided for @settingsLiveMonitoringActivated.
  ///
  /// In es, this message translates to:
  /// **'Monitoreo en vivo activado.'**
  String get settingsLiveMonitoringActivated;

  /// No description provided for @settingsLiveMonitoringDeactivated.
  ///
  /// In es, this message translates to:
  /// **'Monitoreo en vivo desactivado.'**
  String get settingsLiveMonitoringDeactivated;

  /// No description provided for @settingsLiveMonitoringSaveFailed.
  ///
  /// In es, this message translates to:
  /// **'No se pudo guardar (¿usuario administrador?). Revisa la sesión.'**
  String get settingsLiveMonitoringSaveFailed;

  /// No description provided for @settingsHeroInitialsFallback.
  ///
  /// In es, this message translates to:
  /// **'WG'**
  String get settingsHeroInitialsFallback;

  /// No description provided for @settingsFooterTagline.
  ///
  /// In es, this message translates to:
  /// **'Cliente Flutter · WireGuard UI'**
  String get settingsFooterTagline;

  /// No description provided for @settingsPanelPathDialogTitle.
  ///
  /// In es, this message translates to:
  /// **'Base path del panel'**
  String get settingsPanelPathDialogTitle;

  /// No description provided for @settingsPanelPathServerReadonly.
  ///
  /// In es, this message translates to:
  /// **'Servidor (solo lectura)'**
  String get settingsPanelPathServerReadonly;

  /// No description provided for @settingsPanelPathFieldLabel.
  ///
  /// In es, this message translates to:
  /// **'Base path'**
  String get settingsPanelPathFieldLabel;

  /// No description provided for @settingsPanelPathFieldHint.
  ///
  /// In es, this message translates to:
  /// **'ej. /wg'**
  String get settingsPanelPathFieldHint;

  /// No description provided for @settingsPanelPathHelper.
  ///
  /// In es, this message translates to:
  /// **'Se validará contra la API antes de guardar.'**
  String get settingsPanelPathHelper;

  /// No description provided for @settingsPanelPathProbeFailed.
  ///
  /// In es, this message translates to:
  /// **'Este path no responde a la API con tu sesión.'**
  String get settingsPanelPathProbeFailed;

  /// No description provided for @settingsPanelPathRevertFailed.
  ///
  /// In es, this message translates to:
  /// **'No se pudo restablecer la sesión con el nuevo path. Se revirtió el path.'**
  String get settingsPanelPathRevertFailed;

  /// No description provided for @settingsPanelPathUpdated.
  ///
  /// In es, this message translates to:
  /// **'Base path actualizado; datos recargados.'**
  String get settingsPanelPathUpdated;

  /// No description provided for @homeSubtitle.
  ///
  /// In es, this message translates to:
  /// **'Panel de control'**
  String get homeSubtitle;

  /// No description provided for @homeOfflineNoCache.
  ///
  /// In es, this message translates to:
  /// **'Sin datos en caché. Conecta al menos una vez con el servidor.'**
  String get homeOfflineNoCache;

  /// No description provided for @homeActiveInterface.
  ///
  /// In es, this message translates to:
  /// **'INTERFAZ ACTIVA'**
  String get homeActiveInterface;

  /// No description provided for @homeTunnelConnected.
  ///
  /// In es, this message translates to:
  /// **'Conectado'**
  String get homeTunnelConnected;

  /// No description provided for @homeTunnelInactive.
  ///
  /// In es, this message translates to:
  /// **'Inactivo'**
  String get homeTunnelInactive;

  /// No description provided for @homeTunnelStatsLine.
  ///
  /// In es, this message translates to:
  /// **'{sessionsLabel} · {online} · {downloadLabel}: {downloadBytes} · {uploadLabel}: {uploadBytes}'**
  String homeTunnelStatsLine(
      String sessionsLabel,
      int online,
      String downloadLabel,
      String downloadBytes,
      String uploadLabel,
      String uploadBytes);

  /// No description provided for @homeSessionsOnlineLabel.
  ///
  /// In es, this message translates to:
  /// **'Sesiones en línea'**
  String get homeSessionsOnlineLabel;

  /// No description provided for @homeTrafficDownloadLabel.
  ///
  /// In es, this message translates to:
  /// **'Descarga'**
  String get homeTrafficDownloadLabel;

  /// No description provided for @homeTrafficUploadLabel.
  ///
  /// In es, this message translates to:
  /// **'Subida'**
  String get homeTrafficUploadLabel;

  /// No description provided for @homeMiniPeersEnabled.
  ///
  /// In es, this message translates to:
  /// **'habilitados'**
  String get homeMiniPeersEnabled;

  /// No description provided for @homeNewClient.
  ///
  /// In es, this message translates to:
  /// **'Nuevo cliente'**
  String get homeNewClient;

  /// No description provided for @homePeersHeading.
  ///
  /// In es, this message translates to:
  /// **'PEERS'**
  String get homePeersHeading;

  /// No description provided for @homeSeeAllPeers.
  ///
  /// In es, this message translates to:
  /// **'Ver todos'**
  String get homeSeeAllPeers;

  /// No description provided for @homeZipNoPeers.
  ///
  /// In es, this message translates to:
  /// **'No hay peers para descargar.'**
  String get homeZipNoPeers;

  /// No description provided for @homeZipReady.
  ///
  /// In es, this message translates to:
  /// **'ZIP listo para guardar o compartir.'**
  String get homeZipReady;

  /// No description provided for @homeShareZipSubject.
  ///
  /// In es, this message translates to:
  /// **'Configuraciones WireGuard'**
  String get homeShareZipSubject;

  /// No description provided for @peerSaveStateFailed.
  ///
  /// In es, this message translates to:
  /// **'No se pudo guardar el estado del peer en el servidor.'**
  String get peerSaveStateFailed;

  /// No description provided for @peerStatusOff.
  ///
  /// In es, this message translates to:
  /// **'Apagado'**
  String get peerStatusOff;

  /// No description provided for @peerStatusOnline.
  ///
  /// In es, this message translates to:
  /// **'● En línea'**
  String get peerStatusOnline;

  /// No description provided for @peerStatusDisconnected.
  ///
  /// In es, this message translates to:
  /// **'Desconectado'**
  String get peerStatusDisconnected;

  /// No description provided for @peerTraffic24hBadge.
  ///
  /// In es, this message translates to:
  /// **'24 h'**
  String get peerTraffic24hBadge;

  /// No description provided for @peersOfflineNoCache.
  ///
  /// In es, this message translates to:
  /// **'Sin datos en caché.'**
  String get peersOfflineNoCache;

  /// No description provided for @peersPageTitle.
  ///
  /// In es, this message translates to:
  /// **'Peers'**
  String get peersPageTitle;

  /// No description provided for @peersSubtitle.
  ///
  /// In es, this message translates to:
  /// **'Clientes registrados'**
  String get peersSubtitle;

  /// No description provided for @peersSearchHint.
  ///
  /// In es, this message translates to:
  /// **'Buscar peer, IP…'**
  String get peersSearchHint;

  /// No description provided for @peersChipAll.
  ///
  /// In es, this message translates to:
  /// **'Todos · {count}'**
  String peersChipAll(int count);

  /// No description provided for @peersChipWithTraffic.
  ///
  /// In es, this message translates to:
  /// **'Con tráfico · {count}'**
  String peersChipWithTraffic(int count);

  /// No description provided for @peersChipNoTraffic.
  ///
  /// In es, this message translates to:
  /// **'Sin tráfico · {count}'**
  String peersChipNoTraffic(int count);

  /// No description provided for @peersChipEnabled.
  ///
  /// In es, this message translates to:
  /// **'Habilitados · {count}'**
  String peersChipEnabled(int count);

  /// No description provided for @peersChipDisabled.
  ///
  /// In es, this message translates to:
  /// **'Deshabilitados · {count}'**
  String peersChipDisabled(int count);

  /// No description provided for @peerDetailFallbackTitle.
  ///
  /// In es, this message translates to:
  /// **'Peer'**
  String get peerDetailFallbackTitle;

  /// No description provided for @peerDetailDeleteFailed.
  ///
  /// In es, this message translates to:
  /// **'No se pudo borrar el peer en el servidor.'**
  String get peerDetailDeleteFailed;

  /// No description provided for @peerToggleSaveFailed.
  ///
  /// In es, this message translates to:
  /// **'No se pudo guardar el estado en el servidor.'**
  String get peerToggleSaveFailed;

  /// No description provided for @peerQrHint.
  ///
  /// In es, this message translates to:
  /// **'Escanea desde la app WireGuard en tu dispositivo'**
  String get peerQrHint;

  /// No description provided for @peerSectionConfiguration.
  ///
  /// In es, this message translates to:
  /// **'CONFIGURACIÓN'**
  String get peerSectionConfiguration;

  /// No description provided for @peerRowAllowedIps.
  ///
  /// In es, this message translates to:
  /// **'IPs permitidas'**
  String get peerRowAllowedIps;

  /// No description provided for @peerRowDns.
  ///
  /// In es, this message translates to:
  /// **'DNS'**
  String get peerRowDns;

  /// No description provided for @peerRowEndpoint.
  ///
  /// In es, this message translates to:
  /// **'Endpoint'**
  String get peerRowEndpoint;

  /// No description provided for @peerDeleteTileTitle.
  ///
  /// In es, this message translates to:
  /// **'Eliminar cliente'**
  String get peerDeleteTileTitle;

  /// No description provided for @peerDeleteTileSubtitle.
  ///
  /// In es, this message translates to:
  /// **'Revoca acceso (endpoint /remove-client)'**
  String get peerDeleteTileSubtitle;

  /// No description provided for @peerDeleteConfirmTitle.
  ///
  /// In es, this message translates to:
  /// **'¿Eliminar?'**
  String get peerDeleteConfirmTitle;

  /// No description provided for @peerDeleteConfirmBody.
  ///
  /// In es, this message translates to:
  /// **'Esta acción no se puede deshacer.'**
  String get peerDeleteConfirmBody;

  /// No description provided for @newPeerTitle.
  ///
  /// In es, this message translates to:
  /// **'Nuevo peer'**
  String get newPeerTitle;

  /// No description provided for @newPeerNameLabel.
  ///
  /// In es, this message translates to:
  /// **'Nombre del cliente'**
  String get newPeerNameLabel;

  /// No description provided for @newPeerIpOptionalLabel.
  ///
  /// In es, this message translates to:
  /// **'IP asignada (opcional)'**
  String get newPeerIpOptionalLabel;

  /// No description provided for @newPeerIpHint.
  ///
  /// In es, this message translates to:
  /// **'10.0.0.x · vacío = primera sugerida'**
  String get newPeerIpHint;

  /// No description provided for @newPeerSuggestIp.
  ///
  /// In es, this message translates to:
  /// **'Sugerir IP (/api/suggest-client-ips)'**
  String get newPeerSuggestIp;

  /// No description provided for @newPeerNameRequired.
  ///
  /// In es, this message translates to:
  /// **'Nombre requerido'**
  String get newPeerNameRequired;

  /// No description provided for @newPeerSuggestIpFailed.
  ///
  /// In es, this message translates to:
  /// **'No se pudo obtener IP sugerida'**
  String get newPeerSuggestIpFailed;

  /// No description provided for @newPeerSubmit.
  ///
  /// In es, this message translates to:
  /// **'Crear en wireguard-ui'**
  String get newPeerSubmit;

  /// No description provided for @newPeerApplyHint.
  ///
  /// In es, this message translates to:
  /// **'Tras crear, pulsa Aplicar (banner o web) si el servidor no aplica wg.conf automáticamente.'**
  String get newPeerApplyHint;

  /// No description provided for @trafficTitle.
  ///
  /// In es, this message translates to:
  /// **'Tráfico'**
  String get trafficTitle;

  /// No description provided for @trafficUpdatedAge.
  ///
  /// In es, this message translates to:
  /// **'Actualizado · antigüedad {seconds}s'**
  String trafficUpdatedAge(int seconds);

  /// No description provided for @trafficRealtimeHeader.
  ///
  /// In es, this message translates to:
  /// **'VELOCIDAD EN TIEMPO REAL'**
  String get trafficRealtimeHeader;

  /// No description provided for @trafficDlShort.
  ///
  /// In es, this message translates to:
  /// **'descarga'**
  String get trafficDlShort;

  /// No description provided for @trafficUlShort.
  ///
  /// In es, this message translates to:
  /// **'subida'**
  String get trafficUlShort;

  /// No description provided for @trafficTab24h.
  ///
  /// In es, this message translates to:
  /// **'24h'**
  String get trafficTab24h;

  /// No description provided for @trafficTab7d.
  ///
  /// In es, this message translates to:
  /// **'7 días'**
  String get trafficTab7d;

  /// No description provided for @trafficTab30d.
  ///
  /// In es, this message translates to:
  /// **'30 días'**
  String get trafficTab30d;

  /// No description provided for @trafficRangeSubtitle24h.
  ///
  /// In es, this message translates to:
  /// **'últimas 24h (estimado en vivo)'**
  String get trafficRangeSubtitle24h;

  /// No description provided for @trafficRangeSubtitle7d.
  ///
  /// In es, this message translates to:
  /// **'últimos 7 días (estimado en vivo)'**
  String get trafficRangeSubtitle7d;

  /// No description provided for @trafficRangeSubtitle30d.
  ///
  /// In es, this message translates to:
  /// **'últimos 30 días (estimado en vivo)'**
  String get trafficRangeSubtitle30d;

  /// No description provided for @trafficBandwidthAggregate.
  ///
  /// In es, this message translates to:
  /// **'Ancho de banda · agregado'**
  String get trafficBandwidthAggregate;

  /// No description provided for @trafficAxisStart.
  ///
  /// In es, this message translates to:
  /// **'inicio'**
  String get trafficAxisStart;

  /// No description provided for @trafficAxisNow.
  ///
  /// In es, this message translates to:
  /// **'ahora'**
  String get trafficAxisNow;

  /// No description provided for @trafficEmptyPeerBars.
  ///
  /// In es, this message translates to:
  /// **'Sin datos por peer para este rango.'**
  String get trafficEmptyPeerBars;

  /// No description provided for @trafficBandwidthPeers.
  ///
  /// In es, this message translates to:
  /// **'Ancho de banda'**
  String get trafficBandwidthPeers;

  /// No description provided for @trafficLegendDownloadTop.
  ///
  /// In es, this message translates to:
  /// **'Descarga (arriba)'**
  String get trafficLegendDownloadTop;

  /// No description provided for @trafficLegendUploadBottom.
  ///
  /// In es, this message translates to:
  /// **'Subida (abajo)'**
  String get trafficLegendUploadBottom;

  /// No description provided for @trafficPeerPerspectiveNote.
  ///
  /// In es, this message translates to:
  /// **'Perspectiva peer: descarga = TX del servidor, subida = RX del servidor.'**
  String get trafficPeerPerspectiveNote;

  /// No description provided for @trafficMetricDownload.
  ///
  /// In es, this message translates to:
  /// **'Descarga'**
  String get trafficMetricDownload;

  /// No description provided for @trafficMetricUpload.
  ///
  /// In es, this message translates to:
  /// **'Subida'**
  String get trafficMetricUpload;

  /// No description provided for @trafficMetricPeak.
  ///
  /// In es, this message translates to:
  /// **'Pico'**
  String get trafficMetricPeak;

  /// No description provided for @trafficMetricPeers.
  ///
  /// In es, this message translates to:
  /// **'Peers'**
  String get trafficMetricPeers;

  /// No description provided for @trafficRankingWindow.
  ///
  /// In es, this message translates to:
  /// **'POR PEER (ventana)'**
  String get trafficRankingWindow;

  /// No description provided for @trafficRankingKernel.
  ///
  /// In es, this message translates to:
  /// **'POR PEER (kernel)'**
  String get trafficRankingKernel;

  /// No description provided for @logsTitle.
  ///
  /// In es, this message translates to:
  /// **'Logs'**
  String get logsTitle;

  /// No description provided for @logsMonitoringDisabled.
  ///
  /// In es, this message translates to:
  /// **'El monitoreo en vivo está desactivado en el servidor (igual que en la web). Actívalo en Ajustes → «Monitoreo en vivo (logs y estadísticas)».'**
  String get logsMonitoringDisabled;

  /// No description provided for @logsSearchHint.
  ///
  /// In es, this message translates to:
  /// **'Buscar en logs…'**
  String get logsSearchHint;

  /// No description provided for @logsFilterAll.
  ///
  /// In es, this message translates to:
  /// **'Todos'**
  String get logsFilterAll;

  /// No description provided for @logsLoadFailed.
  ///
  /// In es, this message translates to:
  /// **'No se pudieron cargar los logs (403 o sesión). Activa el monitoreo en Ajustes o revisa permisos.'**
  String get logsLoadFailed;

  /// No description provided for @logsEmptyWithFilters.
  ///
  /// In es, this message translates to:
  /// **'No hay líneas que mostrar con los filtros actuales.'**
  String get logsEmptyWithFilters;

  /// No description provided for @profileTitle.
  ///
  /// In es, this message translates to:
  /// **'Mi cuenta'**
  String get profileTitle;

  /// No description provided for @profileSessionLoadError.
  ///
  /// In es, this message translates to:
  /// **'No se pudo obtener el usuario de la sesión. Vuelve a iniciar sesión.'**
  String get profileSessionLoadError;

  /// No description provided for @profilePasswordStrengthNone.
  ///
  /// In es, this message translates to:
  /// **'Fortaleza: sin contraseña nueva'**
  String get profilePasswordStrengthNone;

  /// No description provided for @profilePasswordStrengthShort.
  ///
  /// In es, this message translates to:
  /// **'Fortaleza: corta'**
  String get profilePasswordStrengthShort;

  /// No description provided for @profilePasswordStrengthImprove.
  ///
  /// In es, this message translates to:
  /// **'Fortaleza: mejorable'**
  String get profilePasswordStrengthImprove;

  /// No description provided for @profilePasswordStrengthMedium.
  ///
  /// In es, this message translates to:
  /// **'Fortaleza: media'**
  String get profilePasswordStrengthMedium;

  /// No description provided for @profilePasswordStrengthGood.
  ///
  /// In es, this message translates to:
  /// **'Fortaleza: buena'**
  String get profilePasswordStrengthGood;

  /// No description provided for @profileSaveFailed.
  ///
  /// In es, this message translates to:
  /// **'No se pudo guardar'**
  String get profileSaveFailed;

  /// No description provided for @profileRelogin.
  ///
  /// In es, this message translates to:
  /// **'Vuelve a iniciar sesión.'**
  String get profileRelogin;

  /// No description provided for @profileSavedOk.
  ///
  /// In es, this message translates to:
  /// **'Cambios guardados.'**
  String get profileSavedOk;

  /// No description provided for @profileSectionAccount.
  ///
  /// In es, this message translates to:
  /// **'Datos de tu cuenta'**
  String get profileSectionAccount;

  /// No description provided for @profileSectionPasskeys.
  ///
  /// In es, this message translates to:
  /// **'Passkeys'**
  String get profileSectionPasskeys;

  /// No description provided for @profileAccountHint.
  ///
  /// In es, this message translates to:
  /// **'Solo modifica tu propio usuario. Si cambias contraseña, se cerrará la sesión.'**
  String get profileAccountHint;

  /// No description provided for @profileFieldDisplayName.
  ///
  /// In es, this message translates to:
  /// **'NOMBRE PARA MOSTRAR'**
  String get profileFieldDisplayName;

  /// No description provided for @profileFieldUsername.
  ///
  /// In es, this message translates to:
  /// **'NOMBRE DE USUARIO'**
  String get profileFieldUsername;

  /// No description provided for @profileFieldEmail.
  ///
  /// In es, this message translates to:
  /// **'CORREO ELECTRÓNICO'**
  String get profileFieldEmail;

  /// No description provided for @profileFieldNewPassword.
  ///
  /// In es, this message translates to:
  /// **'NUEVA CONTRASEÑA'**
  String get profileFieldNewPassword;

  /// No description provided for @profileNewPasswordHint.
  ///
  /// In es, this message translates to:
  /// **'Vacío para mantener la actual'**
  String get profileNewPasswordHint;

  /// No description provided for @profilePasswordShow.
  ///
  /// In es, this message translates to:
  /// **'Mostrar'**
  String get profilePasswordShow;

  /// No description provided for @profilePasswordHide.
  ///
  /// In es, this message translates to:
  /// **'Ocultar'**
  String get profilePasswordHide;

  /// No description provided for @profileSaveChanges.
  ///
  /// In es, this message translates to:
  /// **'Guardar cambios'**
  String get profileSaveChanges;

  /// No description provided for @profilePasskeysHintOn.
  ///
  /// In es, this message translates to:
  /// **'Registra passkeys en este dispositivo o renombra / quita las ya guardadas.'**
  String get profilePasskeysHintOn;

  /// No description provided for @profilePasskeysHintOff.
  ///
  /// In es, this message translates to:
  /// **'Las passkeys están desactivadas en la configuración del servidor. Actívalas en el panel web (ajustes globales) para poder registrar llaves.'**
  String get profilePasskeysHintOff;

  /// No description provided for @profileNoPasskeys.
  ///
  /// In es, this message translates to:
  /// **'No hay passkeys en esta cuenta.'**
  String get profileNoPasskeys;

  /// No description provided for @profilePasskeyRenameTooltip.
  ///
  /// In es, this message translates to:
  /// **'Renombrar'**
  String get profilePasskeyRenameTooltip;

  /// No description provided for @profilePasskeyDeleteTooltip.
  ///
  /// In es, this message translates to:
  /// **'Eliminar'**
  String get profilePasskeyDeleteTooltip;

  /// No description provided for @profileAddPasskeyNameLabel.
  ///
  /// In es, this message translates to:
  /// **'NOMBRE (EJ: IPHONE, YUBIKEY)'**
  String get profileAddPasskeyNameLabel;

  /// No description provided for @profileAddPasskeyNameHint.
  ///
  /// In es, this message translates to:
  /// **'Nombre (ej: iPhone, MacBook, YubiKey)'**
  String get profileAddPasskeyNameHint;

  /// No description provided for @profileAddPasskey.
  ///
  /// In es, this message translates to:
  /// **'Agregar passkey'**
  String get profileAddPasskey;

  /// No description provided for @profileRemovePasskeyTitle.
  ///
  /// In es, this message translates to:
  /// **'Quitar passkey'**
  String get profileRemovePasskeyTitle;

  /// No description provided for @profileRemovePasskeyBody.
  ///
  /// In es, this message translates to:
  /// **'¿Eliminar \"{name}\"? Las sesiones de esta cuenta se invalidan.'**
  String profileRemovePasskeyBody(String name);

  /// No description provided for @profileRenamePasskeyTitle.
  ///
  /// In es, this message translates to:
  /// **'Renombrar passkey'**
  String get profileRenamePasskeyTitle;

  /// No description provided for @profileRenamePasskeyFieldLabel.
  ///
  /// In es, this message translates to:
  /// **'Nombre'**
  String get profileRenamePasskeyFieldLabel;

  /// No description provided for @profileRenamePasskeyFieldHint.
  ///
  /// In es, this message translates to:
  /// **'ej. iPhone, YubiKey'**
  String get profileRenamePasskeyFieldHint;

  /// No description provided for @profilePasskeyRemoved.
  ///
  /// In es, this message translates to:
  /// **'Passkey eliminada.'**
  String get profilePasskeyRemoved;

  /// No description provided for @profileNameUpdated.
  ///
  /// In es, this message translates to:
  /// **'Nombre actualizado.'**
  String get profileNameUpdated;

  /// No description provided for @profileEnterPasskeyName.
  ///
  /// In es, this message translates to:
  /// **'Escribe un nombre para esta passkey.'**
  String get profileEnterPasskeyName;

  /// No description provided for @profilePasskeyRegisterFailed.
  ///
  /// In es, this message translates to:
  /// **'No se pudo registrar la passkey'**
  String get profilePasskeyRegisterFailed;

  /// No description provided for @profilePasskeyRegisteredOk.
  ///
  /// In es, this message translates to:
  /// **'Passkey registrada en este dispositivo.'**
  String get profilePasskeyRegisteredOk;

  /// No description provided for @profilePasskeyDuplicate.
  ///
  /// In es, this message translates to:
  /// **'Esta llave ya está registrada para tu cuenta.'**
  String get profilePasskeyDuplicate;

  /// No description provided for @profilePasskeyDomainHint.
  ///
  /// In es, this message translates to:
  /// **'No se pudo validar el dominio para passkeys ({detail}). Revisa «Origen passkey» en Ajustes si entras por IP o otro host.'**
  String profilePasskeyDomainHint(String detail);

  /// No description provided for @profilePasskeyDeviceUnsupported.
  ///
  /// In es, this message translates to:
  /// **'Este dispositivo no permite crear passkeys.'**
  String get profilePasskeyDeviceUnsupported;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'es'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'es':
      return AppLocalizationsEs();
  }

  throw FlutterError(
      'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
      'an issue with the localizations generation tool. Please file an issue '
      'on GitHub with a reproducible sample app and the gen-l10n configuration '
      'that was used.');
}
