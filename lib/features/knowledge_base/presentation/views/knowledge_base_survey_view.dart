import 'package:flutter/material.dart';

import '../../data/datasources/knowledge_base_prefs.dart';
import '../../domain/entities/knowledge_base_option.dart';
import '../viewmodels/knowledge_base_survey_viewmodel.dart';

/// Encuesta que se muestra tras crear una cuenta (y, si aún no se ha
/// contestado, también al iniciar sesión en una cuenta ya existente):
/// elegir qué bases de conocimiento descargar para que Tinta AI las use
/// como contexto local (RAG offline, sin conexión).
class KnowledgeBaseSurveyView extends StatefulWidget {
  final KnowledgeBaseSurveyViewModel viewModel;
  final String userId;
  final VoidCallback onDone;

  const KnowledgeBaseSurveyView({
    Key? key,
    required this.viewModel,
    required this.userId,
    required this.onDone,
  }) : super(key: key);

  @override
  State<KnowledgeBaseSurveyView> createState() =>
      _KnowledgeBaseSurveyViewState();
}

class _KnowledgeBaseSurveyViewState extends State<KnowledgeBaseSurveyView> {
  // ── Paleta Tinta ──────────────────────────────────────────────
  static const _mintPrimary = Color(0xFF3DBF7A);
  static const _deepGreen = Color(0xFF1A4D2E);
  static const _warmGold = Color(0xFFF5C842);
  static const _peach = Color(0xFFFFBF9B);
  static const _offWhite = Color(0xFFF2F5EF);
  static const _darkText = Color(0xFF1A2B1F);

  @override
  void initState() {
    super.initState();
    widget.viewModel.addListener(_onChange);
  }

  @override
  void dispose() {
    widget.viewModel.removeListener(_onChange);
    super.dispose();
  }

  void _onChange() {
    if (!mounted) return;
    setState(() {});
    if (widget.viewModel.state == KbSurveyState.done) {
      widget.onDone();
    } else if (widget.viewModel.state == KbSurveyState.error) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(widget.viewModel.errorMessage ?? 'Ocurrió un error'),
        ),
      );
    }
  }

  Future<void> _skip() async {
    await widget.viewModel.skip(widget.userId);
    if (mounted) widget.onDone();
  }

  @override
  Widget build(BuildContext context) {
    final vm = widget.viewModel;
    final isDownloading = vm.isDownloading;

    return Scaffold(
      backgroundColor: _offWhite,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 20),

              // ── Icono + encabezado ────────────────────────────
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: _mintPrimary,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(Icons.psychology_alt_rounded,
                    color: Colors.white, size: 28),
              ),
              const SizedBox(height: 20),
              Text(
                '¿Qué quieres\naprender?',
                style: TextStyle(
                  fontFamily: 'PlusJakartaSans',
                  fontWeight: FontWeight.w800,
                  fontSize: 32,
                  height: 1.15,
                  color: _darkText,
                  letterSpacing: -0.6,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                'Elige las bases de conocimiento que Tinta AI podrá usar '
                    'para ayudarte offline. Puedes cambiar esto después.',
                style: TextStyle(
                  fontFamily: 'DMSans',
                  fontSize: 14,
                  height: 1.4,
                  color: _darkText.withOpacity(0.55),
                ),
              ),

              const SizedBox(height: 28),

              // ── Opciones ───────────────────────────────────────
              Expanded(
                child: ListView.separated(
                  itemCount: KnowledgeBaseCatalog.available.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 14),
                  itemBuilder: (_, i) {
                    final option = KnowledgeBaseCatalog.available[i];
                    return _KbOptionCard(
                      option: option,
                      selected: vm.isSelected(option.id),
                      progress: vm.progress[option.id],
                      isDownloading: isDownloading,
                      onTap: () => vm.toggle(option.id),
                      mintPrimary: _mintPrimary,
                      deepGreen: _deepGreen,
                      warmGold: _warmGold,
                      peach: _peach,
                      darkText: _darkText,
                    );
                  },
                ),
              ),

              const SizedBox(height: 12),

              // ── Botón continuar ───────────────────────────────
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: isDownloading
                      ? null
                      : () async {
                    final ok = await vm.downloadSelected();
                    if (ok) {
                      await KnowledgeBasePrefs.markSurveyCompleted(
                        widget.userId,
                      );
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _mintPrimary,
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: _mintPrimary.withOpacity(0.5),
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18),
                    ),
                  ),
                  child: isDownloading
                      ? const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                        color: Colors.white, strokeWidth: 2.5),
                  )
                      : const Text(
                    'Continuar',
                    style: TextStyle(
                      fontFamily: 'PlusJakartaSans',
                      fontWeight: FontWeight.w700,
                      fontSize: 16,
                      letterSpacing: 0.2,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 12),

              Center(
                child: TextButton(
                  onPressed: isDownloading ? null : _skip,
                  child: Text(
                    'Ahora no',
                    style: TextStyle(
                      fontFamily: 'DMSans',
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: _darkText.withOpacity(0.45),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 12),
            ],
          ),
        ),
      ),
    );
  }
}

class _KbOptionCard extends StatelessWidget {
  final KnowledgeBaseOption option;
  final bool selected;
  final double? progress;
  final bool isDownloading;
  final VoidCallback onTap;
  final Color mintPrimary;
  final Color deepGreen;
  final Color warmGold;
  final Color peach;
  final Color darkText;

  const _KbOptionCard({
    required this.option,
    required this.selected,
    required this.progress,
    required this.isDownloading,
    required this.onTap,
    required this.mintPrimary,
    required this.deepGreen,
    required this.warmGold,
    required this.peach,
    required this.darkText,
  });

  IconData get _icon {
    switch (option.id) {
      case 'kb_programacion_informatica':
        return Icons.terminal_rounded;
      case 'kb_historia':
        return Icons.account_balance_rounded;
      default:
        return Icons.menu_book_rounded;
    }
  }

  Color get _accent {
    switch (option.id) {
      case 'kb_programacion_informatica':
        return mintPrimary;
      case 'kb_historia':
        return peach;
      default:
        return warmGold;
    }
  }

  @override
  Widget build(BuildContext context) {
    final showProgress = isDownloading && selected && progress != null;

    return GestureDetector(
      onTap: isDownloading ? null : onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected ? mintPrimary : darkText.withOpacity(0.08),
            width: selected ? 2 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: darkText.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: _accent.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(_icon, color: _accent, size: 22),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        option.title,
                        style: TextStyle(
                          fontFamily: 'PlusJakartaSans',
                          fontWeight: FontWeight.w700,
                          fontSize: 16,
                          color: deepGreen,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        option.conceptCountLabel,
                        style: TextStyle(
                          fontFamily: 'DMSans',
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: darkText.withOpacity(0.4),
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  width: 26,
                  height: 26,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: selected ? mintPrimary : Colors.transparent,
                    border: Border.all(
                      color: selected
                          ? mintPrimary
                          : darkText.withOpacity(0.25),
                      width: 2,
                    ),
                  ),
                  child: selected
                      ? const Icon(Icons.check_rounded,
                      color: Colors.white, size: 16)
                      : null,
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              option.description,
              style: TextStyle(
                fontFamily: 'DMSans',
                fontSize: 13,
                height: 1.4,
                color: darkText.withOpacity(0.55),
              ),
            ),
            if (showProgress) ...[
              const SizedBox(height: 12),
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: LinearProgressIndicator(
                  value: progress,
                  minHeight: 6,
                  backgroundColor: darkText.withOpacity(0.08),
                  valueColor: AlwaysStoppedAnimation<Color>(_accent),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Descargando… ${((progress ?? 0) * 100).round()}%',
                style: TextStyle(
                  fontFamily: 'DMSans',
                  fontSize: 11,
                  color: darkText.withOpacity(0.45),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}