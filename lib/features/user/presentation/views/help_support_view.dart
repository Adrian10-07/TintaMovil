import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

/// Pantalla "Ayuda y soporte" — preguntas frecuentes estáticas + un
/// formulario de feedback que abre la app de correo del usuario con un
/// mailto: prellenado (asunto + cuerpo), listo para mandar.
class HelpSupportView extends StatefulWidget {
  final String userEmail;
  const HelpSupportView({Key? key, required this.userEmail}) : super(key: key);

  @override
  State<HelpSupportView> createState() => _HelpSupportViewState();
}

class _HelpSupportViewState extends State<HelpSupportView> {
  // Cambia esto por el correo real del equipo cuando lo tengan.
  static const _supportEmail = 'soporte.tinta@gmail.com';

  final _subjectController = TextEditingController();
  final _messageController = TextEditingController();
  bool _sending = false;

  @override
  void dispose() {
    _subjectController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  Future<void> _sendFeedback() async {
    if (_messageController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Escribe tu mensaje antes de enviar.')),
      );
      return;
    }

    setState(() => _sending = true);

    final subject = _subjectController.text.trim().isEmpty
        ? 'Feedback — Tinta App'
        : _subjectController.text.trim();

    final body = '${_messageController.text.trim()}\n\n'
        '---\n'
        'Enviado desde: ${widget.userEmail}';

    final uri = Uri(
      scheme: 'mailto',
      path: _supportEmail,
      query: 'subject=${Uri.encodeComponent(subject)}&body=${Uri.encodeComponent(body)}',
    );

    try {
      final abierto = await launchUrl(uri);
      if (!abierto && mounted) {
        _showNoMailAppDialog(subject, body);
      } else if (mounted) {
        _subjectController.clear();
        _messageController.clear();
      }
    } catch (_) {
      if (mounted) _showNoMailAppDialog(subject, body);
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  /// Si el dispositivo no tiene una app de correo configurada,
  /// launchUrl falla — en ese caso mostramos el correo y el mensaje para
  /// que el usuario lo copie manualmente en vez de dejarlo sin opción.
  void _showNoMailAppDialog(String subject, String body) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('No se encontró una app de correo'),
        content: SingleChildScrollView(
          child: Text(
            'Escríbenos directo a:\n$_supportEmail\n\nAsunto: $subject\n\n$body',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cerrar'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Ayuda y soporte')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text('Preguntas frecuentes', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 10),
          const _FaqTile(
            question: '¿Puedo leer sin conexión a internet?',
            answer: 'Sí, una vez que abres un libro por primera vez (necesita internet), se guarda en tu dispositivo y puedes reabrirlo offline después.',
          ),
          const _FaqTile(
            question: '¿Qué pasa con los PDF que subo?',
            answer: 'Se suben por conexión segura al servidor de análisis para generar recomendaciones, y también se guardan en tu dispositivo. Puedes borrar ese historial en Perfil > Privacidad.',
          ),
          const _FaqTile(
            question: '¿Cómo cambio mi nombre o idioma?',
            answer: 'Toca el ícono de lápiz junto a tu nombre en la parte de arriba de tu perfil.',
          ),
          const _FaqTile(
            question: '¿Cómo se calcula mi racha de lectura?',
            answer: 'Sube un día cada vez que abres la app en un día consecutivo al anterior. Si te saltas un día, se reinicia.',
          ),
          const SizedBox(height: 28),
          Text('Contáctanos', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 4),
          Text(
            'Manda tus dudas, reportes de errores o sugerencias — se abre tu app de correo con el mensaje ya listo.',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: colorScheme.onSurface.withOpacity(0.6),
            ),
          ),
          const SizedBox(height: 14),
          TextField(
            controller: _subjectController,
            decoration: const InputDecoration(
              labelText: 'Asunto (opcional)',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _messageController,
            maxLines: 5,
            decoration: const InputDecoration(
              labelText: 'Tu mensaje',
              hintText: 'Cuéntanos qué pasó o qué te gustaría ver en Tinta...',
              border: OutlineInputBorder(),
              alignLabelWithHint: true,
            ),
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: _sending ? null : _sendFeedback,
              icon: _sending
                  ? const SizedBox(
                width: 16, height: 16,
                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
              )
                  : const Icon(Icons.email_rounded, size: 18),
              label: const Text('Enviar por correo'),
            ),
          ),
        ],
      ),
    );
  }
}

class _FaqTile extends StatelessWidget {
  final String question;
  final String answer;
  const _FaqTile({required this.question, required this.answer});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(14),
      ),
      child: ExpansionTile(
        title: Text(question, style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600)),
        childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
        expandedCrossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            answer,
            style: TextStyle(fontSize: 12.5, color: colorScheme.onSurface.withOpacity(0.65)),
          ),
        ],
      ),
    );
  }
}