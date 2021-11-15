import 'dart:ui';
import 'dart:async';
import 'package:hive/hive.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:android_intent/android_intent.dart';
import 'package:language_miner/Controllers/bookmarkController.dart';
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';
import 'package:text_selection_controls/text_selection_controls.dart';
import 'package:language_miner/Controllers/dictController.dart';
import 'package:language_miner/Controllers/settings.dart';
import 'package:language_miner/Controllers/wordController.dart';
import 'package:language_miner/model/bookmarkModel.dart';
import 'package:language_miner/model/wordModel.dart';
import '../model/textModel.dart';
import 'package:flutter_tts/flutter_tts.dart';

class ReadText extends StatefulWidget {
  final TextModel? text;
  const ReadText({Key? key, this.text}) : super(key: key);

  @override
  _ReadTextState createState() => _ReadTextState();
}

class AlwaysDisabledFocusNode extends FocusNode {
  @override
  bool get hasFocus => false;
}

class _ReadTextState extends State<ReadText> {
  final titleController = TextEditingController();
  final contentsController = TextEditingController();
  late String content;
  late int paragraphId = -1;
  late Box wordsBox;
  late Box bookmarksBox;
  late List<Map<dynamic, dynamic>> dictTerms;
  late String selectedWord;
  late String selectedSentence;
  ScrollController scrollController = new ScrollController();
  double fontSize = 12;
  double paddingSize = 0;
  int scrollPositionIndexed = 0;
  late Settings settings;
  double appBarSize = 50;
  bool isTTsEnabled = true;
  final FlutterTts tts = FlutterTts();
  bool isMenuShown = false;
  String fontName = 'Dayrom';
  double ttsSpeed = 0;
  String clipboardBuffer = '';
  FocusNode focus = new FocusNode();

  late List<BookmarkModel> bookmarks;

  final ItemScrollController itemScrollController = ItemScrollController();
  final ItemPositionsListener itemPositionsListener =
      ItemPositionsListener.create();

  late List<String> paragraphsList = content.split(
      new RegExp(r"(?<!\w\.\w.)(?<![A-Z][a-z]\.)(?<=\.|\?)(\s|[A-Z].*)|\n"));

  Future initwordsBox() async {
    wordsBox = await Hive.openBox<WordModel>('words');
    bookmarksBox = await Hive.openBox<BookmarkModel>('bookmarks');
    bookmarks = bookmarksBox.values
        .cast<BookmarkModel>()
        .where((element) => element.textTitle == widget.text!.title)
        .toList();
  }

  @override
  void initState() {
    super.initState();
    initwordsBox();
    if (widget.text != null) {
      final text = widget.text!;

      titleController.text = text.title;
      contentsController.text = text.contents;
    }
    content = contentsController.text;
    settings = Settings();
    settings.init().then((value) {
      setState(() {
        fontSize = settings.getfontSize();
        paddingSize = settings.getPadding();
        scrollPositionIndexed = settings.getScrollPositionIndexed();
        fontName = settings.getFontFamily();
        isTTsEnabled = settings.getTts();
        ttsSpeed = 0.8;
      });
    });
    tts.setLanguage('de');
    tts.setSpeechRate(0.8);
  }
//RICH
  // @override
  // Widget build(BuildContext context) {
  //   scrollController = ScrollController()
  //     ..addListener(() {
  //       print(scrollController.position.pixels);
  //     });
  //   return Scaffold(
  //     appBar: PreferredSize(
  //       child: appBar(),
  //       preferredSize: Size.fromHeight(appBarSize),
  //     ),
  //     // linia 106 by naprawić jumpy przy zaznaczaniu poprzez przytrzymanie
  //     body: SingleChildScrollView(
  //       child: SelectableText.rich(
  //         TextSpan(text: content),
  //         style: TextStyle(
  //             color: Colors.white,
  //             fontSize: fontSize,
  //             fontWeight: FontWeight.bold,
  //             fontFamily: fontName),
  //         dragStartBehavior: DragStartBehavior.down,
  //         selectionControls: FlutterSelectionControls(
  //           toolBarItems: toolBarItems(),
  //         ),
  //       ),
  //       controller: scrollController,
  //     ),
  //     floatingActionButton: FloatingActionButton(
  //       onPressed: () {},
  //     ),
  //   );
  // }

  @override
  Widget build(BuildContext context) {
    scrollController = ScrollController()
      ..addListener(() {
        print(scrollController.offset);
      });
    return Scaffold(
      appBar: PreferredSize(
        child: appBar(),
        preferredSize: Size.fromHeight(appBarSize),
      ),
      // linia 106 by naprawić jumpy przy zaznaczaniu poprzez przytrzymanie
      body: SingleChildScrollView(
        child: SelectableText(
          content,
          style: TextStyle(
              color: Colors.white,
              fontSize: fontSize,
              fontWeight: FontWeight.bold,
              fontFamily: fontName),
          dragStartBehavior: DragStartBehavior.down,
          selectionControls: FlutterSelectionControls(
            toolBarItems: toolBarItems(),
          ),
        ),
        controller: scrollController,
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {},
      ),
    );
  }

  List<ToolBarItem> toolBarItems() {
    return [
      ToolBarItem(
          item: Text(
            'Copy',
          ),
          itemControl: ToolBarItemControl.copy),
      ToolBarItem(
        item: Text(
          'word',
        ),
        onItemPressed: (String highLightedText, int start, int end) async => {
          selectedWord = highLightedText,
          dictTerms = await DictController.getTerm(highLightedText),
          modalDefinitions(dictTerms, highLightedText),
        },
      ),
      ToolBarItem(
        item: Text(
          'translate',
        ),
        onItemPressed: (String highLightedText, int start, int end) async {
          final AndroidIntent intent = AndroidIntent(
              action: 'android.intent.action.TRANSLATE',
              arguments: {
                'android.intent.extra.PROCESS_TEXT': highLightedText,
              },
              package: 'com.google.android.apps.translate');
          intent.launch();
        },
      ),
    ];
  }

  AppBar appBar() {
    return AppBar(
        title: Text(titleController.text),
        backgroundColor: Colors.grey[900],
        actions: [
          PopupMenuButton(
            icon: Icon(Icons.bookmark),
            color: Colors.grey[850],
            itemBuilder: (context) => [
              bookmarksMenu(),
            ],
          ),
          PopupMenuButton(
            color: Colors.grey[850],
            itemBuilder: (context) => [
              textSizeItem(),
              paddingSizeItem(),
              fontFamilyItem(),
              ttsItem(),
              ttsSpeedItem(),
            ],
          )
        ]);
  }

  PopupMenuItem bookmarksMenu() {
    return PopupMenuItem(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Bookmarks',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                ),
              ),
              IconButton(
                onPressed: () {
                  setState(() {
                    BookmarkController.addBookmark(widget.text!.title,
                        scrollController.position.pixels.toInt());
                    bookmarks.add(BookmarkModel()
                      ..textTitle = widget.text!.title
                      ..sentenceIndex =
                          scrollController.position.pixels.toInt());
                  });
                },
                icon: Icon(
                  Icons.add,
                ),
              )
            ],
          ),
          ValueListenableBuilder<Box<BookmarkModel>>(
            valueListenable: Hive.box<BookmarkModel>('bookmarks').listenable(),
            builder: (context, box, _) {
              final bookmarks = box.values.toList().cast<BookmarkModel>();
              return buildBookmarks(bookmarks);
            },
          )
        ],
      ),
    );
  }

  Widget buildBookmarks(List<BookmarkModel> bookmarks) {
    if (bookmarks.isEmpty) {
      return Center(
        child: Text(
          'No bookmarks here!',
          style: TextStyle(
            fontSize: 18,
            color: Colors.white,
          ),
        ),
      );
    } else {
      return Container(
        child: SingleChildScrollView(
          child: Column(
            children: [
              for (var bookmark in bookmarks.reversed) buildBookmark(bookmark)
            ],
          ),
        ),
      );
    }
  }

  Widget buildBookmark(BookmarkModel bookmark) {
    return Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
      GestureDetector(
        child: Text(
          "bookmark: ${bookmark.sentenceIndex}",
          style: TextStyle(color: Colors.white),
        ),
        onTap: () {
          scrollController.jumpTo(bookmark.sentenceIndex.toDouble());
        },
      ),
      IconButton(
          onPressed: () {
            // BookmarkController.deleteBookmark(bookmark.delete());

            setState(() {
              bookmark.delete();
              bookmarks.remove(bookmark);
            });
          },
          icon: Icon(Icons.delete))
    ]);
  }

  // PopupMenuItem bookmarksMenu() {
  //   return PopupMenuItem(
  //     child: StatefulBuilder(
  //       builder: (context, innerSetState) => Column(
  //         mainAxisAlignment: MainAxisAlignment.spaceBetween,
  //         children: [
  //           Row(
  //             mainAxisAlignment: MainAxisAlignment.spaceBetween,
  //             children: [
  //               Text(
  //                 'Bookmarks',
  //                 style: TextStyle(
  //                   color: Colors.white,
  //                   fontSize: 16,
  //                 ),
  //               ),
  //               IconButton(
  //                 onPressed: () {
  //                   innerSetState(() {
  //                     setState(() {
  //                       BookmarkController.addBookmark(widget.text!.title,
  //                           scrollController.position.pixels.toInt());
  //                       bookmarks.add(BookmarkModel()
  //                         ..textTitle = widget.text!.title
  //                         ..sentenceIndex =
  //                             scrollController.position.pixels.toInt());
  //                     });
  //                   });
  //                 },
  //                 icon: Icon(
  //                   Icons.add,
  //                 ),
  //               )
  //             ],
  //           ),
  //           Container(
  //             child: SingleChildScrollView(
  //               child: Column(
  //                 children: [
  //                   for (var bookmark in bookmarks.reversed)
  //                     Row(
  //                         mainAxisAlignment: MainAxisAlignment.spaceBetween,
  //                         children: [
  //                           GestureDetector(
  //                             child: Text(
  //                               "bookmark: ${bookmark.sentenceIndex}",
  //                               style: TextStyle(color: Colors.white),
  //                             ),
  //                             onTap: () {
  //                               scrollController
  //                                   .jumpTo(bookmark.sentenceIndex.toDouble());
  //                             },
  //                           ),
  //                           IconButton(
  //                               onPressed: () {
  //                                 // BookmarkController.deleteBookmark(bookmark.delete());
  //                                 innerSetState(() {
  //                                   setState(() {
  //                                     bookmark.delete();
  //                                     bookmarks.remove(bookmark);
  //                                   });
  //                                 });
  //                               },
  //                               icon: Icon(Icons.delete))
  //                         ]),
  //                 ],
  //               ),
  //             ),
  //           ),
  //         ],
  //       ),
  //     ),
  //   );
  // }

  PopupMenuItem ttsSpeedItem() {
    return PopupMenuItem(
      child: StatefulBuilder(
        builder: (context, innerSetState) => Column(
          children: [
            Text(
              'Tts speed: $ttsSpeed',
              style: TextStyle(color: Colors.white, fontSize: 16),
            ),
            Slider(
              max: 1.5,
              min: 0.5,
              divisions: 10,
              value: ttsSpeed,
              onChanged: (value) {
                innerSetState(() {
                  setState(() {
                    ttsSpeed = value;
                    tts.setSpeechRate(ttsSpeed);
                    settings.setTtsSpeed(value);
                  });
                });
              },
            )
          ],
        ),
      ),
    );
  }

  PopupMenuItem ttsItem() {
    return PopupMenuItem(
      child: StatefulBuilder(
        builder: (context, innerSetState) => Padding(
          padding: EdgeInsets.symmetric(horizontal: 10),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'TTS',
                style: TextStyle(color: Colors.white, fontSize: 16),
              ),
              Switch(
                  value: isTTsEnabled,
                  onChanged: (value) {
                    innerSetState(() {
                      setState(() {
                        isTTsEnabled = value;
                        settings.setTts(isTTsEnabled);
                      });
                    });
                  })
            ],
          ),
        ),
      ),
    );
  }

  PopupMenuItem fontFamilyItem() {
    return PopupMenuItem(
      child: StatefulBuilder(
        builder: (context, innerSetState) => Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Font',
              style: TextStyle(color: Colors.white, fontSize: 16),
            ),
            DropdownButton(
              value: fontName,
              focusColor: Colors.white,
              dropdownColor: Colors.grey[700],
              onChanged: (String? newValue) {
                setState(() {
                  fontName = newValue!;
                  settings.setFontFamily(fontName);
                });
              },
              items: <String>['Dayrom', 'LouisGeorgeCafe', 'OpenDyslexic']
                  .map<DropdownMenuItem<String>>(
                (String value) {
                  return DropdownMenuItem<String>(
                    value: value,
                    child: Text(
                      value,
                      style: TextStyle(color: Colors.white, fontFamily: value),
                    ),
                  );
                },
              ).toList(),
            ),
          ],
        ),
      ),
    );
  }

  PopupMenuItem paddingSizeItem() {
    return PopupMenuItem(
      child: StatefulBuilder(
        builder: (context, innerSetState) => Column(
          children: [
            Text(
              'Padding size: ${paddingSize.round()}',
              style: TextStyle(color: Colors.white, fontSize: 16),
            ),
            Slider(
              max: 64,
              min: 0,
              divisions: 8,
              value: paddingSize,
              onChanged: (value) {
                innerSetState(() {
                  setState(() {
                    paddingSize = value;
                    settings.setPadding(value);
                  });
                });
              },
            )
          ],
        ),
      ),
    );
  }

  PopupMenuItem textSizeItem() {
    return PopupMenuItem(
      child: StatefulBuilder(
        builder: (context, innerSetState) => Column(
          children: [
            Text(
              'Text size: ${fontSize.round()}',
              style: TextStyle(color: Colors.white, fontSize: 16),
            ),
            Slider(
              max: 44,
              min: 12,
              divisions: 8,
              value: fontSize,
              onChanged: (value) {
                innerSetState(() {
                  setState(() {
                    fontSize = value;
                    settings.setfontSize(value);
                  });
                });
              },
            )
          ],
        ),
      ),
    );
  }

  Future modalDefinitions(
      List<Map<dynamic, dynamic>> definitions, String word) {
    if (isTTsEnabled) tts.speak(word);
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
                    definitionCard(definitions[i])
                ],
              ),
            ),
          );
        });
  }

  Widget definitionCard(Map<dynamic, dynamic> definition) {
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
          onTap: () async {
            //TODO: FIX ADDING WORLD (NO SENTENCE)
            WordController.addWord(
                selectedWord,
                definitionFormated,
                selectedSentence,
                '[sound:${selectedWord + selectedSentence.split(' ').first}.mp3]');
            Navigator.pop(context);
          }),
    );
  }

  void showToast(String message) => Fluttertoast.showToast(msg: message);
}
