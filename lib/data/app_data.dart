import 'dart:io';
import 'package:flutter/material.dart';
import 'package:collection/collection.dart';
import 'package:intl/intl.dart';
import 'package:ohnote/data/filters.dart';
import 'package:ohnote/data/label.dart';
import 'package:sqflite/sqflite.dart';
import 'package:ohnote/data/app_theme.dart';
import 'package:ohnote/data/settings.dart';
import 'package:ohnote/data/note.dart';
import 'package:ohnote/data/gui_manager.dart';
import 'package:ohnote/data/first_access.dart';
import 'package:ohnote/tools/home_widget_manager.dart';
import 'package:ohnote/tools/datetime_to_str_converter.dart';
import 'package:ohnote/constants.dart' as c;
import 'package:path/path.dart' as p;

class _IndexedDatabase {
  final int openDbId;
  final Database db;

  const _IndexedDatabase(this.openDbId, this.db);
}

class AppData {
  const AppData._();

  //Privates
  static bool _resetDatabase = false;
  static final List<int> _openDbIds = [];
  static bool _closingDb = false;
  static List<int> _notesUserOrder =
      []; //Contains the main, trash and archive notes user order simultaneously. Not necessarily incremented by one, e.g. in when using notesUserOrder.remove()

  //Public
  static final dataInitialized = ValueNotifier<bool>(false);
  static final themeBrightness = ValueNotifier<AppThemeBrightness>(AppThemeBrightness.systemDefault);
  static bool themeUpdatedFromSettings = false;
  static final appliedWallpaper = ValueNotifier<AssetImage?>(null); //Used instead of settings value to control the update moment of the wallpaper
  static Future<void> Function()? precacheWallpaperAsset;
  static final Map<Settings, ValueNotifier<String>> settings = Map.fromEntries(Settings.values.map((e) => MapEntry(e, ValueNotifier(''))));
  static final Map<FirstAccess, bool> firstAccesses = Map.fromEntries(FirstAccess.values.map((e) => MapEntry(e, true)));
  static List<Label> labels = [];
  static final notesManager = GuiManager(
    sortComparison: (a, b) => a.userOrder.compareTo(b.userOrder),
    getFilterDateTime: (note) => note.modifDateTime,
  );

  //Public using get
  static String? _dbPath;
  static Future<String> get dbPath async {
    _dbPath ??= p.join(await getDatabasesPath(), 'ohnote.db');
    return _dbPath!;
  }

  static Future<void> _deleteDb() async {
    var dbFile = File(await dbPath);
    if (await dbFile.exists()) {
      await dbFile.delete();
    }
  }

  static Future<_IndexedDatabase> _openDb() async {
    var openDbId = _openDbIds.isNotEmpty ? _openDbIds.max + 1 : 1;
    while (_closingDb) {
      await Future.delayed(const Duration(milliseconds: 10));
    }
    _openDbIds.add(openDbId);
    return _IndexedDatabase(
      openDbId,
      await openDatabase(
        await dbPath,
        //TODO: Set version to 1
        version: 5,
        onUpgrade: (db, oldVersion, newVersion) async {
          if (oldVersion < 5) {
            await db.rawDelete('ALTER TABLE notes RENAME COLUMN history_parent_id TO parent_id');
          }
        },
        onCreate: (db, version) async {
          await db.execute('CREATE TABLE settings('
              'id INTEGER PRIMARY KEY AUTOINCREMENT, '
              'param VARCHAR(25) NOT NULL, '
              'value VARCHAR(25) NOT NULL)');
          await db.insert('settings', {'param': Settings.theme.name, 'value': AppThemeBrightness.systemDefault.caption});
          await db.insert('settings', {'param': Settings.wallpaper.name, 'value': c.defaultWallpaper});
          await db.insert('settings', {'param': Settings.defaultColor.name, 'value': null.toString()});
          await db.insert('settings', {'param': Settings.defaultNumberOfLines.name, 'value': '1'});
          await db.insert('settings', {'param': Settings.maxHistory.name, 'value': '5'});
          await db.insert('settings', {'param': Settings.useCreationDateTime.name, 'value': false.toString()});
          await db.insert('settings', {'param': Settings.hideSendToTrashDialog.name, 'value': false.toString()});
          await db.insert('settings', {'param': Settings.hideArchiveNotesDialog.name, 'value': false.toString()});
          await db.insert('settings', {'param': Settings.hideRemovePermanentlyDialog.name, 'value': false.toString()});
          await db.insert('settings', {'param': Settings.hideRemoveLabelDialog.name, 'value': false.toString()});
          await db.insert('settings', {'param': Settings.hideDetachLabelDialog.name, 'value': false.toString()});
          await db.execute('CREATE TABLE first_access('
              'id INTEGER PRIMARY KEY AUTOINCREMENT, '
              'param VARCHAR(25) NOT NULL, '
              'shown INTEGER NOT NULL DEFAULT 0)');
          for (var firstAccess in FirstAccess.values) {
            await db.insert('first_access', {'param': firstAccess.name});
          }
          await db.execute('CREATE TABLE filters('
              'id INTEGER PRIMARY KEY AUTOINCREMENT, '
              'filter VARCHAR(15) NOT NULL, '
              'value TEXT)');
          await db.insert('filters', {'filter': Filters.FAVORITES});
          await db.insert('filters', {'filter': Filters.BY_DATE});
          await db.insert('filters', {'filter': Filters.BY_TEXT});
          await db.insert('filters', {'filter': Filters.BY_LABEL});
          await db.insert('filters', {'filter': Filters.BY_COLOR});
          await db.insert('filters', {'filter': Filters.CROSSED_OUT});
          await db.execute('CREATE TABLE labels('
              'id INTEGER PRIMARY KEY AUTOINCREMENT, '
              'text VARCHAR(30) NOT NULL)');
          await db.insert('labels', {'text': 'Business'});
          await db.insert('labels', {'text': 'Important'});
          await db.insert('labels', {'text': 'To Do'});
          await db.execute('CREATE TABLE notes('
              'id INTEGER PRIMARY KEY AUTOINCREMENT, '
              'text TEXT NOT NULL, '
              'modif_date_time VARCHAR(25) NOT NULL, '
              'creation_date_time VARCHAR(25) NOT NULL, '
              'is_crossed_out INTEGER NOT NULL DEFAULT 0, '
              'number_of_lines INTEGER NOT NULL DEFAULT 1, '
              'color INTEGER, '
              'favorite INTEGER NOT NULL DEFAULT 0, '
              'label_ids TEXT, '
              'parent_id INTEGER, '
              'history_date_time VARCHAR(25), '
              'archive_date_time VARCHAR(25), '
              'trash_date_time VARCHAR(25))');
          //notes_user_order table is used to update user order for several notes (also trash and archive) in a single statement.
          await db.execute('CREATE TABLE notes_user_order(data TEXT NOT NULL DEFAULT \'\')');
          await db.insert('notes_user_order', {'data': ''});
        },
        onOpen: (db) async {
          await db.execute('PRAGMA foreign_keys = ON');
        },
      ),
    );
  }

  static Future<void> _closeDb(_IndexedDatabase iDb) async {
    _openDbIds.remove(iDb.openDbId);
    if (_openDbIds.isEmpty) {
      _closingDb = true;
      await iDb.db.close();
      _closingDb = false;
    }
  }

  static void initData({bool runEnsureInitialized = true}) async {
    //Open db
    if (runEnsureInitialized) {
      WidgetsFlutterBinding.ensureInitialized(); //Avoid errors caused by flutter upgrade.
    }
    if (_resetDatabase) {
      _resetDatabase = false;
      await _deleteDb();
    }
    var iDb = await _openDb();

    //Settings
    List<Map<String, dynamic>> query = await iDb.db.query('settings', columns: ['param', 'value']);
    for (var row in query) {
      settings[Settings.values.firstWhere((e) => row['param'] == e.name)]!.value = row['value'];
    }
    appliedWallpaper.value = AssetImage(settings[Settings.wallpaper]!.value);
    var useCreationDateTime = AppData.settings[Settings.useCreationDateTime]!;
    void onUseCreationDateTimeChanged() {
      notesManager.getFilterDateTime = useCreationDateTime.value == true.toString() ? (note) => note.creationDateTime : (note) => note.modifDateTime;
      notesManager.requestFilterList();
    }

    useCreationDateTime.removeListener(onUseCreationDateTimeChanged);
    useCreationDateTime.addListener(onUseCreationDateTimeChanged);
    onUseCreationDateTimeChanged();

    //First accesses
    query = await iDb.db.query('first_access', columns: ['param', 'shown'], where: 'shown = 0');
    for (var row in query) {
      firstAccesses[FirstAccess.values.firstWhere((e) => row['param'] == e.name)] = false;
    }

    //Filters
    query = await iDb.db.query('filters', columns: ['filter', 'value']);
    notesManager.filters.value = Filters.fromDbQuery(query);

    //Labels
    query = await iDb.db.query('labels', columns: ['id', 'text']);
    labels = query.map((e) => Label(e['id'], e['text'])).sorted((a, b) => a.text.toLowerCase().compareTo(b.text.toLowerCase())).toList();

    //Notes user order
    query = await iDb.db.query('notes_user_order', columns: ['data']);
    String notesUserOrderData = query.map((e) => e['data']).first;
    if (notesUserOrderData != '') {
      _notesUserOrder = notesUserOrderData.split(',').map((e) => int.parse(e)).toList();
    }

    //Recovering draft note in case application was closed during a note edition
    query = await iDb.db.query('notes',
        columns: [
          'text',
          'modif_date_time', //For orderBy, sometimes it's required in SQL.
          'number_of_lines',
          'color',
          'favorite',
          'label_ids',
          'parent_id',
        ],
        where: 'parent_id IS NOT NULL AND history_date_time IS NULL',
        orderBy: 'modif_date_time DESC'); //It should be only one draft in db, but just in case we're getting the last one.
    if (query.isNotEmpty) {
      var draft = query.first;
      var parentId = draft['parent_id'];
      if (parentId == 0) {
        var newId = await iDb.db.insert('notes', {
          'text': draft['text'],
          'modif_date_time': draft['modif_date_time'],
          'creation_date_time': draft['creation_date_time'], //TODO: Update creation_date_time every time when updating draft
          'is_crossed_out': draft['is_crossed_out'],
          'number_of_lines': draft['number_of_lines'],
          'color': draft['color'],
          'favorite': draft['favorite'],
          'label_ids': draft['label_ids'],
        });
        _notesUserOrder.insert(0, newId);
        _updateDbNotesUserOrder(iDb);
        if (newId <= 0) {
          _error('ERROR');
        }
      } else {}
      var deleteDraftCount = await iDb.db.delete('notes', where: 'parent_id IS NOT NULL AND history_date_time IS NULL');
      if (deleteDraftCount <= 0) {
        _error('ERROR');
      }
    }

    //Note list
    notesManager.allList = await _queryNotes(
      db: iDb.db,
      guiManager: notesManager,
      where: 'parent_id IS NULL AND history_date_time IS NULL AND trash_date_time IS NULL AND archive_date_time IS NULL',
    );
    HomeWidgetManager.updateWidget(notesManager.allList);
    notesManager.requestFilterList();

    validateTimeInTrash();

    //Closing
    dataInitialized.value = true;
    await _closeDb(iDb);
  }

  static Future<List<Note>> queryNotes({
    required GuiManager guiManager,
    required String where,
  }) async {
    var iDb = await _openDb();
    var noteList = await _queryNotes(
      db: iDb.db,
      guiManager: guiManager,
      where: where,
    );
    _closeDb(iDb);
    return noteList;
  }

  static Future<List<Note>> _queryNotes({
    required Database db,
    required GuiManager guiManager,
    required String where,
  }) async {
    List<Map<String, dynamic>> query = await db.query(
      'notes',
      columns: [
        'id',
        'text',
        'modif_date_time',
        'creation_date_time',
        'is_crossed_out',
        'number_of_lines',
        'color',
        'favorite',
        'label_ids',
        'parent_id',
        'history_date_time',
        'trash_date_time',
        'archive_date_time',
      ],
      where: where,
    );
    var notes = query.map((e) => Note.fromDbQuery(e, guiManager)).toList();
    //User order and label ids don't apply to history.
    //User order and label ids are set for trash and archive in case note is restored.
    if (notes.any((e) => e.historyDateTime == null)) {
      var labelIds = labels.map((e) => e.id).toList();
      for (var note in notes) {
        note.userOrder = _notesUserOrder.indexOf(note.id);
        var idLength = note.labelIds.length;
        note.labelIds.removeWhere((e) => !labelIds.contains(e));
        if (note.labelIds.length != idLength) {
          await db.update('notes', {'label_ids': note.labelIdsString()}, where: 'id = ?', whereArgs: [note.id]);
        }
      }
    }
    return notes.sorted(guiManager.sortComparison);
  }

  static Future<bool> newNote(Note note, [bool isDraft = false]) async {
    var success = false;
    var iDb = await _openDb();
    //var newUserOrder = mainManager.list.value!.map((e) => e.userOrder).fold(0, max) + 1; requires to import 'dart:math' to use max.
    if !isDraft _clear Draft();
    var now = DateTime.now();
    var newId = await iDb.db.insert('notes', {
      'text': note.text,
      'modif_date_time': now.parseToStr(DTToStrFormat.DATABASE),
      'creation_date_time': now.parseToStr(DTToStrFormat.DATABASE),
      'is_crossed_out': note.isCrossedOut.value ? 1 : 0,
      'number_of_lines': note.numberOfLines.value,
      'color': note.color.value?.value,
      'favorite': note.favorite.value ? 1 : 0,
      'label_ids': note.labelIdsString(),
      'parent_id': isDraft ? note.id : null,
    });
    if (newId > 0) {
      if (!isDraft) {
        note.id = newId;
        note.modifDateTime = now;
        note.creationDateTime = now;
        for (var note in notesManager.allList) {
          note.userOrder++;
        }
        notesManager.allList = [note, ...notesManager.allList].sorted(notesManager.sortComparison);
        _notesUserOrder.insert(0, note.id);
        //_closeDb(iDb); //_updateDbNotesUserOrder closes the db.
        _updateDbNotesUserOrder(iDb, true); //It is required to not await to continue with code without waiting for db.
        HomeWidgetManager.updateWidget(notesManager.allList);
        notesManager.requestFilterList();
      } else {
        _closeDb(iDb);
      }
      success = true;
    } else {
      _closeDb(iDb);
      _error('ERROR');
    }
    return success;
  }

  static void updateNote(Note note, String oldText, Color? oldColor, [bool isDraft = fals]) async {
    if !isDraft _clear Draft ();
    _IndexedDatabase iDb;
    var noteCopy = note.clone(); //Cloning note to save asynchronously to history with the current values.
    if (note.text != oldText || note.color.value != oldColor) {
      var now = DateTime.now();
      note.modifDateTime = now;
      if (!notesManager.noteIsInFilter(note)) {
        notesManager.displayList.value!.remove(note);
      }
      HomeWidgetManager.updateWidget(notesManager.allList);
      iDb = await _openDb();
      ////Limiting the history size.
      // List<Map<String, dynamic>> query = await iDb.db
      //     .query('notes', columns: ['id'], where: 'parent_id = ${noteCopy.id} AND history_date_time IS NOT NULL', orderBy: 'history_date_time');
      // var historyIds = query.map((e) => e['id'] as int);
      // if (historyIds.length >= int.parse(settings[Settings.maxHistory]!.value)) {
      //   await iDb.db.delete('notes', where: 'id = ?', whereArgs: [historyIds.first]);
      // }
      await _validateMaxHistory(iDb, int.parse(settings[Settings.maxHistory]!.value) - 1, noteCopy.id);
      //Inserting to history in db.
      var newId = await iDb.db.insert('notes', {
        'parent_id': noteCopy.id,
        'history_date_time': now.parseToStr(DTToStrFormat.DATABASE),
        'text': oldText,
        'modif_date_time': noteCopy.modifDateTime.parseToStr(DTToStrFormat.DATABASE),
        'creation_date_time': noteCopy.creationDateTime.parseToStr(DTToStrFormat.DATABASE),
        'is_crossed_out': noteCopy.isCrossedOut.value ? 1 : 0,
        'number_of_lines': noteCopy.numberOfLines.value,
        'color': oldColor?.value,
      });
      if (newId <= 0) {
        _error('ERROR');
      }
    } else {
      iDb = await _openDb();
    }
    var count = await iDb.db.update(
      'notes',
      {
        'text': note.text,
        'modif_date_time': note.modifDateTime.parseToStr(DTToStrFormat.DATABASE),
        'is_crossed_out': note.isCrossedOut.value ? 1 : 0,
        'number_of_lines': note.numberOfLines.value,
        'color': note.color.value?.value,
        'favorite': note.favorite.value ? 1 : 0,
        'label_ids': note.labelIdsString(),
      },
      where: 'id = ?',
      whereArgs: [note.id],
    );
    if (count <= 0) {
      _error('ERROR');
    }
    await _closeDb(iDb);
  }

  static void updateDbNotes(List<Note> notes, String field, String value) async {
    if (notes.isNotEmpty) {
      HomeWidgetManager.updateWidget(notesManager.allList);
      var iDb = await _openDb();
      var count = await iDb.db.rawUpdate('UPDATE notes SET $field = $value WHERE id IN (${notes.map((e) => e.id).join(',')})');
      if (count <= 0) {
        _error('ERROR');
      }
      await _closeDb(iDb);
    }
  }

  static void removeDbHistory(List<Note> history) async {
    if (history.isNotEmpty) {
      var iDb = await _openDb();
      var count = await iDb.db.rawDelete('DELETE FROM notes WHERE id IN (${history.map((e) => e.id).join(',')})');
      if (count <= 0) {
        _error('ERROR');
      }
      await _closeDb(iDb);
    }
  }

  static void restoreHistory(Note history, bool withStyle) async {
    var note = notesManager.allList.firstWhere((e) => e.id == history.parentId);
    note.text = history.text;
    note.modifDateTime = history.modifDateTime;
    if (withStyle) {
      note.isCrossedOut.value = history.isCrossedOut.value;
      note.numberOfLines.value = history.numberOfLines.value;
      note.color.value = history.color.value;
    }
    HomeWidgetManager.updateWidget(notesManager.allList);
    //Updating the note in db.
    var iDb = await _openDb();
    var count = await iDb.db.update(
      'notes',
      {
        'text': history.text,
        'modif_date_time': history.modifDateTime.parseToStr(DTToStrFormat.DATABASE),
        ...(withStyle
            ? {
                'is_crossed_out': history.isCrossedOut.value ? 1 : 0,
                'number_of_lines': history.numberOfLines.value,
                'color': history.color.value?.value,
              }
            : {}),
      },
      where: 'id = ?',
      whereArgs: [note.id],
    );
    if (count > 0) {
      count = await iDb.db.delete('notes', where: 'id = ?', whereArgs: [history.id]);
      if (count <= 0) {
        _error('ERROR');
      }
    } else {
      _error('ERROR');
    }
    await _closeDb(iDb);
  }

  static void archiveNotes(List<Note> notes) async {
    if (notes.isNotEmpty) {
      removeNotesFromLists(notes, notesManager);
      HomeWidgetManager.updateWidget(notesManager.allList);
      var iDb = await _openDb();
      var count = await iDb.db.rawUpdate(
          'UPDATE notes SET archive_date_time = \'${DateTime.now().parseToStr(DTToStrFormat.DATABASE)}\' WHERE id IN (${notes.map((e) => e.id).join(',')})');
      if (count <= 0) {
        _error('ERROR');
      }
      await _closeDb(iDb);
    }
  }

  static void sendNotesToTrash(List<Note> notes) async {
    if (notes.isNotEmpty) {
      removeNotesFromLists(notes, notesManager);
      HomeWidgetManager.updateWidget(notesManager.allList);
      var iDb = await _openDb();
      var count = await iDb.db.rawUpdate(
          'UPDATE notes SET trash_date_time = \'${DateTime.now().parseToStr(DTToStrFormat.DATABASE)}\', archive_date_time = NULL WHERE id IN (${notes.map((e) => e.id).join(',')})');
      if (count <= 0) {
        _error('ERROR');
      }
      await _closeDb(iDb);
    }
  }

  static void removeTrash(List<Note> trashNotes, GuiManager trashManager) async {
    if (trashNotes.isNotEmpty) {
      var idString = trashNotes.map((e) => e.id).join(',');
      removeNotesFromLists(trashNotes, trashManager);
      for (var note in trashNotes) {
        _notesUserOrder.remove(note.id);
      }
      var iDb = await _openDb();
      var count = await iDb.db.rawDelete('DELETE FROM notes WHERE id IN ($idString) OR parent_id IN ($idString)');
      if (count <= 0) {
        _error('ERROR');
      }
      await _updateDbNotesUserOrder(iDb);
      await _closeDb(iDb);
    }
  }

  static void restoreNotes(List<Note> notes) async {
    if (notes.isNotEmpty) {
      for (Note note in notes) {
        note.trashDateTime = null;
        note.archiveDateTime = null;
        note.guiManager = notesManager;
      }
      notesManager.allList = [...notesManager.allList, ...notes].sorted(notesManager.sortComparison);
      HomeWidgetManager.updateWidget(notesManager.allList);
      notesManager.requestFilterList();
      var iDb = await _openDb();
      var count = await iDb.db
          .rawUpdate('UPDATE notes SET trash_date_time = NULL, archive_date_time = NULL WHERE id IN (${notes.map((e) => e.id).join(',')})');
      if (count <= 0) {
        _error('ERROR');
      }
      await _closeDb(iDb);
    }
  }

  static Future<void> _clearDraft() async {
    var iDb = await _openDb();
    var count = await iDb.db.delete('notes', where: 'parent_id IS NOT NULL AND history_date_time IS NULL');
    if (count <= 0) {
      _error('ERROR');
    }
    _closeDb(iDb);
  }

  static Future<int> newLabel(String text, GuiManager? labelsManager) async {
    labelsManager?.displayList.value = null;
    var iDb = await _openDb();
    var newId = await iDb.db.insert('labels', {'text': text});
    if (newId > 0) {
      labels = [Label(newId, text), ...labels].sorted((a, b) => a.text.toLowerCase().compareTo(b.text.toLowerCase()));
      labelsManager?.allList = [
        Note(id: newId, text: text, guiManager: labelsManager),
        ...labelsManager.allList,
      ].sorted(labelsManager.sortComparison);
    } else {
      _error('ERROR');
    }
    _closeDb(iDb);
    labelsManager?.requestFilterList();
    return newId;
  }

  static void updateLabel(Label label, String value, GuiManager labelsManager) async {
    label.text = value;
    labelsManager.allList.sort(labelsManager.sortComparison);
    labelsManager.requestFilterList();
    var iDb = await _openDb();
    var count = await iDb.db.update('labels', {'text': value}, where: 'id = ?', whereArgs: [label.id]);
    if (count <= 0) {
      _error('ERROR');
    }
    await _closeDb(iDb);
  }

  static void removeLabels(List<Label> selectedLabels) async {
    if (selectedLabels.isNotEmpty) {
      var idString = selectedLabels.map((e) => e.id).join(',');
      var relatedNotes = <Note>[];
      for (var label in selectedLabels) {
        labels.remove(label);
        for (var note in notesManager.allList.where((e) => e.labelIds.contains(label.id)).toList()) {
          note.labelIds.remove(label.id);
          if (!relatedNotes.contains(note)) {
            relatedNotes.add(note);
          }
        }
      }
      var iDb = await _openDb();
      var count = await iDb.db.rawDelete('DELETE FROM labels WHERE id IN ($idString)');
      for (var note in relatedNotes) {
        //Note: trash and archive labelIds will be removed from db when querying the notes (_queryNotes() function)
        await iDb.db.update('notes', {'label_ids': note.labelIdsString()}, where: 'id = ?', whereArgs: [note.id]);
      }
      if (count <= 0) {
        _error('ERROR');
      }
      await _closeDb(iDb);
    }
  }

  static void removeNotesFromLists(List<Note> selectedNotes, GuiManager guiManager) {
    for (var note in selectedNotes) {
      guiManager.allList.remove(note);
      guiManager.displayList.value!.remove(note);
    }
  }

  static void reorderNote(int oldIndex, int newIndex) async {
    if (oldIndex < newIndex) {
      newIndex -= 1;
    }
    var newIndexNote = notesManager.displayList.value![newIndex];
    var newIndexOfAll = notesManager.allList.indexOf(newIndexNote);
    var newIndexOfUserOrder = _notesUserOrder.indexOf(newIndexNote.id);
    var note = notesManager.displayList.value!.removeAt(oldIndex);
    notesManager.displayList.value!.insert(newIndex, note);
    notesManager.allList.remove(note);
    notesManager.allList.insert(newIndexOfAll, note);
    _notesUserOrder.remove(note.id);
    _notesUserOrder.insert(newIndexOfUserOrder, note.id);
    for (var note in notesManager.allList) {
      note.userOrder = _notesUserOrder.indexOf(note.id);
    }
    HomeWidgetManager.updateWidget(notesManager.allList);
    notesManager.displayList.notifyListeners();
    //Updating the db.
    var iDb = await _openDb();
    await _updateDbNotesUserOrder(iDb);
    await _closeDb(iDb);
  }

  static Future<void> _updateDbNotesUserOrder(_IndexedDatabase iDb, [bool closeDb = false]) async {
    int count = await iDb.db.rawUpdate('UPDATE notes_user_order SET data = \'${_notesUserOrder.join(',')}\'');
    if (count <= 0) {
      _error('ERROR');
    }
    if (closeDb) {
      await _closeDb(iDb);
    }
    return;
  }

  static void validateMaxHistory() async {
    var maxHistory = int.parse(AppData.settings[Settings.maxHistory]!.value);
    var iDb = await _openDb();
    for (var parentNote in notesManager.allList) {
      await _validateMaxHistory(iDb, maxHistory, parentNote.id);
    }
    await _closeDb(iDb);
  }

  static Future<void> _validateMaxHistory(_IndexedDatabase iDb, int maxHistory, int parentNoteId) {
    return iDb.db.rawDelete(
        'DELETE FROM notes WHERE id IN (SELECT id FROM notes WHERE parent_id = $parentNoteId AND history_date_time IS NOT NULL ORDER BY history_date_time DESC LIMIT -1 OFFSET ${maxHistory >= 0 ? maxHistory : maxHistory})');
  }

  static Future<void> validateTimeInTrash() async {
    var iDb = await _openDb();
    await iDb.db.rawDelete(
        'DELETE FROM notes WHERE trash_date_time IS NOT NULL AND (SELECT 30 - (JULIANDAY(\'now\',\'localtime\') - JULIANDAY(trash_date_time))) <= 0');
    await _closeDb(iDb);
  }

  static void updateDbShownFirstAccesses(List<FirstAccess> shownfirstAccesses, bool value) async {
    if (shownfirstAccesses.isNotEmpty) {
      var iDb = await _openDb();
      var count = await iDb.db
          .rawUpdate('UPDATE first_access SET shown = ${value ? 1 : 0} WHERE param IN (${shownfirstAccesses.map((e) => '\'${e.name}\'').join(',')})');
      if (count <= 0) {
        _error('ERROR');
      }
      await _closeDb(iDb);
    }
  }

  static void updateDbSettings(List<Settings> settings) async {
    if (settings.isNotEmpty) {
      var settingsValues = Map.fromEntries(settings.map((e) => MapEntry(e, AppData.settings[e]!.value)));
      var iDb = await _openDb();
      for (var setting in settings) {
        var count = await iDb.db.update('settings', {'value': settingsValues[setting]}, where: 'param = ?', whereArgs: [setting.name]);
        if (count <= 0) {
          _error('ERROR');
        }
      }
      await _closeDb(iDb);
    }
  }

  static void updateDbFilters() async {
    var filters = Filters()..copyFrom(notesManager.filters.value);
    var iDb = await _openDb();

    Future<void> update(String value, bool condition, String filterName) async {
      var count = await iDb.db.update('filters', {'value': condition ? value : null}, where: 'filter = ?', whereArgs: [filterName]);
      if (count <= 0) {
        _error('ERROR');
      }
    }

    await update(true.toString(), filters.favorites, Filters.FAVORITES);
    await update(
      '${filters.from != null ? DateFormat('yyyyMMdd').format(filters.from!) : null.toString()}-'
      '${filters.to != null ? DateFormat('yyyyMMdd').format(filters.to!) : null.toString()}',
      filters.from != null || filters.to != null,
      Filters.BY_DATE,
    );
    await update(filters.text, filters.text != '', Filters.BY_TEXT);
    await update(filters.labelIds.join(','), filters.labelIds.isNotEmpty, Filters.BY_LABEL);
    await update(filters.colors.map((e) => e.value).join(','), filters.colors.isNotEmpty, Filters.BY_COLOR);
    await update(true.toString(), filters.crossedOut, Filters.CROSSED_OUT);
    await _closeDb(iDb);
  }

  static void _error(String msg) {
    try {
      throw Exception(msg);
    } catch (e, s) {
      print('$msg\n$s');
    }
  }
}
