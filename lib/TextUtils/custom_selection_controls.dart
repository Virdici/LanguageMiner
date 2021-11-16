import 'dart:async';

import 'package:android_intent/android_intent.dart';
import 'package:extended_text/extended_text.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:language_miner/Controllers/dictController.dart';
import 'package:language_miner/Controllers/wordController.dart';

const double _kHandleSize = 22;
const double _kToolbarContentDistanceBelow = _kHandleSize - 2.0;
const double _kToolbarContentDistance = 8.0;
TextEditingController textFieldController = new TextEditingController();

String selectedText = '';
String selectedTextModal = '';
String clipboard = '';

class CustomTextSelectionControls extends TextSelectionControls {
  bool modal = false;

  CustomTextSelectionControls({required this.modal});
  // String selectedText = '';
  String selectedWord = '';
  String selectedTextModal = '';

  String selectedSentence = 'penis';
  late List<Map<dynamic, dynamic>> dictTerms;
  late Timer _timer;
  int currentPosition = 0;
  @override
  Widget buildHandle(
      BuildContext context, TextSelectionHandleType type, double textLineHeight,
      [VoidCallback? onTap, double? startGlyphHeight, double? endGlyphHeight]) {
    const Widget handle = SizedBox(
        width: _kHandleSize,
        height: _kHandleSize,
        child: Icon(
          Icons.circle,
          color: Colors.blue,
          size: 32,
        ));

    switch (type) {
      case TextSelectionHandleType.left: // points up-right
        return handle;
      case TextSelectionHandleType.right: // points up-left
        return handle;
      case TextSelectionHandleType.collapsed: // points up
        return handle;
    }
  }

  @override
  Size getHandleSize(double textLineHeight) =>
      const Size(_kHandleSize, _kHandleSize);

  @override
  Offset getHandleAnchor(TextSelectionHandleType type, double textLineHeight,
      [double? startGlyphHeight, double? endGlyphHeight]) {
    switch (type) {
      case TextSelectionHandleType.left:
        return const Offset(_kHandleSize, 0);
      case TextSelectionHandleType.right:
        return const Offset(_kHandleSize - 12, 0);
      default:
        return const Offset(_kHandleSize / 2, -4);
    }
  }

  void handleTranslate(TextSelectionDelegate delegate) async {
    selectedText = delegate.textEditingValue.text.substring(
        delegate.textEditingValue.selection.start,
        delegate.textEditingValue.selection.end);
    if (modal == true) {
      selectedTextModal = selectedText;
    }
    final AndroidIntent intent = AndroidIntent(
      action: 'android.intent.action.TRANSLATE',
      arguments: {
        'android.intent.extra.PROCESS_TEXT': selectedText,
      },
    );
    intent.launch();
    delegate.hideToolbar();
    delegate.userUpdateTextEditingValue(
        delegate.textEditingValue
            .copyWith(selection: const TextSelection.collapsed(offset: 0)),
        SelectionChangedCause.toolBar);
  }

  void handleMine(TextSelectionDelegate delegate, BuildContext context) {
    String highlightedText = delegate.textEditingValue.text.substring(
        delegate.textEditingValue.selection.start,
        delegate.textEditingValue.selection.end);

    selectedText = highlightedText;

    modalMiner(context, selectedText);

    delegate.hideToolbar();
    delegate.userUpdateTextEditingValue(
        delegate.textEditingValue
            .copyWith(selection: const TextSelection.collapsed(offset: 0)),
        SelectionChangedCause.toolBar);
  }

  void handleAddWord(
      TextSelectionDelegate delegate, BuildContext context) async {
    String selectedText = delegate.textEditingValue.text.substring(
        delegate.textEditingValue.selection.start,
        delegate.textEditingValue.selection.end);

    selectedWord = selectedText;
    dictTerms = await DictController.getTerm(selectedWord);
    modalDefinitions(context, dictTerms, selectedWord);

    delegate.hideToolbar();
    delegate.userUpdateTextEditingValue(
        delegate.textEditingValue
            .copyWith(selection: const TextSelection.collapsed(offset: 0)),
        SelectionChangedCause.toolBar);
  }

  @override
  Widget buildToolbar(
    BuildContext context,
    Rect globalEditableRegion,
    double textLineHeight,
    // ignore: avoid_renaming_method_parameters
    Offset selectionMidpoint,
    List<TextSelectionPoint> endpoints,
    TextSelectionDelegate delegate,
    ClipboardStatusNotifier clipboardStatus,
    Offset? lastSecondaryTapDownPosition,
  ) {
    // print('new LINE WWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWW');
    // print(selectionMidpoint.dx);
    // print(selectionMidpoint.dy);
    // print(delegate.textEditingValue.selection.start);
    currentPosition = delegate.textEditingValue.selection.start;
    // print(currentPosition);
    return _TextSelectionControlsToolbar(
      modal: modal,
      globalEditableRegion: globalEditableRegion,
      textLineHeight: textLineHeight,
      selectionMidpoint: selectionMidpoint,
      endpoints: endpoints,
      delegate: delegate,
      clipboardStatus: clipboardStatus,
      handleCut: canCut(delegate) ? () => handleCut(delegate) : null,
      handleCopy: canCopy(delegate)
          ? () => handleCopy(delegate, clipboardStatus)
          : null,
      handlePaste: canPaste(delegate) ? () => handlePaste(delegate) : null,
      handleSelectAll:
          canSelectAll(delegate) ? () => handleSelectAll(delegate) : null,
      handleTranslate: () => handleTranslate(delegate),
      handleMine: () => handleMine(delegate, context),
      handleAddWord: () => handleAddWord(delegate, context),
    );
  }

  Future modalMiner(BuildContext context, String selectedText) async {
    checkClipboard();
    CustomTextSelectionControls modalSelectionControls =
        new CustomTextSelectionControls(modal: true);
    return showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        builder: (BuildContext context) {
          return Container(
            color: Colors.grey[900],
            child: Padding(
              padding: EdgeInsets.only(
                  bottom: MediaQuery.of(context).viewInsets.bottom),
              child: Padding(
                padding: const EdgeInsets.all(18.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    ExtendedText(
                      selectedText,
                      selectionEnabled: true,
                      selectionControls: modalSelectionControls,
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          fontFamily: 'LouisGeorgeCafe'),
                    ),
                    SizedBox(height: 12),
                    Container(
                      child: TextFormField(
                        // initialValue: clipboard,
                        maxLines: null,
                        onTap: () {
                          _timer.cancel();
                        },
                        controller: textFieldController,
                        style: TextStyle(color: Colors.white, fontSize: 18),
                        decoration: InputDecoration(
                          fillColor: Colors.grey[800],
                          filled: true,
                          focusedBorder: OutlineInputBorder(
                            borderSide: const BorderSide(
                                color: Colors.white, width: 2.0),
                            borderRadius: BorderRadius.circular(5.0),
                          ),
                        ),
                      ),
                    ),
                    TextButton(
                        onPressed: () {
                          WordController.addWord(
                              modalSelectionControls.selectedTextModal,
                              selectedWord,
                              selectedText,
                              '[sound:${selectedWord + selectedText.split(' ').first}.mp3]');
                          Navigator.of(context)..pop();
                        },
                        child: Container(child: Text('Add')))
                  ],
                ),
              ),
            ),
          );
        }).then((value) => _timer.cancel());
  }

  Future modalDefinitions(BuildContext context,
      List<Map<dynamic, dynamic>> definitions, String word) {
    return showModalBottomSheet<void>(
        context: context,
        builder: (BuildContext context) {
          return SingleChildScrollView(
            child: Container(
              color: Colors.grey[900],
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Text(
                      word,
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          fontFamily: 'LouisGeorgeCafe'),
                    ),
                  ),
                  for (var i = 0; i < definitions.length; i++)
                    definitionCard(context, definitions[i])
                ],
              ),
            ),
          );
        });
  }

  Widget definitionCard(
      BuildContext context, Map<dynamic, dynamic> definition) {
    String definitionFormated =
        definition['definition'].toString().replaceAll('<br>', '');
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 8, 8, 8),
      child: GestureDetector(
          child: Card(
            color: Colors.green,
            child: Align(
              alignment: Alignment.centerLeft,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(18, 8, 18, 8),
                child: Text(
                  definitionFormated,
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'LouisGeorgeCafe'),
                ),
              ),
            ),
          ),
          onTap: () {
            WordController.addWord(
                selectedWord,
                definitionFormated,
                selectedText,
                '[sound:${selectedWord + selectedText.split(' ').first}.mp3]');
            Navigator.of(context)
              ..pop()
              ..pop();
          }),
    );
  }

  void checkClipboard() {
    //nie porządane, nie da się ręcznie zmieniać po wprowadzeniu wartości z g translate
    _timer = Timer.periodic(Duration(milliseconds: 50), (Timer t) async {
      ClipboardData? data = await Clipboard.getData(Clipboard.kTextPlain);
      if (data != null) {
        textFieldController.text = data.text!;

        selectedWord = textFieldController.text;
      }
    });
  }
}

class _TextSelectionControlsToolbar extends StatefulWidget {
  const _TextSelectionControlsToolbar({
    Key? key,
    required this.modal,
    required this.clipboardStatus,
    required this.delegate,
    required this.endpoints,
    required this.globalEditableRegion,
    required this.handleCut,
    required this.handleCopy,
    required this.handlePaste,
    required this.handleSelectAll,
    required this.selectionMidpoint,
    required this.textLineHeight,
    required this.handleTranslate,
    required this.handleMine,
    required this.handleAddWord,
  }) : super(key: key);

  final bool modal;
  final ClipboardStatusNotifier clipboardStatus;
  final TextSelectionDelegate delegate;
  final List<TextSelectionPoint> endpoints;
  final Rect globalEditableRegion;
  final VoidCallback? handleCut;
  final VoidCallback? handleCopy;
  final VoidCallback? handlePaste;
  final VoidCallback? handleSelectAll;
  final VoidCallback handleTranslate;
  final VoidCallback handleMine;
  final VoidCallback handleAddWord;
  final Offset selectionMidpoint;
  final double textLineHeight;

  @override
  _TextSelectionControlsToolbarState createState() =>
      _TextSelectionControlsToolbarState();
}

class _TextSelectionControlsToolbarState
    extends State<_TextSelectionControlsToolbar> with TickerProviderStateMixin {
  void _onChangedClipboardStatus() {
    setState(() {
      // Inform the widget that the value of clipboardStatus has changed.
    });
  }

  @override
  void initState() {
    super.initState();
    widget.clipboardStatus.addListener(_onChangedClipboardStatus);
    widget.clipboardStatus.update();
  }

  @override
  void didUpdateWidget(_TextSelectionControlsToolbar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.clipboardStatus != oldWidget.clipboardStatus) {
      widget.clipboardStatus.addListener(_onChangedClipboardStatus);
      oldWidget.clipboardStatus.removeListener(_onChangedClipboardStatus);
    }
    widget.clipboardStatus.update();
  }

  @override
  void dispose() {
    super.dispose();
    // When used in an Overlay, it can happen that this is disposed after its
    // creator has already disposed _clipboardStatus.
    if (!widget.clipboardStatus.disposed) {
      widget.clipboardStatus.removeListener(_onChangedClipboardStatus);
    }
  }

  @override
  Widget build(BuildContext context) {
    // If there are no buttons to be shown, don't render anything.
    if (widget.handleCut == null &&
        widget.handleCopy == null &&
        widget.handlePaste == null &&
        widget.handleSelectAll == null) {
      return const SizedBox.shrink();
    }
    // If the paste button is desired, don't render anything until the state of
    // the clipboard is known, since it's used to determine if paste is shown.
    if (widget.handlePaste != null &&
        widget.clipboardStatus.value == ClipboardStatus.unknown) {
      return const SizedBox.shrink();
    }

    // Calculate the positioning of the menu. It is placed above the selection
    // if there is enough room, or otherwise below.
    final TextSelectionPoint startTextSelectionPoint = widget.endpoints[0];
    final TextSelectionPoint endTextSelectionPoint =
        widget.endpoints.length > 1 ? widget.endpoints[1] : widget.endpoints[0];
    final Offset anchorAbove = Offset(
        widget.globalEditableRegion.left + widget.selectionMidpoint.dx,
        widget.globalEditableRegion.top +
            startTextSelectionPoint.point.dy -
            widget.textLineHeight -
            _kToolbarContentDistance);
    final Offset anchorBelow = Offset(
      widget.globalEditableRegion.left + widget.selectionMidpoint.dx,
      widget.globalEditableRegion.top +
          endTextSelectionPoint.point.dy +
          _kToolbarContentDistanceBelow,
    );

    // Determine which buttons will appear so that the order and total number is
    // known. A button's position in the menu can slightly affect its
    // appearance.
    assert(debugCheckHasMaterialLocalizations(context));
    final MaterialLocalizations localizations =
        MaterialLocalizations.of(context);
    final List<_TextSelectionToolbarItemData> itemDatas =
        <_TextSelectionToolbarItemData>[
      if (widget.handleCut != null)
        _TextSelectionToolbarItemData(
          label: localizations.cutButtonLabel,
          onPressed: widget.handleCut,
        ),
      if (widget.handleCopy != null && widget.modal == false)
        _TextSelectionToolbarItemData(
          label: localizations.copyButtonLabel,
          onPressed: widget.handleCopy,
        ),
      if (widget.handlePaste != null &&
          widget.clipboardStatus.value == ClipboardStatus.pasteable)
        _TextSelectionToolbarItemData(
          label: localizations.pasteButtonLabel,
          onPressed: widget.handlePaste,
        ),
      if (widget.handleSelectAll != null)
        _TextSelectionToolbarItemData(
          label: localizations.selectAllButtonLabel,
          onPressed: widget.handleSelectAll,
        ),
      _TextSelectionToolbarItemData(
        label: 'Translate',
        onPressed: widget.handleTranslate,
      ),
      if (widget.modal == false)
        _TextSelectionToolbarItemData(
          label: 'Mine',
          onPressed: widget.handleMine,
        ),
      if (widget.modal == true)
        _TextSelectionToolbarItemData(
          label: 'add word',
          onPressed: widget.handleAddWord,
        ),
    ];

    // If there is no option available, build an empty widget.
    if (itemDatas.isEmpty) {
      return const SizedBox(width: 0.0, height: 0.0);
    }

    return TextSelectionToolbar(
      anchorAbove: anchorAbove,
      anchorBelow: anchorBelow,
      children: itemDatas
          .asMap()
          .entries
          .map((MapEntry<int, _TextSelectionToolbarItemData> entry) {
        return TextSelectionToolbarTextButton(
          padding: TextSelectionToolbarTextButton.getPadding(
              entry.key, itemDatas.length),
          onPressed: entry.value.onPressed,
          child: Text(entry.value.label),
        );
      }).toList(),
    );
  }
}

// The label and callback for the available default text selection menu buttons.
class _TextSelectionToolbarItemData {
  const _TextSelectionToolbarItemData({
    required this.label,
    required this.onPressed,
  });

  final String label;
  final VoidCallback? onPressed;
}
