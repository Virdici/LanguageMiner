import 'dart:async';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:hive/hive.dart';
import 'package:language_miner/Controllers/dictController.dart';
import 'package:language_miner/Controllers/settings.dart';
import 'package:language_miner/Controllers/wordController.dart';
import 'package:language_miner/model/wordModel.dart';
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';
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
  late Box box;
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

  List<String>? bookmarks = new List.empty(growable: true);

  final ItemScrollController itemScrollController = ItemScrollController();
  final ItemPositionsListener itemPositionsListener =
      ItemPositionsListener.create();

  late List<String> paragraphsList = content.split(
      new RegExp(r"(?<!\w\.\w.)(?<![A-Z][a-z]\.)(?<=\.|\?)(\s|[A-Z].*)|\n"));

  Future initBox() async {
    box = await Hive.openBox<WordModel>('words');
  }

  @override
  void initState() {
    super.initState();
    initBox();
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
        ttsSpeed = 1;
        // ttsSpeed = settings.getTtsSpeed();
        bookmarks = settings.getBookmarks();
      });
    });
    tts.setLanguage('de');
    tts.setSpeechRate(0.8);
    Future.delayed(Duration(microseconds: 100), () => setPosition(context));
  }

  void setPosition(BuildContext context) {
    itemScrollController.jumpTo(index: scrollPositionIndexed);
  }

  @override
  Widget build(BuildContext context) {
    Timer.periodic(Duration(seconds: 1), (timer) {
      settings.setScrollPositionIndexed(
          itemPositionsListener.itemPositions.value.first.index);
    });
    return Scaffold(
      appBar: PreferredSize(
        child: appBar(),
        preferredSize: Size.fromHeight(appBarSize),
      ),
      body: Stack(
        alignment: Alignment.topRight,
        children: [
          GestureDetector(
            onDoubleTap: () {
              setState(() {
                if (appBarSize == 50) {
                  appBarSize = 0;
                } else {
                  appBarSize = 50;
                }
              });
            },
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: paddingSize),
              child: ScrollablePositionedList.builder(
                  itemCount: paragraphsList.length,
                  itemScrollController: itemScrollController,
                  itemPositionsListener: itemPositionsListener,
                  addAutomaticKeepAlives: true,
                  itemBuilder: (context, index) {
                    return textSpan(paragraphsList[index]);
                  }),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          print(itemPositionsListener.itemPositions.value.first.index);
          itemScrollController.jumpTo(index: 150);
        },
      ),
    );
  }

  AppBar appBar() {
    return AppBar(title: Text(titleController.text), actions: [
      PopupMenuButton(
        icon: Icon(Icons.bookmark),
        color: Colors.grey[850],
        itemBuilder: (context) => [
          PopupMenuItem(
            child: StatefulBuilder(
              builder: (context, innerSetState) => Column(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Bookmarks',
                        style: TextStyle(color: Colors.white, fontSize: 16),
                      ),
                      IconButton(
                          onPressed: () {
                            bookmarks!.add(itemPositionsListener
                                .itemPositions.value.first.index
                                .toString());
                            innerSetState(() {
                              setState(() {
                                settings.saveBookmarks(bookmarks!);
                              });
                            });
                          },
                          icon: Icon(Icons.add))
                    ],
                  ),
                  Container(
                    child: SingleChildScrollView(
                      child: Column(
                        children: [
                          for (var bookmark in bookmarks!)
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                GestureDetector(
                                  child: Text(
                                    "sentence: $bookmark",
                                    style: TextStyle(color: Colors.white),
                                  ),
                                  onTap: () {
                                    itemScrollController.jumpTo(
                                        index: int.parse(bookmark));
                                  },
                                ),
                                IconButton(
                                  onPressed: () {
                                    innerSetState(() {
                                      setState(() {
                                        bookmarks!.remove(bookmark);
                                      });
                                    });
                                  },
                                  icon: Icon(Icons.delete),
                                ),
                              ],
                            ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
      PopupMenuButton(
        color: Colors.grey[850],
        itemBuilder: (context) => [
          PopupMenuItem(
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
          ),
          PopupMenuItem(
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
          ),
          PopupMenuItem(
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
                            style: TextStyle(
                                color: Colors.white, fontFamily: value),
                          ),
                        );
                      },
                    ).toList(),
                  ),
                ],
              ),
            ),
          ),
          PopupMenuItem(
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
          ),
          PopupMenuItem(
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
          ),
        ],
      )
    ]);
  }

  Widget bookark(String sentence) {
    return StatefulBuilder(
      builder: (context, innerSetState) => Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          GestureDetector(
            child: Text(
              "sentence: $sentence",
              style: TextStyle(color: Colors.white),
            ),
            onTap: () {
              itemScrollController.jumpTo(index: int.parse(sentence));
            },
          ),
          IconButton(
            onPressed: () {
              innerSetState(() {
                setState(() {
                  bookmarks!.remove(sentence);
                });
              });
            },
            icon: Icon(Icons.delete),
          ),
        ],
      ),
    );
  }

  Widget textSpan(String text) {
    List<String> words = text.split(new RegExp(
        r"(?<=[^a-zA-Z0-9äöüÄÖÜß])(?=[a-zA-Z0-9äöüÄÖÜß])|(?<=[a-zA-Z0-9äöüÄÖÜß])(?=[^a-zA-Z0-9äöüÄÖÜß])|(?<=[^a-zA-Z0-9äöüÄÖÜß])(?=[^a-zA-Z0-9äöüÄÖÜß])"));
    return Wrap(
      alignment: WrapAlignment.start,
      children: [
        for (var i = 0; i < words.length; i++)
          GestureDetector(
            child: Text(
              words[i],
              style: TextStyle(
                  color: Colors.white,
                  fontSize: fontSize,
                  fontWeight: FontWeight.bold,
                  fontFamily: fontName),
            ),
            onTap: () async => {
              selectedSentence = text,
              selectedWord = words[i],
              dictTerms = await DictController.getTerm(words[i]),
              WordController.checkIfExists(words[i], selectedSentence)
                  ? showToast('Term already saved')
                  : modalDefinitions(dictTerms, words[i]),
            },
            onLongPress: () {
              if (isTTsEnabled) tts.speak(text);
            },
          )
      ],
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
            WordController.addWord(
                selectedWord,
                definitionFormated,
                selectedSentence,
                '[sound:${selectedWord + selectedSentence.split(' ').first}.mp3]');
            Navigator.pop(context);
          }),
    );
  }

  @override
  void dispose() {
    super.dispose();
    settings.setScrollPositionIndexed(
        itemPositionsListener.itemPositions.value.first.index);
  }

  void showToast(String message) => Fluttertoast.showToast(msg: message);
}
