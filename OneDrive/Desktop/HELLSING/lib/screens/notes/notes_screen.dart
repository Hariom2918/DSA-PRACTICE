import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../../database/hive_database.dart';
import '../../models/note_model.dart';
import '../../theme/yamada_theme.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';

class NotesScreen extends StatefulWidget {
  const NotesScreen({super.key});

  @override
  State<NotesScreen> createState() => _NotesScreenState();
}

class _NotesScreenState extends State<NotesScreen> {
  bool _isSearching = false;
  final _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: YamadaTheme.crimson,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
              child: Row(
                children: [
                  if (!_isSearching)
                    Expanded(
                      child: Text('BRAIN DUMP', style: YamadaTheme.heading1)
                          .animate()
                          .fadeIn(duration: 400.ms)
                          .slideX(begin: -0.2, end: 0),
                    ),
                  if (_isSearching)
                    Expanded(
                      child: TextField(
                        controller: _searchController,
                        autofocus: true,
                        style: YamadaTheme.body,
                        decoration: InputDecoration(
                          hintText: 'SEARCH...',
                          hintStyle: YamadaTheme.body.copyWith(color: YamadaTheme.inkGhost),
                          border: InputBorder.none,
                        ),
                        onChanged: (v) => setState(() => _searchQuery = v),
                      ),
                    ),
                  GestureDetector(
                    onTap: () {
                      setState(() {
                        _isSearching = !_isSearching;
                        if (!_isSearching) {
                          _searchController.clear();
                          _searchQuery = '';
                        }
                      });
                    },
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(border: YamadaTheme.hardBorder),
                      child: Icon(
                        _isSearching ? Icons.close : Icons.search,
                        color: YamadaTheme.ink,
                        size: 20,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 16),
              child: Text('FIELD NOTES',
                  style: YamadaTheme.sectionLabel
                      .copyWith(color: YamadaTheme.inkLight)),
            ),
            const Divider(height: 2),
            Expanded(
              child: ValueListenableBuilder<Box<NoteModel>>(
                valueListenable: YamadaDatabase.notesBox.listenable(),
                builder: (context, box, _) {
                  final allNotes = box.values.toList();
                  final notes = _searchQuery.isEmpty 
                    ? allNotes 
                    : allNotes.where((n) => n.title.toLowerCase().contains(_searchQuery.toLowerCase()) || n.content.toLowerCase().contains(_searchQuery.toLowerCase())).toList();
                  if (notes.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            _searchQuery.isNotEmpty ? 'NO RESULTS' : 'EMPTY',
                            style: YamadaTheme.heading3,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            _searchQuery.isNotEmpty
                                ? 'ADJUST SEARCH TERMS'
                                : 'TAP + TO CREATE',
                            style: YamadaTheme.caption
                                .copyWith(color: YamadaTheme.inkSubtle),
                          ),
                        ],
                      ),
                    );
                  }

                  return AnimationLimiter(
                    child: ListView.builder(
                      padding: const EdgeInsets.all(20),
                      itemCount: notes.length,
                      itemBuilder: (context, index) {
                        final note = notes[index];
                        return AnimationConfiguration.staggeredList(
                          position: index,
                          duration: const Duration(milliseconds: 400),
                          child: SlideAnimation(
                            horizontalOffset: 50.0,
                            child: FadeInAnimation(
                              child: _NoteCard(
                                note: note,
                                onTap: () => _openEditor(note),
                                onDelete: () => _deleteNote(note.id),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _openEditor(null),
        child: const Icon(Icons.add, size: 28),
      ),
    );
  }

  Future<void> _deleteNote(String id) async {
    await YamadaDatabase.deleteNote(id);
  }

  void _openEditor(NoteModel? note) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => _NoteEditorPage(note: note),
      ),
    );
  }
}

class _NoteCard extends StatelessWidget {
  final NoteModel note;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const _NoteCard({
    required this.note,
    required this.onTap,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final preview = note.content.length > 80
        ? '${note.content.substring(0, 80)}...'
        : note.content;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(border: YamadaTheme.hardBorder),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(note.title, style: YamadaTheme.bodyBold),
                ),
                GestureDetector(
                  onTap: onDelete,
                  child: Icon(Icons.close, color: YamadaTheme.inkSubtle, size: 18),
                ),
              ],
            ),
            if (preview.isNotEmpty) ...[
              const SizedBox(height: 6),
              Text(preview,
                  style: YamadaTheme.body.copyWith(color: YamadaTheme.inkLight),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis),
            ],
            const SizedBox(height: 8),
            Row(
              children: [
                Text(
                  DateFormat('dd MMM · HH:mm').format(note.updatedAt),
                  style: YamadaTheme.caption.copyWith(color: YamadaTheme.inkSubtle),
                ),
                if (note.tags.isNotEmpty) ...[
                  const SizedBox(width: 8),
                  ...note.tags.take(3).map((tag) => Container(
                    margin: const EdgeInsets.only(right: 4),
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    color: YamadaTheme.ink.withValues(alpha: 0.1),
                    child: Text(tag.trim().toUpperCase(),
                        style: YamadaTheme.caption.copyWith(fontSize: 9)),
                  )),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _NoteEditorPage extends StatefulWidget {
  final NoteModel? note;
  const _NoteEditorPage({this.note});

  @override
  State<_NoteEditorPage> createState() => _NoteEditorPageState();
}

class _NoteEditorPageState extends State<_NoteEditorPage> {
  late TextEditingController _titleController;
  late TextEditingController _contentController;
  late TextEditingController _tagsController;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.note?.title ?? '');
    _contentController = TextEditingController(text: widget.note?.content ?? '');
    _tagsController = TextEditingController(text: widget.note?.tags.join(', ') ?? '');
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    _tagsController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_titleController.text.trim().isEmpty) return;

    if (widget.note == null) {
      final newNote = NoteModel(
        id: const Uuid().v4(),
        title: _titleController.text.trim(),
        content: _contentController.text,
        tags: _tagsController.text.trim().split(',').where((t) => t.isNotEmpty).toList(),
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      await YamadaDatabase.addNote(newNote);
    } else {
      final updated = widget.note!;
      updated.title = _titleController.text.trim();
      updated.content = _contentController.text;
      updated.tags = _tagsController.text.trim().split(',').where((t) => t.isNotEmpty).toList();
      updated.updatedAt = DateTime.now();
      await YamadaDatabase.updateNote(updated);
    }

    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: YamadaTheme.crimson,
      appBar: AppBar(
        title: Text(widget.note == null ? 'NEW NOTE' : 'EDIT NOTE'),
        actions: [
          GestureDetector(
            onTap: _save,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                color: YamadaTheme.ink,
                child: Text('SAVE',
                    style: YamadaTheme.caption.copyWith(color: YamadaTheme.crimson)),
              ),
            ),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            TextField(
              controller: _titleController,
              style: YamadaTheme.heading3,
              decoration: InputDecoration(
                hintText: 'TITLE',
                hintStyle: YamadaTheme.heading3.copyWith(color: YamadaTheme.inkGhost),
                border: InputBorder.none,
              ),
            ),
            const Divider(height: 2),
            const SizedBox(height: 12),
            TextField(
              controller: _tagsController,
              style: YamadaTheme.caption,
              decoration: InputDecoration(
                hintText: 'TAGS (COMMA SEPARATED)',
                hintStyle: YamadaTheme.caption.copyWith(color: YamadaTheme.inkGhost),
                border: InputBorder.none,
              ),
            ),
            const Divider(height: 2),
            const SizedBox(height: 12),
            Expanded(
              child: TextField(
                controller: _contentController,
                style: YamadaTheme.body,
                maxLines: null,
                expands: true,
                textAlignVertical: TextAlignVertical.top,
                decoration: InputDecoration(
                  hintText: 'WRITE...',
                  hintStyle: YamadaTheme.body.copyWith(color: YamadaTheme.inkGhost),
                  border: InputBorder.none,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
