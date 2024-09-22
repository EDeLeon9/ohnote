import 'package:flutter/material.dart';
import 'package:ohnote/data/app_data.dart';
import 'package:ohnote/data/filters.dart';
import 'package:ohnote/data/gui_manager.dart';
import 'package:ohnote/tools/landscape_textfield.dart';
import 'package:ohnote/tools/single_async.dart';
import 'dart:math' as math;
import 'package:ohnote/constants.dart' as c;

class FiltersPanel extends StatefulWidget {
  const FiltersPanel({
    super.key,
    required this.guiManager,
    this.updateDbFilters = false,
    this.useFilterChips = true,
  });

  final GuiManager guiManager;
  final bool updateDbFilters;
  final bool useFilterChips;

  @override
  State<FiltersPanel> createState() => _FiltersPanelState();
}

class _FiltersPanelState extends State<FiltersPanel> {
  bool _showContainerDecoration = false;
  final _searchTextController = TextEditingController();
  final SingleAsync _updateDbFiltersAsync = SingleAsync();

  @override
  void initState() {
    _searchTextController.text = widget.guiManager.filters.value.text;
    widget.guiManager.filters.removeListener(_setFilterText);
    widget.guiManager.filters.addListener(_setFilterText);
    super.initState();
  }

  @override
  void dispose() {
    widget.guiManager.filters.removeListener(_setFilterText);
    super.dispose();
  }

  void _setFilterText() {
    if (_searchTextController.text != widget.guiManager.filters.value.text) {
      _searchTextController.text = widget.guiManager.filters.value.text;
    }
    //widget.guiManager.showSearchText is not being set to false because maybe another filter is being clear, even with text in ''
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder(
      valueListenable: widget.guiManager.filters,
      builder: (context, filters, child) {
        return ValueListenableBuilder(
          valueListenable: widget.guiManager.showSearchText,
          builder: (context, showSearchText, child) {
            bool filtersHasApplied = filters.hasApplied();
            if (filtersHasApplied || showSearchText) {
              _showContainerDecoration = true;
            } else if (_showContainerDecoration) {
              //Future is used because there is no onEnd property in AnimatedSize.
              Future.delayed(c.animationDuration, () {
                setState(() {
                  _showContainerDecoration = false;
                });
              });
            }
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              verticalDirection: VerticalDirection.up,
              children: [
                Container(
                  decoration: _showContainerDecoration
                      ? BoxDecoration(
                          //outlineVariant is used by Dividers.
                          border: Border(bottom: BorderSide(color: Theme.of(context).colorScheme.outlineVariant)),
                          boxShadow: [
                            BoxShadow(
                              blurRadius: 3.5,
                              spreadRadius: 1.0,
                              offset: const Offset(0.0, -2.0),
                              color: Theme.of(context).colorScheme.shadow.withOpacity(0.5),
                            ),
                          ],
                          color: Theme.of(context).colorScheme.tertiaryContainer,
                        )
                      : null,
                ),
                Container(
                  color: Theme.of(context).colorScheme.tertiaryContainer,
                  child: AnimatedSize(
                    duration: c.animationDuration,
                    child: Padding(
                      padding: EdgeInsets.symmetric(horizontal: 15.0, vertical: filtersHasApplied || showSearchText ? 2.5 : 0.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          widget.useFilterChips
                              ? Wrap(
                                  runSpacing: -3.0,
                                  spacing: 10.0,
                                  children: filters.getAppliedCaptions().map((e) {
                                    return InputChip(
                                      tooltip: 'Delete',
                                      deleteButtonTooltipMessage: 'Delete',
                                      clipBehavior: Clip.antiAlias, //Fix for "x" button splash effect bug.
                                      visualDensity: const VisualDensity(vertical: -2.0),
                                      label: Text(e, style: Theme.of(context).textTheme.bodySmall),
                                      onPressed: () => _removeFilter(filters, e),
                                      onDeleted: () => _removeFilter(filters, e),
                                    );
                                  }).toList(),
                                )
                              : const SizedBox.shrink(),
                          showSearchText
                              ? Padding(
                                  padding: const EdgeInsets.symmetric(vertical: 0.0),
                                  child: Row(
                                    children: [
                                      Text('Search: ', style: Theme.of(context).textTheme.bodyLarge),
                                      Expanded(
                                        child: LandscapeTextField(
                                          controller: _searchTextController,
                                          focusNode: widget.guiManager.searchTextFocusNode,
                                          textFieldBuilder: (controller, focusNode, readOnly) {
                                            return TextField(
                                              showCursor: true,
                                              controller: controller,
                                              focusNode: focusNode,
                                              readOnly: readOnly,
                                              style: Theme.of(context).textTheme.bodyMedium,
                                              decoration: const InputDecoration(
                                                isDense: true,
                                                contentPadding: EdgeInsets.symmetric(horizontal: 10.0, vertical: 8.0),
                                                border: OutlineInputBorder(),
                                              ),
                                              onChanged: (value) {
                                                if (widget.guiManager.filters.value.text != value) {
                                                  widget.guiManager.filters.value.text = value;
                                                  widget.guiManager.filters.notifyListeners();
                                                  if (widget.updateDbFilters) {
                                                    _updateDbFiltersAsync.runLast(750, () {
                                                      AppData.updateDbFilters();
                                                    });
                                                  }
                                                }
                                              },
                                            );
                                          },
                                        ),
                                      ),
                                      IconButton(
                                        style: const ButtonStyle(padding: WidgetStatePropertyAll(EdgeInsets.symmetric(horizontal: 5.0))),
                                        tooltip: widget.useFilterChips ? 'Close' : 'Clear',
                                        visualDensity: const VisualDensity(horizontal: -4.0, vertical: -1.5),
                                        icon: widget.useFilterChips
                                            ? Transform.rotate(
                                                angle: (180.0 * math.pi) / 180.0,
                                                child: Icon(Icons.arrow_drop_down_circle, color: Theme.of(context).colorScheme.primary),
                                              )
                                            : Icon(Icons.cancel, color: Theme.of(context).colorScheme.primary),
                                        onPressed: () {
                                          widget.guiManager.showSearchText.value = false;
                                          if (!widget.useFilterChips) {
                                            widget.guiManager.filters.value.text = '';
                                            widget.guiManager.filters.notifyListeners();
                                          }
                                        },
                                      ),
                                    ],
                                  ),
                                )
                              : const SizedBox.shrink(),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _removeFilter(Filters filters, String filterCaption) {
    switch (filterCaption) {
      case Filters.FAVORITES:
        filters.favorites = false;
        break;
      case Filters.BY_DATE:
        filters.from = null;
        filters.to = null;
        break;
      case Filters.BY_TEXT:
        filters.text = '';
        widget.guiManager.showSearchText.value = false;
        break;
      case Filters.BY_LABEL:
        filters.labelIds.clear();
        break;
      case Filters.BY_COLOR:
        filters.colors.clear();
        break;
      case Filters.CROSSED_OUT:
        filters.crossedOut = false;
        break;
    }
    widget.guiManager.filters.notifyListeners();
    if (widget.updateDbFilters) {
      AppData.updateDbFilters();
    }
  }
}
