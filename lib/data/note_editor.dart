import 'package:flutter/material.dart';
import 'package:ohnote/data/note.dart';
import 'package:ohnote/tools/single_async.dart';

class NoteEditor {
  NoteEditor({
    required this.note,
    required this.unmodifiedNote,
    required this.textController,
    required this.draftSaver,
  });

  final Note note;
  Note unmodifiedNote;
  final TextEditingController textController;
  final SingleAsync draftSaver;
  int? draftId;
  bool savingDraft = false;
}
