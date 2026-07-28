import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/services/search_service.dart';
import '../core/theme/app_tokens.dart';
import '../providers/nav_provider.dart';
import '../providers/semester_provider.dart';
import '../utils/constants.dart';
import '../widgets/note_editor_sheet.dart';
import '../widgets/placeholder_view.dart';
import 'lecture_detail_screen.dart';
import 'subject_workspace_screen.dart';
import '../core/models/enums.dart';

/// Global Search (Phase 12): "Normalization -> shows Lecture, PDF, PPT,
/// Assignment, Syllabus. No filename searching." One search box across
/// the active semester's subjects; [SearchService] does the actual
/// content matching, this screen just debounces typing and renders
/// results grouped visually by a leading type icon + subject name.
class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final _controller = TextEditingController();
  Timer? _debounce;

  bool _searching = false;
  bool _hasSearched = false;
  List<SearchResult> _results = const [];
  int? _lastSemesterId;

  void _onChanged(int semesterId, String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 350), () {
      _runSearch(semesterId, value);
    });
  }

  Future<void> _runSearch(int semesterId, String value) async {
    final query = value.trim();
    if (query.isEmpty) {
      setState(() {
        _results = const [];
        _hasSearched = false;
        _searching = false;
      });
      return;
    }

    setState(() => _searching = true);
    final results = await SearchService.instance.search(
      semesterId: semesterId,
      query: query,
    );
    if (!mounted) return;
    setState(() {
      _results = results;
      _hasSearched = true;
      _searching = false;
    });
  }

  void _open(SearchResult result) {
    if (result.lecture != null) {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => LectureDetailScreen(lecture: result.lecture!),
        ),
      );
      return;
    }

    if (result.note != null) {
      NoteEditorSheet.showEdit(context, note: result.note!);
      return;
    }

    final SubjectSection section;
    if (result.syllabus != null) {
      section = SubjectSection.syllabus;
    } else if (result.assignment != null) {
      section = SubjectSection.assignments;
    } else {
      section = SubjectSection.resources;
    }
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => SubjectWorkspaceScreen(
          subject: result.subject,
          initialSection: section,
        ),
      ),
    );
  }

  IconData _iconFor(SearchResultKind kind) {
    switch (kind) {
      case SearchResultKind.lecture:
        return Icons.photo_camera_outlined;
      case SearchResultKind.pdf:
        return Icons.picture_as_pdf_outlined;
      case SearchResultKind.ppt:
        return Icons.slideshow_outlined;
      case SearchResultKind.word:
        return Icons.description_outlined;
      case SearchResultKind.image:
        return Icons.image_outlined;
      case SearchResultKind.assignment:
        return Icons.assignment_outlined;
      case SearchResultKind.note:
        return Icons.sticky_note_2_outlined;
      case SearchResultKind.syllabus:
        return Icons.menu_book_outlined;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final active = context.watch<SemesterProvider>().active;

    if (active == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Search')),
        body: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Expanded(
              child: PlaceholderView(
                icon: Icons.search_rounded,
                title: 'No active semester',
                subtitle:
                    'Create a semester and add subjects first — Search '
                    'looks across everything in the active semester.',
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () => context.read<NavProvider>().setIndex(1),
                  child: const Text('Go to Semester'),
                ),
              ),
            ),
          ],
        ),
      );
    }

    // A different semester became active while a previous search's
    // results were still on screen — clear them rather than showing
    // stale hits from a semester that's no longer selected.
    if (_lastSemesterId != active.id) {
      _lastSemesterId = active.id;
      _results = const [];
      _hasSearched = false;
      _controller.clear();
    }

    return Scaffold(
      appBar: AppBar(title: Text('Search · ${active.name}')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: TextField(
              controller: _controller,
              autofocus: false,
              onChanged: (value) => _onChanged(active.id, value),
              decoration: InputDecoration(
                hintText: 'Search lectures, PDFs, PPTs, syllabus…',
                prefixIcon: const Icon(Icons.search_rounded),
                suffixIcon: _controller.text.isEmpty
                    ? null
                    : IconButton(
                        icon: const Icon(Icons.close_rounded),
                        onPressed: () {
                          _controller.clear();
                          _onChanged(active.id, '');
                        },
                      ),
                filled: true,
                border: OutlineInputBorder(
                  borderRadius: AppRadius.lgRadius,
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
          Expanded(child: _buildBody()),
        ],
      ),
    );
  }

  Widget _buildBody() {
    if (_searching) {
      return const Center(child: CircularProgressIndicator());
    }

    if (!_hasSearched) {
      return const PlaceholderView(
        icon: Icons.search_rounded,
        title: 'Search everything',
        subtitle:
            'Type above to search across every lecture, resource, and '
            'syllabus in this semester — by content, not just the file '
            'name.',
      );
    }

    if (_results.isEmpty) {
      return const PlaceholderView(
        icon: Icons.search_off_rounded,
        title: 'No matches',
        subtitle: 'Nothing found for that search in the active semester.',
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(AppSpacing.md),
      itemCount: _results.length,
      separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.sm),
      itemBuilder: (context, i) => _SearchResultCard(
        result: _results[i],
        icon: _iconFor(_results[i].kind),
        onTap: () => _open(_results[i]),
      ),
    );
  }
}

class _SearchResultCard extends StatelessWidget {
  const _SearchResultCard({
    required this.result,
    required this.icon,
    required this.onTap,
  });

  final SearchResult result;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = SubjectPalette.colorFor(result.subject.id);

    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                backgroundColor: color.withOpacity(0.15),
                foregroundColor: color,
                child: Icon(icon),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(result.title, style: theme.textTheme.titleMedium),
                    const SizedBox(height: 2),
                    Text(
                      '${result.kind.label} · ${result.subject.name}',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: color,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xxs),
                    Text(
                      result.snippet,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right_rounded,
                  color: theme.colorScheme.onSurfaceVariant),
            ],
          ),
        ),
      ),
    );
  }
}