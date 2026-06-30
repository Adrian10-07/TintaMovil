import 'package:flutter/material.dart';
import 'recent_document.dart';
import 'recent_document_card.dart';

/// Sección "Recientes": encabezado con contador de archivos + lista
/// de RecentDocumentCard. Recibe la lista de documentos para que el
/// padre decida la fuente (mock hoy, backend después).
class RecentDocumentsSection extends StatelessWidget {
  final List<RecentDocument> documents;
  final void Function(RecentDocument)? onChatTap;

  const RecentDocumentsSection({
    Key? key,
    required this.documents,
    this.onChatTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;

    if (documents.isEmpty) return const SizedBox.shrink();

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
              onChatTap: () => onChatTap?.call(doc),
            ),
          );
        }),
      ],
    );
  }
}
