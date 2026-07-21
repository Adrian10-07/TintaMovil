import 'package:flutter/material.dart';
import 'recent_document.dart';
import 'recent_document_card.dart';

/// Sección "Recientes": encabezado con contador de archivos + lista
/// de RecentDocumentCard. Recibe la lista de documentos reales
/// (RecentDocumentsService), ya no hay datos mock.
class RecentDocumentsSection extends StatelessWidget {
  final List<RecentDocument> documents;
  final void Function(RecentDocument)? onTap;
  final void Function(RecentDocument)? onChatTap;
  final void Function(RecentDocument)? onDeleteTap;

  const RecentDocumentsSection({
    Key? key,
    required this.documents,
    this.onTap,
    this.onChatTap,
    this.onDeleteTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;

    if (documents.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 16),
        decoration: BoxDecoration(
          color: colorScheme.surfaceContainerLowest,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          children: [
            Icon(Icons.folder_open_rounded,
                size: 32, color: colorScheme.onSurface.withOpacity(0.3)),
            const SizedBox(height: 8),
            Text(
              'Todavía no has subido ningún documento.',
              style: textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurface.withOpacity(0.5),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Recientes', style: textTheme.titleMedium),
            Text(
              '${documents.length} archivos',
              style: textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurface.withOpacity(0.50),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        ...List.generate(documents.length, (index) {
          final doc = documents[index];
          return Padding(
            padding: EdgeInsets.only(
              bottom: index == documents.length - 1 ? 0 : 10,
            ),
            child: RecentDocumentCard(
              document: doc,
              style: DocumentTypeStyle.forIndex(index, colorScheme),
              onTap: () => onTap?.call(doc),
              onChatTap: () => onChatTap?.call(doc),
              onDeleteTap: () => onDeleteTap?.call(doc),
            ),
          );
        }),
      ],
    );
  }
}