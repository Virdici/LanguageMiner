import 'dart:ui';
import 'dart:async';
import 'package:extended_text/extended_text.dart';
import 'package:flutter/rendering.dart';
import 'package:hive/hive.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:language_miner/Controllers/bookmarkController.dart';
import 'package:language_miner/TextUtils/custom_selection_controls.dart';
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';
import 'package:language_miner/Controllers/settings.dart';
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
  ScrollController scrollControllerSupport = new ScrollController();
  double fontSize = 12;
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
  double paddingSize = 0;

  double fontScale = 1;

  //Font scales
  double louisFS = 1;
  double dislexicFS = 0.619132;
  double dayromFS = 0.9013;

  bool supportVisibility = false;

  late double progress = 2.54;
  late ExtendedText text;

  late List<BookmarkModel> bookmarks;
  CustomTextSelectionControls customTextSelectionControls =
      CustomTextSelectionControls(modal: false);

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
        scrollPositionIndexed = settings.getScrollPositionIndexed();
        fontName = settings.getFontFamily();
        isTTsEnabled = settings.getTts();
        ttsSpeed = 0.8;
      });
    });
    tts.setLanguage('de');
    tts.setSpeechRate(0.8);
    text = new ExtendedText(
      content,
      style: TextStyle(
          color: Colors.white,
          // fontSize: fontSize,
          fontSize: fontSize,
          fontWeight: FontWeight.bold,
          fontFamily: fontName),
      selectionEnabled: true,
      selectionControls: customTextSelectionControls,
      textScaleFactor: fontScale,
    );
  }

  @override
  Widget build(BuildContext context) {
    scrollController = ScrollController()
      ..addListener(() {
        // print(scrollController.offset);
        setState(() {
          double currentPos = scrollController.position.pixels;
          double maxScroll = scrollController.position.maxScrollExtent;
          double percentage = ((currentPos * 100) / maxScroll);
          progress = percentage;
        });
      });

    return Scaffold(
      appBar: PreferredSize(
        child: appBar(),
        preferredSize: Size.fromHeight(appBarSize),
      ),
      //TODO: FIX HIDING APPBAR
      body: GestureDetector(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: paddingSize),
          child: SingleChildScrollView(
            child: ExtendedText(
              content,
              style: TextStyle(
                  color: Colors.white,
                  // fontSize: fontSize,
                  fontSize: fontSize,
                  fontWeight: FontWeight.bold,
                  fontFamily: fontName),
              selectionEnabled: true,
              selectionControls: customTextSelectionControls,
              textScaleFactor: fontScale,
            ),
            controller: scrollController,
          ),
        ),
        onScaleStart: (details) {
          setState(() {
            if (appBarSize <= 0) {
              appBarSize = 50;
            } else {
              appBarSize = 0;
            }
          });
        },
      ),
    );
  }

  AppBar appBar() {
    return AppBar(
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(titleController.text),
            Text(progress.toStringAsFixed(2) + ' /100%'),
          ],
        ),
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
                  double currentPos = scrollController.position.pixels;
                  double maxScroll = scrollController.position.maxScrollExtent;
                  double percentage = ((currentPos * 100) / maxScroll);

                  print("percentage: " + (percentage).toString());

                  setState(() {
                    BookmarkController.addBookmark(
                        widget.text!.title, percentage);
                    bookmarks.add(BookmarkModel()
                      ..textTitle = widget.text!.title
                      ..sentenceIndex = percentage);
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
              final bookmarks = box.values
                  .where((element) => element.textTitle == widget.text!.title)
                  .toList()
                  .cast<BookmarkModel>();
              return buildBookmarks(bookmarks);
            },
          )
        ],
      ),
    );
  }

  //
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
          "bookmark: ${bookmark.sentenceIndex.toStringAsPrecision(2)}%",
          style: TextStyle(color: Colors.white),
        ),
        onTap: () {
          //TODO: Maybe add some adjustments?
          double? position;
          double maxScroll = scrollController.position.maxScrollExtent;

          position = ((bookmark.sentenceIndex * maxScroll) / 100);
          scrollController.jumpTo(position);
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
                  switch (fontName) {
                    case 'Dayrom':
                      fontScale = dayromFS;
                      break;
                    case 'LouisGeorgeCafe':
                      fontScale = louisFS;
                      break;
                    case 'OpenDyslexic':
                      fontScale = dislexicFS;
                      break;

                    default:
                  }
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

  void showToast(String message) => Fluttertoast.showToast(msg: message);
}
