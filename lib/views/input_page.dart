import 'package:flutter/material.dart';
import 'package:ohnote/data/first_access.dart';
import 'package:ohnote/data/app_data.dart';
import 'package:ohnote/data/gui_manager.dart';
import 'package:ohnote/data/note.dart';
import 'package:ohnote/data/settings.dart';
import 'package:ohnote/tools/animated/animated_color.dart';
import 'package:ohnote/tools/animated/animatedscale_button.dart';
import 'package:ohnote/tools/custom_showcase.dart';
import 'package:ohnote/tools/landscape_textfield.dart';
import 'package:ohnote/view_components/header_buttons.dart';
import 'package:ohnote/view_components/label_container.dart';
import 'package:ohnote/views/dialogs/label_note_dialog.dart';
import 'package:ohnote/views/dialogs/style_colorpicker_dialog.dart';
import 'package:ohnote/tools/comfirmation_dialog.dart';
import 'package:ohnote/views/bottomsheets/history_bottomsheet.dart';
import 'package:ohnote/constants.dart' as c;
import 'package:ohnote/tools/custom_toast.dart' as t;
import 'package:ohnote/tools/single_async.dart' as a;

class InputPage extends StatefulWidget {
  const InputPage({super.key, required this.note});

  final Note note;

  @override
  State<InputPage> createState() => _InputPageState();
}

class _InputPageState extends State<InputPage> with WidgetsBindingObserver {
  String? _heroTag;
  int? _draftId;
  late final bool _isNewNote;
  late String _oldText;
  late Color? _oldColor;
  final _textController = TextEditingController();
  final _autoSaver = a.SingleAsync();
  final GuiManager historyManager = GuiManager(
    sortComparison: (a, b) => b.historyDateTime!.compareTo(a.historyDateTime!),
    getComparisonDateTime: (note) => note.modifDateTime,
  );
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

    _isNewNote = widget.note.id == 0;
    _oldText = widget.note.text;
    _oldColor = widget.note.color.value;
    _textController.text = widget.note.text;

    if (!_isNewNote) {
      _heroTag = 'noteHero_${widget.note.id}';
    }

    _showCaseKeys = [_configBarSCK, _backSCK, _favoriteSCK, _labelNoteSCK, _moreSCK];
    if (widget.note.labelIds.isNotEmpty) {
      _showCaseKeys.add(_removeLabelSCK);
    }
    CustomShowCase.startShowCase(
      context: context,
      showCaseKeys: _showCaseKeys,
      usePostFrameCallback: true,
      onFinish: () {
        setState(() {}); //Updates the widgets who uses CustomShowCase.finished value.
      },
    );

    _setHistoryManagerList();

    AppData.validateTimeInTrash(); //Also executed here because user will be opening/creating notes very often.

    super.initState();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _textController.dispose();
    super.dispose();
  }

  //Used by WidgetsBinding.instance.addObserver(this) with WidgetsBindingObserver
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed && _draftId != null) {
      _saveDraft();
    }
    super.didChangeAppLifecycleState(state);
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) => _onPopInvoked(didPop, context),
      child: Scaffold(
        appBar: AppBar(
          title: Text(_isNewNote ? 'New Note' : 'Edit Note'),
          leading: _backButton(),
          actions: [
            _favoriteButton(),
            _labelNoteButton(context),
            _moreButton(),
          ],
        ),
        body: Column(
          children: [
            _configBar(),
            const Divider(height: 0.0),
            _textField(),
            _labels(),
          ],
        ),
      ),
    );
  }

  void _onPopInvoked(bool didPop, BuildContext context) async {
    if (!didPop && !CustomShowCase.next(context)) {
      a.runFirst(() async {
        if (_isNewNote && widget.note.text.trim().isEmpty) {
          Navigator.pop(context);
        } else {
          if (_isNewNote) {
            if ((await AppData.newNoteFromInput(widget.note)) > 0) {
              setState(() {
                _heroTag = 'noteHero_${widget.note.id}';
              });
            }
          } else {
            if (widget.note.text.trim().isNotEmpty) {
              AppData.updateNoteFromInput(widget.note, _oldText, _oldColor);
            } else {
              widget.note.text = _oldText;
              AppData.sendNotesToTrash([widget.note]);
              t.showCustomToast('Text is empty. The note was moved to trash.', context);
            }
          }
          AppData.notesManager.displayList.notifyListeners();
          widget.note.performingHero = true;
          if (context.mounted) {
            Navigator.pop(context);
          }
          //This async code makes the hero to be performed correctly.
          Future.delayed(const Duration(milliseconds: 100), () => widget.note.performingHero = false);
        }
      });
    }
  }

  Widget _backButton() {
    return CustomShowCase(
      showCaseKey: _backSCK,
      description: 'Tap back to save changes\nafter editing your note.',
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
      description: 'You can set your note\nas favorite. This can\nhelp you when using\nfilters in the main list.',
      child: ValueListenableBuilder(
        valueListenable: widget.note.favorite,
        builder: (context, favorite, child) {
          return Stack(
            children: [
              AnimatedScaleButton(
                duration: c.animationDuration,
                tooltip: HeaderButtonDetails.favorite.caption,
                icon: Icons.star_border,
                isVisible: !favorite,
                onPressed: () {
                  widget.note.favorite.value = !favorite;
                  _saveDraft();
                },
              ),
              AnimatedScaleButton(
                duration: c.animationDuration,
                tooltip: HeaderButtonDetails.favorite.caption,
                icon: HeaderButtonDetails.favorite.icon,
                isVisible: favorite,
                onPressed: () {
                  widget.note.favorite.value = !favorite;
                  _saveDraft();
                },
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _labelNoteButton(BuildContext context) {
    return CustomShowCase(
      showCaseKey: _labelNoteSCK,
      description: 'You can add labels to\nyour note by tapping\nhere. You can also\nfilter by label in the\nmain list.',
      child: IconButton(
        tooltip: 'Label note',
        icon: const Icon(Icons.label),
        onPressed: () {
          LabelNoteDialog.show(
            context: context,
            selectedLabelsId: widget.note.labelIds,
          ).then((value) {
            if (value != null) {
              setState(() {
                widget.note.labelIds = value;
              });
              _saveDraft();
              if (widget.note.labelIds.isNotEmpty && context.mounted) {
                CustomShowCase.startShowCase(
                  context: context,
                  showCaseKeys: [_removeLabelSCK],
                  usePostFrameCallback: false,
                );
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
        ..showCaseDescription = 'Tap here to see more\noptions like viewing the\nhistory of your note or\n sending it to trash can.',
      moreButtons: [
        HeaderButton(HeaderButtonDetails.history),
        HeaderButton(HeaderButtonDetails.sendToTrash),
      ],
      onSelected: (selected) {
        if (selected == HeaderButtonDetails.history) {
          _historyPressed();
        } else if (selected == HeaderButtonDetails.sendToTrash) {
          _sendToTrashPressed(context);
        }
      },
    );
  }

  Widget _configBar() {
    return CustomShowCase(
      showCaseKey: _configBarSCK,
      description: 'You can tap this zone to\nset color to your note.',
      child: ValueListenableBuilder(
        valueListenable: widget.note.color,
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
                          widget.note.color.value = value != Colors.transparent ? value : null;
                          _saveDraft();
                        });
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 5.0),
                    child: Row(
                      children: [
                        const Spacer(),
                        Text(
                          AppData.settings[Settings.useCreationDateTime]!.value == true.toString()
                              ? widget.note.localFormatCreationDateTime
                              : widget.note.localFormatModifDateTime,
                          style: TextStyle(color: widget.note.foregroundColor(context)),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  Widget _textField() {
    Widget result = LandscapeTextField(
      controller: _textController,
      textFieldBuilder: (controller, focusNode, readOnly) {
        return TextField(
          maxLines: null,
          expands: true,
          keyboardType: TextInputType.multiline,
          showCursor: true,
          readOnly: readOnly,
          focusNode: focusNode,
          controller: controller,
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
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.35),
            ),
          ),
          onChanged: (value) {
            widget.note.text = value;
            _saveDraft();
          },
        );
      },
    );

    if (_heroTag != null) {
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

  Widget _labels() {
    return CustomShowCase(
      showCaseKey: _removeLabelSCK,
      description: 'You can long-press\na label to detach it\nfrom your note.',
      child: Padding(
        padding: const EdgeInsets.fromLTRB(15.0, 10.0, 12.0, 10.0),
        child: Align(
          alignment: Alignment.centerLeft,
          child: Wrap(
            spacing: 15.0,
            runSpacing: 10.0,
            children: AppData.labels.where((e) => widget.note.labelIds.contains(e.id)).map((e) {
              return LabelContainer(
                padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 6.0),
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
                        widget.note.labelIds.remove(e.id);
                      });
                      _saveDraft();
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
      ),
    );
  }

  void _saveDraft() async {
    _autoSaver.runLast(500, () async {
      if (_draftId != null && _draftId! > 0) {
        await AppData.updateNoteFromInput(widget.note, widget.note.text, widget.note.color.value, _draftId);
      } else {
        _draftId = await AppData.newNoteFromInput(widget.note, true);
      }
    });
  }

  void _historyPressed() {
    HistoryBottomSheet.show(context: context, historyManager: historyManager).then((value) {
      historyManager.selectionQuantity.value = null;
      if (value == true) {
        setState(() {
          _oldText = widget.note.text;
          _oldColor = widget.note.color.value;
          _textController.text = widget.note.text;
        });
      }
    });
  }

  void _sendToTrashPressed(BuildContext context) {
    if (_isNewNote && widget.note.text.trim().isEmpty) {
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
          if (widget.note.text.trim().isEmpty && !_isNewNote) {
            widget.note.text = _oldText;
          }
          bool success = true;
          if (_isNewNote) {
            success = await AppData.newNoteFromInput(widget.note) > 0;
          } else {
            AppData.updateNoteFromInput(widget.note, _oldText, _oldColor);
          }
          if (context.mounted) {
            if (success) {
              AppData.sendNotesToTrash([widget.note]);
              AppData.notesManager.displayList.notifyListeners();
              t.showCustomToast('Note sent to trash.', context);
            }
            Navigator.pop(context);
          }
        }
      });
    }
  }

  //This starts loading the history to have it ready before opening the history bottom sheet.
  void _setHistoryManagerList() async {
    if (_isNewNote) {
      historyManager.displayList.value = [];
    } else {
      historyManager.allList = await AppData.queryNotes(
        guiManager: historyManager,
        where: 'parent_id = ${widget.note.id} AND history_date_time IS NOT NULL',
      );
      historyManager.displayList.value = List.of(historyManager.allList);
    }
  }
}
