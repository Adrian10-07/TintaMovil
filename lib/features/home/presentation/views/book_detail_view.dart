import 'package:flutter/material.dart';
import '../../domain/entities/book.dart';
import '../components/book_detail_header.dart';
import '../components/book_synopsis_section.dart';
import '../components/book_chapters_section.dart';
import '../components/book_chapter.dart';
import '../components/book_detail_bottom_bar.dart';

class BookDetailView extends StatefulWidget {
  const BookDetailView({Key? key}) : super(key: key);

  @override
  State<BookDetailView> createState() => _BookDetailViewState();
}

class _BookDetailViewState extends State<BookDetailView> {
  bool _isSaved = false;

  @override
  Widget build(BuildContext context) {
    final book = ModalRoute.of(context)!.settings.arguments as Book;
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      body: Column(
        children: [
          SafeArea(
            bottom: false,
            child: BookDetailHeader(
              book: book,
              onBack: () => Navigator.pop(context),
              isSaved: _isSaved,
              onSave: () => setState(() => _isSaved = !_isSaved),
              onShare: () {
                // pendiente: compartir libro (share_plus u otro paquete)
              },
            ),
          ),
          Expanded(
            child: Container(
              color: colorScheme.surface,
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    BookSynopsisSection(
                      description: book.description?.isNotEmpty == true
                          ? book.description!
                          : 'Sin sinopsis disponible para este libro.',
                    ),
                    const SizedBox(height: 28),
                    BookChaptersSection(
                      chapters: mockChaptersForBook(book.id),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: BookDetailBottomBar(
        onContinueReading: () {
          Navigator.pushNamed(context, '/reader', arguments: book);
        },
        onSecondaryTap: () {
          // pendiente: navegación a club de lectura / grupo de estudio
        },
      ),
    );
  }
}