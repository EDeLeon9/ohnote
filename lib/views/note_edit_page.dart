import 'package:flutter/material.dart';
import 'package:ohnote/data/first_access.dart';
import 'package:ohnote/data/app_data.dart';
import 'package:ohnote/data/gui_manager.dart';
import 'package:ohnote/data/note.dart';
import 'package:ohnote/data/note_editor.dart';
import 'package:ohnote/data/settings.dart';
import 'package:ohnote/tools/animated/animated_color.dart';
import 'package:ohnote/tools/animated/animatedscale_button.dart';
import 'package:ohnote/tools/custom_showcase.dart';
import 'package:ohnote/tools/landscape_textfield.dart';
import 'package:ohnote/view_components/header_buttons.dart';
import 'package:ohnote/view_components/label_container.dart';
import 'package:ohnote/views/dialogs/note_labels_dialog.dart';
import 'package:ohnote/views/dialogs/style_colorpicker_dialog.dart';
import 'package:ohnote/tools/comfirmation_dialog.dart';
import 'package:ohnote/views/bottomsheets/history_bottomsheet.dart';
import 'package:ohnote/constants.dart' as c;
import 'package:ohnote/tools/custom_toast.dart' as t;
import 'package:ohnote/tools/single_async.dart' as a;

class NoteEditPage extends StatefulWidget {
  const NoteEditPage({super.key, required this.notes, required this.selectedNoteId});

  final int selectedNoteId;
  final List<Note> notes;

  @override
  State<NoteEditPage> createState() => _NoteEditPageState();
}

class _NoteEditPageState extends State<NoteEditPage> with WidgetsBindingObserver {
  late final bool _isNewNote;
  late NoteEditor _currentEditor;
  late final List<NoteEditor?> _editors;
  String? _heroTag;
  late final PageController _pageController;
  bool _closing = false;
  final GuiManager historyManager = GuiManager(
    sortComparison: (a, b) => b.historyDateTime!.compareTo(a.historyDateTime!),
    getComparisonDateTime: (note) => note.modifDateTime,
  );
  bool _showCaseFinished = false;
  late final int _configBarSCPageIndex;
  int _removeLabelSCPageIndex = -1;
  late final List<ShowCaseKey<FirstAccess>> _showCaseKeys;
  final _configBarSCK = ShowCaseKey(FirstAccess.editConfigBarSC);
  final _backSCK = ShowCaseKey(FirstAccess.editBackSC);
  final _favoriteSCK = ShowCaseKey(FirstAccess.editFavoriteSC);
  final _labelNoteSCK = ShowCaseKey(FirstAccess.editLabelNoteSC);
  final _moreSCK = ShowCaseKey(FirstAccess.editMoreSC);
  final _removeLabelSCK = ShowCaseKey(FirstAccess.editRemoveLabelSC);

  @override
  void initState() {
    WidgetsBinding.instance.addObserver(this); //For didChangeAppLifecycleState()

    var selectedNoteIndex = widget.notes.indexWhere((e) => e.id == widget.selectedNoteId);
    _editors = List.filled(widget.notes.length, null);
    _currentEditor = _getEditor(selectedNoteIndex);
    _pageController = PageController(initialPage: selectedNoteIndex);
    _configBarSCPageIndex = selectedNoteIndex;

    _isNewNote = _currentEditor.note.id == 0;

    if (!_isNewNote) {
      _heroTag = 'noteHero_${_currentEditor.note.id}';
    }

    _showCaseKeys = [_configBarSCK, _backSCK, _favoriteSCK, _labelNoteSCK, _moreSCK];
    if (_currentEditor.note.labelIds.isNotEmpty) {
      _showCaseKeys.add(_removeLabelSCK);
      _removeLabelSCPageIndex = selectedNoteIndex;
    }

    _setHistoryManagerList();

    if (!CustomShowCase.startShowCase(
      context: context,
      showCaseKeys: _showCaseKeys,
      usePostFrameCallback: true,
      onFinish: () {
        setState(() {
          _showCaseFinished = true;
        }); //Updates the widgets who uses _showCaseFinished value.
      },
    )) {
      _showCaseFinished = true;
    }

    AppData.validateTimeInTrash(); //Also executed here because user will be opening/creating notes very often.

    super.initState();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    for (var editor in _editors) {
      editor?.textController.dispose();
    }
    super.dispose();
  }

  //Used by WidgetsBinding.instance.addObserver(this) with WidgetsBindingObserver
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed) {
      _saveDraft(_currentEditor);
    }
    super.didChangeAppLifecycleState(state);
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) => _onPopInvoked(didPop, context),
      child: AbsorbPointer(
        absorbing: _closing,
        child: Scaffold(
          appBar: AppBar(
            title: Text('${_isNewNote ? 'New' : 'Edit'} Note'),
            leading: _backButton(),
            actions: [
              _favoriteButton(),
              _labelNoteButton(),
              _moreButton(),
            ],
          ),
          body: PageView.builder(
            physics: !_showCaseFinished ? NeverScrollableScrollPhysics() : null,
            controller: _pageController,
            onPageChanged: (index) {
              _saveNote(_currentEditor);
              var currentEditor = _getEditor(index);
              setState(() {
                _currentEditor = currentEditor;
              });
              _setHistoryManagerList();
            },
            itemCount: widget.notes.length,
            itemBuilder: (context, index) {
              var editor = _getEditor(index);
              return SafeArea(
                key: Key('edt_$index'),
                child: Column(
                  children: [
                    index == _configBarSCPageIndex
                        ? CustomShowCase(
                            showCaseKey: _configBarSCK,
                            description: 'You can tap on this\nzone to set a color\nto your note.',
                            child: _configBar(editor),
                          )
                        : _configBar(editor),
                    const Divider(height: 0.0),
                    _textField(editor),
                    index == _removeLabelSCPageIndex
                        ? CustomShowCase(
                            showCaseKey: _removeLabelSCK,
                            description: 'You can long-press\na label to detach it\nfrom your note.',
                            child: _labels(editor),
                          )
                        : _labels(editor),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _backButton() {
    return CustomShowCase(
      showCaseKey: _backSCK,
      description: 'Tap back to save\nchanges after editing\nyour note.',
      child: SizedBox(
        height: 56.0,
        width: 56.0,
        child: IconButton(
          tooltip: HeaderButtonDetails.back.caption,
          icon: Icon(HeaderButtonDetails.back.icon),
          onPressed: () {
            Navigator.maybePop(context); //Allows to enter to PopScope code
          },
        ),
      ),
    );
  }

  Widget _favoriteButton() {
    return CustomShowCase(
      showCaseKey: _favoriteSCK,
      description: 'You can set your note\nas a favorite. This can\nhelp you when using\nfilters in the main list.',
      child: ValueListenableBuilder(
        valueListenable: _currentEditor.note.favorite,
        builder: (context, favorite, child) {
          return Stack(
            children: [
              AnimatedScaleButton(
                duration: c.animationDuration,
                tooltip: HeaderButtonDetails.favorite.caption,
                icon: Icons.star_border,
                isVisible: !favorite,
                onPressed: () {
                  _currentEditor.note.favorite.value = !favorite;
                  _saveDraft(_currentEditor);
                },
              ),
              AnimatedScaleButton(
                duration: c.animationDuration,
                tooltip: HeaderButtonDetails.favorite.caption,
                icon: HeaderButtonDetails.favorite.icon,
                isVisible: favorite,
                onPressed: () {
                  _currentEditor.note.favorite.value = !favorite;
                  _saveDraft(_currentEditor);
                },
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _labelNoteButton() {
    return CustomShowCase(
      showCaseKey: _labelNoteSCK,
      description: 'You can add labels to\nyour note by tapping\nhere. You can also\nfilter by label in the\nmain list.',
      child: IconButton(
        tooltip: 'Label note',
        icon: const Icon(Icons.label),
        onPressed: () {
          NoteLabelsDialog.show(
            context: context,
            selectedLabelsId: _currentEditor.note.labelIds,
          ).then((value) {
            if (value != null) {
              setState(() {
                _currentEditor.note.labelIds = value;
              });
              _saveDraft(_currentEditor);
              if (_currentEditor.note.labelIds.isNotEmpty && mounted) {
                if (_removeLabelSCPageIndex == -1) {
                  setState(() {
                    _removeLabelSCPageIndex = _editors.indexOf(_currentEditor);
                  });
                  CustomShowCase.startShowCase(
                    context: context,
                    showCaseKeys: [_removeLabelSCK],
                    usePostFrameCallback: false,
                  );
                }
              }
            }
          });
        },
      ),
    );
  }

  Widget _moreButton() {
    return HeaderButtons.moreButton(
      context: context,
      button: HeaderButton(HeaderButtonDetails.more)
        ..showCaseKey = _moreSCK
        ..showCaseDescription = 'Tap here for more\noptions, such as\nviewing your note\'s\nhistory or sending it\nto the trash can.',
      moreButtons: [
        HeaderButton(HeaderButtonDetails.history),
        HeaderButton(HeaderButtonDetails.sendToTrash),
      ],
      onSelected: (selected) {
        if (selected == HeaderButtonDetails.history) {
          _historyPressed();
        } else if (selected == HeaderButtonDetails.sendToTrash) {
          _sendToTrashPressed();
        }
      },
    );
  }

  Widget _configBar(NoteEditor editor) {
    return ValueListenableBuilder(
      valueListenable: editor.note.color,
      builder: (context, color, child) {
        return AnimatedColor(
          color: color ?? Theme.of(context).colorScheme.surface,
          duration: c.animationDuration,
          builder: (animatedColor) {
            //Material allows to set color without removing InkWell splash effect.
            return Material(
              color: animatedColor,
              child: InkWell(
                onTap: () {
                  StyleColorPickerDialog.show(
                      context: context,
                      pickerColor: color,
                      onColorChanged: (value) {
                        editor.note.color.value = value != Colors.transparent ? value : null;
                        _saveDraft(editor);
                      });
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 5.0),
                  child: Row(
                    children: [
                      const Spacer(),
                      Text(
                        AppData.settings[Settings.useCreationDateTime]!.value == true.toString()
                            ? editor.note.localeFormatCreationDateTime
                            : editor.note.localeFormatModifDateTime,
                        style: TextStyle(color: editor.note.foregroundColor(context)),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _textField(NoteEditor editor) {
    Widget result = LandscapeTextField(
      controller: editor.textController,
      textFieldBuilder: (controller, focusNode, readOnly) {
        return TextField(
          showCursor: true,
          readOnly: readOnly,
          focusNode: focusNode,
          controller: controller,
          maxLines: null,
          expands: true,
          keyboardType: TextInputType.multiline,
          autofocus: _showCaseKeys.every((e) => AppData.firstAccesses[e.value]!) && _isNewNote,
          decoration: InputDecoration(
            border: InputBorder.none,
            contentPadding: EdgeInsets.zero, //Required to correct hero animation.
            hintText: 'Enter your note',
            hintStyle: TextStyle(
              fontSize: 18.0,
              fontWeight: FontWeight.w500,
              letterSpacing: 0.5,
              wordSpacing: 1.5,
              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.35),
            ),
          ),
          onChanged: (value) {
            editor.note.text = value;
            _saveDraft(editor);
          },
        );
      },
    );
    if (_heroTag != null && editor == _currentEditor) {
      result = Hero(
        tag: _heroTag!,
        child: result,
      );
    }
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(10.0, 5.0, 10.0, 0.0),
        child: result,
      ),
    );
  }

  Widget _labels(NoteEditor editor) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(15.0, 10.0, 12.0, 10.0),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Wrap(
          spacing: 15.0,
          runSpacing: 10.0,
          children: AppData.labels.where((e) => editor.note.labelIds.contains(e.id)).map((e) {
            return LabelContainer(
              onLongPress: () {
                ConfirmationDialog.show(
                  context: context,
                  caption: 'Do you want to detach label "${e.text}" from your note?',
                  confirmOption: 'Detach',
                  confirmOptionIcon: Icons.label_off,
                  dontShowAgainChecked: AppData.settings[Settings.hideDetachLabelDialog]!.value == true.toString(),
                  setDontShowAgain: () {
                    AppData.settings[Settings.hideDetachLabelDialog]!.value = true.toString();
                    AppData.updateDbSettings([Settings.hideDetachLabelDialog]);
                  },
                ).then((value) {
                  if (value) {
                    setState(() {
                      editor.note.labelIds.remove(e.id);
                    });
                    _saveDraft(editor);
                  }
                });
              },
              content: Text(
                e.text,
                maxLines: 1,
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onPrimary,
                  fontSize: Theme.of(context).textTheme.bodySmall?.fontSize,
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  void _onPopInvoked(bool didPop, BuildContext context) async {
    if (!_closing && !didPop && !CustomShowCase.next(context)) {
      a.runFirst(() async {
        setState(() {
          _closing = true;
        });
        if (_isNewNote && _currentEditor.note.text.trim().isEmpty) {
          Navigator.pop(context);
        } else {
          if (_isNewNote) {
            if ((await AppData.newNoteFromEdit(_currentEditor.note)) > 0) {
              setState(() {
                _heroTag = 'noteHero_${_currentEditor.note.id}';
              });
            }
          } else {
            var sendToTrash = _currentEditor.note.text.trim().isEmpty;
            _saveNote(_currentEditor);
            _sendEmptyToTrash();
            if (!sendToTrash) {
              setState(() {
                _heroTag = 'noteHero_${_currentEditor.note.id}';
              });
            } else {
              t.showCustomToast('Text is empty. The note was moved to trash.', context);
            }
          }
          _currentEditor.note.performingHero = true;
          AppData.notesManager.displayList.notifyListeners();
          if (context.mounted) {
            Navigator.pop(context);
          }
          //This async code makes the hero to be performed correctly.
          Future.delayed(const Duration(milliseconds: 100), () => _currentEditor.note.performingHero = false);
        }
      });
    }
  }

  void _saveNote(NoteEditor editor) async {
    if (editor.note.text.trim().isNotEmpty) {
      editor.draftSaver.cancelRunLast();
      if (editor.note.text != editor.unmodifiedNote.text ||
          editor.note.color.value != editor.unmodifiedNote.color.value ||
          editor.note.favorite.value != editor.unmodifiedNote.favorite.value ||
          editor.note.labelIds.join(',') != editor.unmodifiedNote.labelIds.join(',')) {
        editor.note.modifDateTime = DateTime.now();
        if (!editor.note.guiManager.noteIsInFilter(editor.note)) {
          editor.note.guiManager.displayList.value!.remove(editor.note);
        }
        AppData.updateHomeWidget();
      }
      var unmodifiedNote = editor.unmodifiedNote;
      editor.unmodifiedNote = editor.note.clone();
      while (editor.savingDraft) {
        await Future.delayed(const Duration(milliseconds: 10));
      }
      AppData.updateDbNoteFromEdit(editor.note, unmodifiedNote);
    } else {
      AppData.updateHomeWidget();
    }
    editor.draftId = null;
  }

  void _saveDraft(NoteEditor editor) async {
    editor.draftSaver.runLast(500, () async {
      editor.savingDraft = true;
      if (editor.draftId != null && editor.draftId! > 0) {
        await AppData.updateDbNoteFromEdit(editor.note, null, editor.draftId);
      } else {
        editor.draftId = await AppData.newNoteFromEdit(editor.note, true);
      }
      editor.savingDraft = false;
    });
  }

  void _sendToTrashPressed() {
    if (_isNewNote && _currentEditor.note.text.trim().isEmpty) {
      Navigator.pop(context);
    } else {
      a.runFirst(() async {
        var sendToTrash = await ConfirmationDialog.show(
          context: context,
          caption: 'Do you want to send the note to trash?',
          confirmOption: 'Send to trash',
          confirmOptionIcon: Icons.delete,
          dontShowAgainChecked: AppData.settings[Settings.hideSendToTrashDialog]!.value == true.toString(),
          setDontShowAgain: () {
            AppData.settings[Settings.hideSendToTrashDialog]!.value = true.toString();
            AppData.updateDbSettings([Settings.hideSendToTrashDialog]);
          },
        );
        if (sendToTrash) {
          setState(() {
            _closing = true;
          });
          if (_isNewNote) {
            sendToTrash = await AppData.newNoteFromEdit(_currentEditor.note) > 0;
          } else {
            if (_currentEditor.note.text.trim().isEmpty) {
              _currentEditor.note.text = _currentEditor.unmodifiedNote.text;
            }
            _saveNote(_currentEditor);
          }
          if (mounted) {
            if (sendToTrash) {
              _sendEmptyToTrash(editorForcedToTrash: _currentEditor);
              AppData.notesManager.displayList.notifyListeners();
              t.showCustomToast('Note sent to trash.', context);
            }
            Navigator.pop(context);
          }
        }
      });
    }
  }

  void _sendEmptyToTrash({NoteEditor? editorForcedToTrash}) {
    var editorsToDelete = _editors.where((e) => e != null && e.note.text.trim().isEmpty).toList();
    for (var editor in editorsToDelete) {
      editor!.note.text = editor.unmodifiedNote.text;
    }
    if (editorForcedToTrash != null) {
      if (!editorsToDelete.contains(editorForcedToTrash)) {
        editorsToDelete.add(editorForcedToTrash);
      }
    }
    if (editorsToDelete.isNotEmpty) {
      AppData.sendNotesToTrash(editorsToDelete.map((e) => e!.note).toList());
    }
  }

  void _historyPressed() {
    HistoryBottomSheet.show(
      context: context,
      historyManager: historyManager,
    ).then((value) {
      historyManager.selectionQuantity.value = null;
      if (value == true) {
        _currentEditor.unmodifiedNote = _currentEditor.note.clone();
        setState(() {
          _currentEditor.textController.text = _currentEditor.note.text;
        });
      }
    });
  }

  NoteEditor _getEditor(int index) {
    var editor = _editors[index];
    if (editor == null) {
      var currentNote = widget.notes[index];
      editor = NoteEditor(
        note: currentNote,
        unmodifiedNote: currentNote.clone(),
        textController: TextEditingController()..text = currentNote.text,
        draftSaver: a.SingleAsync(),
      );
      _editors[index] = editor;
    }
    return editor;
  }

  //This starts loading the history to have it ready before opening the history bottom sheet.
  void _setHistoryManagerList() async {
    if (_isNewNote) {
      historyManager.displayList.value = [];
    } else {
      historyManager.allList = await AppData.queryNotes(
        guiManager: historyManager,
        where: 'parent_id = ${_currentEditor.note.id} AND history_date_time IS NOT NULL',
      );
      historyManager.displayList.value = List.of(historyManager.allList);
    }
  }
}
