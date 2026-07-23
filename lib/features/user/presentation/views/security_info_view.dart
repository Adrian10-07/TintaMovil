import 'package:flutter/material.dart';

class SecurityInfoView extends StatelessWidget {
  const SecurityInfoView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Seguridad')),
      body: ListView(
        padding: EdgeInsets.fromLTRB(16, 16, 16, 16 + MediaQuery.of(context).padding.bottom),
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: colorScheme.primaryContainer.withOpacity(0.4),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.verified_user_rounded, color: colorScheme.primary),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Esto es exactamente lo que hace la app para proteger tu cuenta y tus datos — sin relleno.',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          _SecurityItem(
            icon: Icons.enhanced_encryption_rounded,
            title: 'Tu sesión está cifrada en el dispositivo',
            body: 'Tu token de acceso (lo que te mantiene con la sesión '
                'iniciada) se guarda cifrado usando el sistema de seguridad '
                'del propio teléfono: Android Keystore en Android, o el '
                'Keychain en iOS. Antes se guardaba en texto plano; ahora '
                'ni con acceso físico al dispositivo se puede leer '
                'directamente sin la llave del sistema operativo.',
          ),
          _SecurityItem(
            icon: Icons.lock_rounded,
            title: 'Comunicación siempre por HTTPS',
            body: 'Todo lo que la app manda o recibe del servidor (login, '
                'tu progreso de lectura, los documentos que subes) viaja '
                'cifrado por HTTPS — nadie que intercepte tu red puede leer '
                'ese tráfico.',
          ),
          _SecurityItem(
            icon: Icons.password_rounded,
            title: 'Nunca guardamos tu contraseña',
            body: 'La app nunca guarda tu contraseña en el dispositivo, ni '
                'siquiera cifrada. Solo se usa una vez para obtener el token '
                'de sesión, y de ahí en adelante se usa ese token.',
          ),
          _SecurityItem(
            icon: Icons.storage_rounded,
            title: 'Tus datos locales, bajo tu control',
            body: 'Racha, historial de lectura, notificaciones y libros '
                'descargados viven solo en tu dispositivo — puedes verlos y '
                'borrarlos cuando quieras desde Perfil > Privacidad.',
          ),
          _SecurityItem(
            icon: Icons.no_accounts_rounded,
            title: 'Cero rastreadores',
            body: 'La app no incluye SDKs de publicidad ni analítica de '
                'terceros que sigan tu actividad. Fue verificado en una '
                'auditoría de seguridad (MobSF) contra 432 rastreadores '
                'conocidos: 0 encontrados.',
          ),
        ],
      ),
    );
  }
}

class _SecurityItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final String body;

  const _SecurityItem({
    required this.icon,
    required this.title,
    required this.body,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: colorScheme.primary.withOpacity(0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, size: 20, color: colorScheme.primary),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
                const SizedBox(height: 4),
                Text(
                  body,
                  style: TextStyle(
                    fontSize: 12.5,
                    height: 1.4,
                    color: colorScheme.onSurface.withOpacity(0.65),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}