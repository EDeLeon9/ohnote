import 'dart:io';
import 'package:flutter/material.dart';
import 'package:collection/collection.dart';
import 'package:intl/intl.dart';
import 'package:sqflite/sqflite.dart';
import 'package:ohnote/data/filters.dart';
import 'package:ohnote/data/home_widget_config.dart';
import 'package:ohnote/data/label.dart';
import 'package:ohnote/data/sort_by.dart';
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
  static List<HomeWidgetConfig> homeWidgetConfigs = [];
  static final notesManager = GuiManager(
    sortComparison: (a, b) => a.userOrder.compareTo(b.userOrder),
    getComparisonDateTime: (note) => note.modifDateTime,
  );

  //Public using get and set
  static String? _dbPath;
  static Future<String> get dbPath async {
    _dbPath ??= p.join(await getDatabasesPath(), 'ohnote.db');
    return _dbPath!;
  }

  static List<Label> _labels = [];
  static List<int> _labelIds = [];
  static List<int> get labelIds => _labelIds;
  static List<Label> get labels => _labels;
  static set labels(List<Label> value) {
    _labels = value;
    _labelIds = value.map((e) => e.id).toList();
  }

  //Functions
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
        //TODO: set to version 1.
        version: 5,
        onUpgrade: (db, oldVersion, newVersion) async {
          if (oldVersion < 3) {
            await db.execute('DELETE FROM first_access');
            for (var firstAccess in FirstAccess.values) {
              await db.insert('first_access', {'param': firstAccess.name});
            }
            await db.insert('settings', {'param': Settings.hideRemoveHomeWidgetConfigDialog.name, 'value': false.toString()});
            await db.execute('CREATE TABLE home_widget_config('
                'id INTEGER PRIMARY KEY, '
                'title VARCHAR(30) NOT NULL, '
                'theme VARCHAR(25) NOT NULL, '
                'opacity INTEGER NOT NULL,'
                'creation_date_time VARCHAR(25) NOT NULL)');
            await db.execute('ALTER TABLE filters ADD COLUMN home_widget_config_id INTEGER');
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
          await db.insert('settings', {'param': Settings.lastSortBy.name, 'value': SortByOrder.asc.name});
          await db.insert('settings', {'param': Settings.hideSendToTrashDialog.name, 'value': false.toString()});
          await db.insert('settings', {'param': Settings.hideArchiveNotesDialog.name, 'value': false.toString()});
          await db.insert('settings', {'param': Settings.hideRemovePermanentlyDialog.name, 'value': false.toString()});
          await db.insert('settings', {'param': Settings.hideRemoveLabelDialog.name, 'value': false.toString()});
          await db.insert('settings', {'param': Settings.hideDetachLabelDialog.name, 'value': false.toString()});
          await db.insert('settings', {'param': Settings.hideRemoveHomeWidgetConfigDialog.name, 'value': false.toString()});
          await db.execute('CREATE TABLE first_access('
              'id INTEGER PRIMARY KEY AUTOINCREMENT, '
              'param VARCHAR(25) NOT NULL, '
              'shown INTEGER NOT NULL DEFAULT 0)');
          for (var firstAccess in FirstAccess.values) {
            await db.insert('first_access', {'param': firstAccess.name});
          }
          await db.execute('CREATE TABLE home_widget_config('
              'id INTEGER PRIMARY KEY, '
              'title VARCHAR(30) NOT NULL, '
              'theme VARCHAR(25) NOT NULL, '
              'opacity INTEGER NOT NULL,'
              'creation_date_time VARCHAR(25) NOT NULL)');
          await db.execute('CREATE TABLE filters('
              'id INTEGER PRIMARY KEY AUTOINCREMENT, '
              'filter VARCHAR(15) NOT NULL, '
              'value TEXT, '
              'home_widget_config_id INTEGER)');
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
    HomeWidgetManager.onError = _error;

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
    appliedWallpaper.value = AssetImage('assets/wallpapers/${settings[Settings.wallpaper]!.value}');
    var useCreationDateTime = settings[Settings.useCreationDateTime]!;
    void onUseCreationDateTimeChanged() {
      notesManager.getComparisonDateTime =
          useCreationDateTime.value == true.toString() ? (note) => note.creationDateTime : (note) => note.modifDateTime;
      notesManager.requestUpdateDisplayList();
    }

    useCreationDateTime.removeListener(onUseCreationDateTimeChanged);
    useCreationDateTime.addListener(onUseCreationDateTimeChanged);
    onUseCreationDateTimeChanged();

    //First accesses
    query = await iDb.db.query('first_access', columns: ['param', 'shown'], where: 'shown = 0');
    for (var row in query) {
      firstAccesses[FirstAccess.values.firstWhere((e) => row['param'] == e.name)] = false;
    }

    //Home widget configurations
    Map<int, List<Map<String, dynamic>>> filtersQuery = {};
    query = await iDb.db.query('filters', columns: ['filter', 'value', 'home_widget_config_id']);
    for (var filter in query.toList()) {
      int homeWidgetConfigId = filter['home_widget_config_id'] ?? 0;
      var filters = filtersQuery[homeWidgetConfigId];
      if (filters == null) {
        filters = [];
        filtersQuery.addAll({homeWidgetConfigId: filters});
      }
      filters.add(filter);
    }
    query = await iDb.db.query('home_widget_config', columns: ['id', 'title', 'theme', 'opacity', 'creation_date_time']);
    homeWidgetConfigs = query.map((e) {
      int id = e['id'];
      String themeString = e['theme'];
      return HomeWidgetConfig(
        id: id,
        title: e['title'],
        theme: AppThemeBrightness.values.where((e) => e.caption == themeString).first,
        opacity: e['opacity'],
        creationDateTime: DateTime.parse(e['creation_date_time']),
        filters: Filters.fromDbQuery(filtersQuery[id]!),
      );
    }).toList();

    //Filters
    notesManager.filters.value = Filters.fromDbQuery(filtersQuery[0]!);

    //Labels
    query = await iDb.db.query('labels', columns: ['id', 'text']);
    labels = query.map((e) => Label(e['id'], e['text'])).sorted((a, b) => a.text.toLowerCase().compareTo(b.text.toLowerCase())).toList();

    //Notes user order
    query = await iDb.db.query('notes_user_order', columns: ['data']);
    String notesUserOrderData = query.map((e) => e['data']).first;
    if (notesUserOrderData.isNotEmpty) {
      //ToSet() just in case there were some error.
      _notesUserOrder = notesUserOrderData.split(',').map((e) => int.parse(e)).toSet().toList();
    }

    //Recovering draft note in case application was closed during a note edition.
    await _recoverFromDraft(iDb);

    //Note list
    notesManager.allList = await _queryNotes(
      iDb: iDb,
      guiManager: notesManager,
      where: 'parent_id IS NULL AND history_date_time IS NULL AND trash_date_time IS NULL AND archive_date_time IS NULL',
    );
    notesManager.requestUpdateDisplayList();

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
      iDb: iDb,
      guiManager: guiManager,
      where: where,
    );
    _closeDb(iDb);
    return noteList;
  }

  static Future<List<Note>> _queryNotes({
    required _IndexedDatabase iDb,
    required GuiManager guiManager,
    required String where,
  }) async {
    List<Map<String, dynamic>> query = await iDb.db.query(
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
      //User order
      var noUserOrder = notes.where((e) => !_notesUserOrder.contains(e.id)).toList();
      //Validation in case there were some error.
      if (noUserOrder.isNotEmpty) {
        _notesUserOrder.insertAll(0, noUserOrder.map((e) => e.id).sorted((a, b) => a.compareTo(b)));
        await _updateDbNotesUserOrder(iDb);
      }
      for (var note in notes) {
        note.userOrder = _notesUserOrder.indexOf(note.id);
        //Label ids
        var labelIdsLength = note.labelIds.length;
        note.labelIds.removeWhere((e) => !labelIds.contains(e));
        if (note.labelIds.length != labelIdsLength) {
          await iDb.db.update('notes', {'label_ids': note.labelIdsString()}, where: 'id = ?', whereArgs: [note.id]);
        }
      }
    }
    return notes.sorted(guiManager.sortComparison);
  }

  static Future<void> _recoverFromDraft(_IndexedDatabase iDb) async {
    List<Map<String, dynamic>> query = await iDb.db.query('notes',
        columns: [
          'text',
          'modif_date_time',
          'creation_date_time',
          'is_crossed_out',
          'number_of_lines',
          'color',
          'favorite',
          'label_ids',
          'parent_id',
        ],
        where: 'parent_id IS NOT NULL AND history_date_time IS NULL',
        orderBy: 'modif_date_time DESC'); //It should be only one draft in db, but just in case we're getting the last one.
    var draft = query.firstOrNull;
    if (draft != null) {
      String draftText = draft['text'];
      if (draftText.trim().isNotEmpty) {
        int parentId = draft['parent_id'];
        Map<String, dynamic> map = {
          'text': draftText,
          'modif_date_time': draft['modif_date_time'],
          'color': draft['color'],
          'favorite': draft['favorite'],
          'label_ids': draft['label_ids']
        };
        if (parentId == 0) {
          map.addAll({
            'creation_date_time': draft['creation_date_time'],
            'is_crossed_out': draft['is_crossed_out'],
            'number_of_lines': draft['number_of_lines'],
          });
          var newId = await iDb.db.insert('notes', map);
          if (newId > 0) {
            _notesUserOrder.insert(0, newId);
            await _updateDbNotesUserOrder(iDb);
          } else {
            _error('ERROR');
          }
        } else {
          query = await iDb.db.query(
            'notes',
            columns: ['text', 'modif_date_time', 'creation_date_time', 'is_crossed_out', 'number_of_lines', 'color'],
            where: 'id = ?',
            whereArgs: [parentId],
          );
          var parent = query.firstOrNull;
          if (parent != null) {
            if (draftText != parent['text'] || draft['color'] != parent['color']) {
              await _addHistory(
                iDb,
                parentId,
                draft['creation_date_time'],
                parent['text'],
                parent['modif_date_time'],
                parent['creation_date_time'],
                parent['is_crossed_out'],
                parent['number_of_lines'],
                parent['color'],
              );
            }
            await iDb.db.update('notes', map, where: 'id = ?', whereArgs: [parentId]);
          } else {
            _error('ERROR');
          }
        }
      }
      var count = await _clearDraft(iDb);
      if (count <= 0) {
        _error('ERROR');
      }
    }
  }

  static Future<int> _clearDraft(_IndexedDatabase iDb) async {
    return iDb.db.delete('notes', where: 'parent_id IS NOT NULL AND history_date_time IS NULL');
  }

  static Future<int> newNoteFromEdit(Note note, [bool isDraft = false]) async {
    var now = DateTime.now();
    var iDb = await _openDb();
    //var newUserOrder = mainManager.list.value!.map((e) => e.userOrder).fold(0, max) + 1; requires to import 'dart:math' to use max.
    if (!isDraft) {
      await _clearDraft(iDb);
    }
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
        //_closeDb(iDb); _updateDbNotesUserOrder closes the db.
        _updateDbNotesUserOrder(iDb, true); //It is required to not await to continue with code without waiting for db.
        updateHomeWidget();
        notesManager.requestUpdateDisplayList();
      } else {
        _closeDb(iDb);
      }
    } else {
      _closeDb(iDb);
      _error('ERROR');
    }
    return newId;
  }

  static Future<void> updateNoteFromEdit(Note note, Note oldNote, [int? draftId]) async {
    _IndexedDatabase iDb;
    var now = DateTime.now();
    var modified = note.text != oldNote.text || note.color.value != oldNote.color.value;
    var modifiedWithoutHistory = modified || note.favorite.value != oldNote.favorite.value || note.labelIds.join(',') != oldNote.labelIds.join(',');
    if ((modified || modifiedWithoutHistory) && draftId == null) {
      note.modifDateTime = now;
      if (!notesManager.noteIsInFilter(note)) {
        notesManager.displayList.value!.remove(note);
      }
      updateHomeWidget();
    }
    if (modified && draftId == null) {
      var noteCopy = note.clone(); //Cloning note to save asynchronously to history with the current values.
      iDb = await _openDb();
      await _addHistory(
        iDb,
        noteCopy.id,
        now.parseToStr(DTToStrFormat.DATABASE),
        oldNote.text,
        noteCopy.modifDateTime.parseToStr(DTToStrFormat.DATABASE),
        noteCopy.creationDateTime.parseToStr(DTToStrFormat.DATABASE),
        noteCopy.isCrossedOut.value ? 1 : 0,
        noteCopy.numberOfLines.value,
        oldNote.color.value?.value,
      );
    } else {
      iDb = await _openDb();
    }
    Map<String, dynamic> updateMap = {
      'text': note.text,
      'modif_date_time': now.parseToStr(DTToStrFormat.DATABASE),
      'color': note.color.value?.value,
      'favorite': note.favorite.value ? 1 : 0,
      'label_ids': note.labelIdsString(),
    };
    if (draftId == null) {
      await _clearDraft(iDb);
    } else {
      updateMap.addAll({'creation_date_time': now.parseToStr(DTToStrFormat.DATABASE)});
    }
    var count = await iDb.db.update('notes', updateMap, where: 'id = ?', whereArgs: [draftId ?? note.id]);
    if (count <= 0) {
      _error('ERROR');
    }
    await _closeDb(iDb);
  }

  static void updateDbNotes(List<Note> notes, String field, String value) async {
    if (notes.isNotEmpty) {
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
    updateHomeWidget();
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
      updateHomeWidget();
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
      updateHomeWidget();
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
      updateHomeWidget();
      notesManager.requestUpdateDisplayList();
      var iDb = await _openDb();
      var count = await iDb.db
          .rawUpdate('UPDATE notes SET trash_date_time = NULL, archive_date_time = NULL WHERE id IN (${notes.map((e) => e.id).join(',')})');
      if (count <= 0) {
        _error('ERROR');
      }
      await _closeDb(iDb);
    }
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
    labelsManager?.requestUpdateDisplayList();
    return newId;
  }

  static void updateLabel(Label label, String value, GuiManager labelsManager) async {
    label.text = value;
    labelsManager.allList.sort(labelsManager.sortComparison);
    labelsManager.requestUpdateDisplayList();
    var iDb = await _openDb();
    var count = await iDb.db.update('labels', {'text': value}, where: 'id = ?', whereArgs: [label.id]);
    if (count <= 0) {
      _error('ERROR');
    }
    await _closeDb(iDb);
  }

  static void removeLabels(List<int> labelIds) async {
    if (labelIds.isNotEmpty) {
      var idString = labelIds.join(',');
      var notesWithLabelIds = <Note>[];
      for (var labelId in labelIds) {
        for (var note in notesManager.allList.where((e) => e.labelIds.contains(labelId)).toList()) {
          note.labelIds.remove(labelId);
          if (!notesWithLabelIds.contains(note)) {
            notesWithLabelIds.add(note);
          }
        }
      }
      labels.removeWhere((e) => labelIds.contains(e.id));
      updateHomeWidget();
      var iDb = await _openDb();
      var count = await iDb.db.rawDelete('DELETE FROM labels WHERE id IN ($idString)');
      for (var note in notesWithLabelIds) {
        //Note: trash and archive labelIds will be removed from db when querying the notes (_queryNotes() function)
        await iDb.db.update('notes', {'label_ids': note.labelIdsString()}, where: 'id = ?', whereArgs: [note.id]);
      }
      if (count <= 0) {
        _error('ERROR');
      }
      await _closeDb(iDb);
    }
  }

  static void updateDbHomeWidgetConfig(HomeWidgetConfig homeWidgetConfig, bool isNew) async {
    int dbResult;
    var now = DateTime.now();
    var iDb = await _openDb();
    if (isNew) {
      dbResult = await iDb.db.insert('home_widget_config', {
        'id': homeWidgetConfig.id,
        'title': homeWidgetConfig.title,
        'theme': homeWidgetConfig.theme.caption,
        'opacity': homeWidgetConfig.opacity,
        'creation_date_time': now.parseToStr(DTToStrFormat.DATABASE),
      });
    } else {
      dbResult = await iDb.db.update(
        'home_widget_config',
        {
          'title': homeWidgetConfig.title,
          'theme': homeWidgetConfig.theme.caption,
          'opacity': homeWidgetConfig.opacity,
        },
        where: 'id = ?',
        whereArgs: [homeWidgetConfig.id],
      );
    }
    if (dbResult > 0) {
      await _updateDbFilters(iDb, homeWidgetConfig.notesManager.filters.value, false, isNew, homeWidgetConfig.id);
    } else {
      _error('ERROR');
    }
    _closeDb(iDb);
  }

  static void removeHomeWidgetConfigs(List<int> homeWidgetConfigIds) async {
    if (homeWidgetConfigIds.isNotEmpty) {
      var idString = homeWidgetConfigIds.join(',');
      homeWidgetConfigs.removeWhere((e) => homeWidgetConfigIds.contains(e.id));
      var iDb = await _openDb();
      var count = await iDb.db.rawDelete('DELETE FROM filters WHERE home_widget_config_id IN ($idString)');
      if (count > 0) {
        count = await iDb.db.rawDelete('DELETE FROM home_widget_config WHERE id IN ($idString)');
      }
      if (count <= 0) {
        _error('ERROR');
      }
      _closeDb(iDb);
    }
  }

  static void removeNotesFromLists(List<Note> notes, GuiManager guiManager) {
    for (var note in notes) {
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
    updateHomeWidget();
    notesManager.displayList.notifyListeners();
    var iDb = await _openDb();
    await _updateDbNotesUserOrder(iDb);
    await _closeDb(iDb);
  }

  static void sortNotes(int Function(Note a, Note b) sortByComparison, SortByOrder order) async {
    settings[Settings.lastSortBy]!.value = order.name;
    int Function(Note a, Note b) comparison = sortByComparison;
    if (order == SortByOrder.desc) {
      comparison = (a, b) => sortByComparison(b, a);
    }
    notesManager.allList.sort((a, b) {
      var result = comparison(a, b);
      if (result != 0) {
        return result;
      }
      return notesManager.sortComparison(a, b);
    });
    updateHomeWidget();
    int i = 0;
    var notesIds = notesManager.allList.map((e) => e.id).toList();
    List<int> newOrder = [];
    for (var id in _notesUserOrder) {
      if (notesIds.contains(id)) {
        if (notesIds.isNotEmpty) {
          newOrder.add(notesIds[i]);
          i++;
        }
      } else {
        newOrder.add(id);
      }
    }
    //Validation in case there were some error.
    for (i; i < notesIds.length; i++) {
      newOrder.add(notesIds[i]);
    }
    _notesUserOrder = newOrder;
    for (var note in notesManager.allList) {
      note.userOrder = _notesUserOrder.indexOf(note.id);
    }
    notesManager.requestUpdateDisplayList();
    var iDb = await _openDb();
    await _updateDbNotesUserOrder(iDb);
    var count = await iDb.db.update('settings', {'value': order.name}, where: 'param = ?', whereArgs: [Settings.lastSortBy.name]);
    if (count <= 0) {
      _error('ERROR');
    }
    await _closeDb(iDb);
  }

  static Future<void> _updateDbNotesUserOrder(_IndexedDatabase iDb, [bool closeDb = false]) async {
    var count = await iDb.db.update('notes_user_order', {'data': _notesUserOrder.join(',')});
    if (count <= 0) {
      _error('ERROR');
    }
    if (closeDb) {
      await _closeDb(iDb);
    }
  }

  static void validateMaxHistory() async {
    var maxHistory = int.parse(settings[Settings.maxHistory]!.value);
    var iDb = await _openDb();
    for (var parentNote in notesManager.allList) {
      await _validateMaxHistory(iDb, maxHistory, parentNote.id);
    }
    await _closeDb(iDb);
  }

  static Future<void> _validateMaxHistory(_IndexedDatabase iDb, int maxHistory, int parentNoteId) {
    return iDb.db.rawDelete(
        'DELETE FROM notes WHERE id IN (SELECT id FROM notes WHERE parent_id = $parentNoteId AND history_date_time IS NOT NULL ORDER BY history_date_time DESC LIMIT -1 OFFSET ${maxHistory >= 0 ? maxHistory : 0})');
  }

  static Future<void> _addHistory(
    _IndexedDatabase iDb,
    int parentId,
    String historyDateTime,
    String text,
    String modifDateTime,
    String creationDateTime,
    int isCrossedOut,
    int numberOfLines,
    int? color,
  ) async {
    await _validateMaxHistory(iDb, int.parse(settings[Settings.maxHistory]!.value) - 1, parentId);
    //Inserting to history in db.
    var id = await iDb.db.insert('notes', {
      'parent_id': parentId,
      'history_date_time': historyDateTime,
      'text': text,
      'modif_date_time': modifDateTime,
      'creation_date_time': creationDateTime,
      'is_crossed_out': isCrossedOut,
      'number_of_lines': numberOfLines,
      'color': color,
    });
    if (id <= 0) {
      _error('ERROR');
    }
  }

  static void updateDbFilters(Filters filters, [bool onlyUpdateText = false]) async {
    var iDb = await _openDb();
    await _updateDbFilters(iDb, filters, onlyUpdateText);
    await _closeDb(iDb);
  }

  static Future<void> _updateDbFilters(
    _IndexedDatabase iDb,
    Filters filters, [
    bool onlyUpdateText = false,
    bool insert = false,
    int? homeWidgetConfigId,
  ]) async {
    var where = 'filter = ? AND home_widget_config_id ${homeWidgetConfigId != null ? '= ?' : 'IS NULL'}';
    var filtersCopy = Filters()..copyFrom(filters);

    Future<void> upsert(String filterName, String value, bool notNullCondition) async {
      int dbResult;
      if (insert) {
        dbResult = await iDb.db.insert(
          'filters',
          {'filter': filterName, 'value': notNullCondition ? value : null, 'home_widget_config_id': homeWidgetConfigId},
        );
      } else {
        dbResult = await iDb.db.update(
          'filters',
          {'value': notNullCondition ? value : null},
          where: where,
          whereArgs: homeWidgetConfigId != null ? [filterName, homeWidgetConfigId] : [filterName],
        );
      }
      if (dbResult <= 0) {
        _error('ERROR');
      }
    }

    await upsert(Filters.BY_TEXT, filtersCopy.text, filtersCopy.text.isNotEmpty);
    if (!onlyUpdateText) {
      await upsert(Filters.FAVORITES, true.toString(), filtersCopy.favorites);
      await upsert(
        Filters.BY_DATE,
        '${filtersCopy.from != null ? DateFormat('yyyyMMdd').format(filtersCopy.from!) : null.toString()}-'
        '${filtersCopy.to != null ? DateFormat('yyyyMMdd').format(filtersCopy.to!) : null.toString()}',
        filtersCopy.from != null || filtersCopy.to != null,
      );
      await upsert(Filters.BY_LABEL, filtersCopy.labelIds.join(','), filtersCopy.labelIds.isNotEmpty);
      await upsert(Filters.BY_COLOR, filtersCopy.colors.map((e) => e.value).join(','), filtersCopy.colors.isNotEmpty);
      await upsert(Filters.CROSSED_OUT, true.toString(), filtersCopy.crossedOut);
    }
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

  static void updateHomeWidget([bool updateConfigList = false, int? maxId]) async {
    maxId ??= homeWidgetConfigs.map((e) => e.id).max;
    List<Future> requests = [];
    var allList = List.of(notesManager.allList);
    for (var config in homeWidgetConfigs) {
      config.notesManager.allList = allList;
      requests.add(config.notesManager.requestUpdateDisplayList());
    }
    await Future.wait(requests);
    var consecutiveIdsConfigs =
        List.generate(maxId, (index) => homeWidgetConfigs.firstWhereOrNull((e) => e.id == index + 1) ?? HomeWidgetConfig(id: index + 1));
    var serializableObjects = Map.fromEntries(consecutiveIdsConfigs.map((e) {
      return MapEntry('_ohNoteWidgetList_${e.id}', e.notesManager.displayList.value ?? '[REMOVED]');
    }));
    if (updateConfigList) {
      serializableObjects.addAll({'_ohNoteWidgetConfigIds': homeWidgetConfigs.map((e) => e.id).toList()});
      serializableObjects.addAll(Map.fromEntries(consecutiveIdsConfigs.map((e) {
        return MapEntry('_ohNoteWidgetConfig_${e.id}', e.notesManager.displayList.value != null ? e : '[REMOVED]');
      })));
      for (var config in homeWidgetConfigs) {
        config.notesManager.allList = allList;
        requests.add(config.notesManager.requestUpdateDisplayList());
      }
    }
    await HomeWidgetManager.updateWidgetWithSerializable(serializableObjects);
  }

  static void _error(String msg) {
    try {
      throw Exception(msg);
    } catch (e, s) {
      print('$msg\n$s');
    }
  }
}
