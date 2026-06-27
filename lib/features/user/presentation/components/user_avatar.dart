import 'package:flutter/material.dart';
import 'package:tinta/core/ui/theme3material/theme.dart';

/// Avatar circular del usuario con gradiente Tinta.
///
/// Muestra imagen de red si [avatarUrl] no es null;
/// de lo contrario, la inicial del nombre sobre gradiente.
class UserAvatar extends StatelessWidget {
  final String? avatarUrl;
  final String name;
  final double size;

  const UserAvatar({
    Key? key,
    this.avatarUrl,
    required this.name,
    this.size = 80,
  }) : super(key: key);

  String get _initial =>
      name.isNotEmpty ? name[0].toUpperCase() : 'T';

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: avatarUrl == null ? MaterialTheme.avatarGradient : null,
        image: avatarUrl != null
            ? DecorationImage(
          image: NetworkImage(avatarUrl!),
          fit: BoxFit.cover,
        )
            : null,
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).colorScheme.shadow.withOpacity(0.12),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: avatarUrl == null
          ? Center(
        child: Text(
          _initial,
          style: TextStyle(
            color: Colors.white,
            fontFamily: 'PlusJakartaSans',
            fontWeight: FontWeight.w800,
            fontSize: size * 0.38,
          ),
        ),
      )
          : null,
    );
  }
}