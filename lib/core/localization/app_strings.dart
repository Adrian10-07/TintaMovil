import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../settings/app_settings_controller.dart';

/// Diccionario simple de traducciones. No es flutter_localizations (eso
/// requeriría generar archivos .arb y regenerar código); esto es un mapa
/// directo ES/EN pensado para poder extenderse fácil.
///
/// Cubre por ahora: barra inferior, saludo de Home, y las pantallas de
/// Perfil/Configuración. El resto de la app sigue en español fijo — se
/// puede ir agregando más claves aquí según se necesite.
class AppStrings {
  final AppLanguage language;
  const AppStrings(this.language);

  /// Forma corta de usar el diccionario dentro de un widget:
  /// `AppStrings.of(context).home`
  ///
  /// Usa Provider (AppSettingsController ya está registrado globalmente
  /// en main.dart), así que cualquier widget que llame esto se reconstruye
  /// solo cuando cambia el idioma — no hace falta pasar el controller a
  /// mano por cada widget.
  static AppStrings of(BuildContext context) {
    final controller = context.watch<AppSettingsController>();
    return AppStrings(controller.language);
  }

  String _t(String es, String en) => language == AppLanguage.es ? es : en;

  // ── Barra inferior ──────────────────────────────────────────────
  String get navHome => _t('Home', 'Home');
  String get navExplore => _t('Explorar', 'Explore');
  String get navStudy => _t('Estudio', 'Study');
  String get navClub => _t('Club', 'Club');
  String get navMe => _t('Yo', 'Me');

  // ── Home ─────────────────────────────────────────────────────────
  String get goodMorning => _t('Buenos días', 'Good morning');
  String get goodAfternoon => _t('Buenas tardes', 'Good afternoon');
  String get goodEvening => _t('Buenas noches', 'Good evening');
  String get catalogTitle => _t('Catálogo Tinta', 'Tinta Catalog');
  String get exploreCatalog => _t('Explorar catálogo', 'Explore catalog');
  String get seeAll => _t('Ver todo', 'See all');
  String get currentlyReading => _t('Leyendo actualmente', 'Currently reading');
  String get readingStreak => _t('Racha de lectura', 'Reading streak');

  // ── Perfil ───────────────────────────────────────────────────────
  String get myProfile => _t('Mi perfil', 'My profile');
  String get account => _t('Cuenta', 'Account');
  String get emailVerified => _t('Correo verificado', 'Email verified');
  String get yes => _t('Sí', 'Yes');
  String get no => _t('No', 'No');
  String get idiomaLabel => _t('Idioma', 'Language');
  String get settings => _t('Configuración', 'Settings');
  String get notifications => _t('Notificaciones', 'Notifications');
  String get notificationsSubtitle =>
      _t('Gestiona tus alertas de lectura', 'Manage your reading alerts');
  String get appearance => _t('Apariencia', 'Appearance');
  String get appearanceSubtitle =>
      _t('Tema y tamaño del texto', 'Theme and text size');
  String get privacy => _t('Privacidad', 'Privacy');
  String get privacySubtitle => _t('Control de tus datos', 'Control your data');
  String get helpSupport => _t('Ayuda y soporte', 'Help and support');
  String get logout => _t('Cerrar sesión', 'Log out');
  String get logoutConfirm => _t(
    '¿Estás seguro de que quieres cerrar tu sesión en Tinta?',
    'Are you sure you want to sign out of Tinta?',
  );
  String get cancel => _t('Cancelar', 'Cancel');
  String get memberSince => _t('Miembro desde', 'Member since');

  // ── Apariencia ───────────────────────────────────────────────────
  String get theme => _t('Tema', 'Theme');
  String get textSize => _t('Tamaño del texto', 'Text size');
  String get previewText => _t(
    'Vista previa: así se ve el texto normal de la app.',
    'Preview: this is what normal app text looks like.',
  );

  // ── Notificaciones ───────────────────────────────────────────────
  String get notifChooseText =>
      _t('Elige qué te queremos avisar dentro de la app.',
          'Choose what we should notify you about inside the app.');
  String get notifStreak => _t('Racha de lectura', 'Reading streak');
  String get notifStreakSub => _t(
    'Cuando subes de racha al abrir la app cada día.',
    'When your streak goes up by opening the app daily.',
  );
  String get notifUpload => _t('Documentos subidos', 'Uploaded documents');
  String get notifUploadSub => _t(
    'Cuando terminas de subir y analizar un PDF.',
    'When you finish uploading and analyzing a PDF.',
  );
  String get notifRecommendation => _t('Recomendaciones nuevas', 'New recommendations');
  String get notifRecommendationSub => _t(
    'Cuando el motor ML encuentra libros para ti.',
    'When the ML engine finds books for you.',
  );

  // ── Privacidad ───────────────────────────────────────────────────
  String get privacyIntro => _t(
    'Tu racha, historial de lectura, notificaciones y libros descargados '
        'se guardan solo en este dispositivo. Los PDF que subes para análisis '
        'sí viajan al servidor de Tinta por HTTPS (necesario para generar '
        'recomendaciones), pero nada de lo de aquí abajo se comparte con '
        'nadie más.',
    'Your streak, reading history, notifications, and downloaded books are '
        'stored only on this device. PDFs you upload for analysis do travel '
        "to Tinta's server over HTTPS (needed to generate recommendations), "
        "but nothing below is shared with anyone else.",
  );
  String get dataStored => _t('Datos guardados en este dispositivo', 'Data stored on this device');
  String get downloadedBooks => _t('Libros descargados (caché)', 'Downloaded books (cache)');
  String get readingHistory => _t('Historial de lectura', 'Reading history');
  String get recentDocuments => _t('Documentos recientes', 'Recent documents');
  String get delete => _t('Borrar', 'Delete');
  String get currentlyReadingSubtitle => _t(
    'Progreso guardado de "Leyendo actualmente"',
    'Saved progress from "Currently reading"',
  );
  String get recentDocumentsSubtitle =>
      _t('Lista de PDFs subidos en Estudio', 'List of PDFs uploaded in Study');
  String get notificationsHistorySubtitle => _t(
    'Historial de la bandeja de notificaciones',
    'Notification inbox history',
  );
  String get confirmDeleteBooks => _t(
    'Se borran las copias locales de los EPUB. La próxima vez que abras cada uno, se vuelve a descargar (necesitas conexión esa primera vez).',
    'Local EPUB copies are deleted. The next time you open each one, it downloads again (you need connection that first time).',
  );
  String get confirmDeleteHistory => _t(
    'Se borra tu progreso guardado en todos los libros. No se puede deshacer.',
    "Your saved progress in all books is deleted. This can't be undone.",
  );
  String get confirmDeleteDocuments => _t(
    'Se borra la lista de "Recientes" (no borra los PDF de tu dispositivo, solo la lista dentro de Tinta).',
    'The "Recent" list is deleted (does not delete the PDFs from your device, only the list inside Tinta).',
  );
  String get confirmDeleteNotifications => _t(
    'Se borra tu bandeja de notificaciones completa.',
    'Your entire notification inbox is deleted.',
  );

  // ── Ayuda y soporte ──────────────────────────────────────────────
  String get faq => _t('Preguntas frecuentes', 'Frequently asked questions');
  String get contactUs => _t('Contáctanos', 'Contact us');
  String get yourMessage => _t('Tu mensaje', 'Your message');
  String get sendByEmail => _t('Enviar por correo', 'Send by email');
}