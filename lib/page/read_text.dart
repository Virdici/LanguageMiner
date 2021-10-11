import 'dart:async';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:hive/hive.dart';
import 'package:language_miner/Controllers/dictController.dart';
import 'package:language_miner/Controllers/settings.dart';
import 'package:language_miner/Controllers/wordController.dart';
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
  late Box box;
  late List<Map<dynamic, dynamic>> dictTerms;
  late String selectedWord;
  late String selectedSentence;
  ScrollController scrollController = new ScrollController();
  double fontSize = 12;
  double paddingSize = 0;
  double scrollPosition = 0;
  late Settings settings;
  double appBarSize = 50;
  bool isTTsEnabled = true;
  final FlutterTts tts = FlutterTts();
  bool isMenuShown = false;
  String fontName = 'Dayrom';

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
        scrollPosition = settings.getScrollPosition();
        fontName = settings.getFontFamily();
        isTTsEnabled = settings.getTts();
      });
    });
    Future.delayed(Duration.zero, () => setPosition(context));
    tts.setLanguage('de');
    tts.setSpeechRate(0.8);
  }

  void setPosition(BuildContext context) {
    scrollController.animateTo(scrollPosition,
        duration: new Duration(microseconds: 1), curve: Curves.bounceIn);
  }

  @override
  Widget build(BuildContext context) {
    scrollController = ScrollController() //get scroll position
      ..addListener(() {
        scrollPosition = scrollController.offset;
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
              child: ListView.builder(
                  controller: scrollController,
                  itemCount: paragraphsList.length,
                  itemBuilder: (context, index) {
                    return textSpan(paragraphsList[index]);
                  }),
            ),
          ),
          customAppBar(),
        ],
      ),
    );
  }

  Widget customAppBar() {
    if (isMenuShown) {
      return Container(
        height: 280,
        width: 220,
        color: Colors.grey[900],
        child: Column(
          children: [
            Padding(
              padding: EdgeInsets.fromLTRB(10, 20, 10, 0),
              child: GestureDetector(
                onTap: () {},
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Text size: ' + fontSize.round().toString(),
                      style: TextStyle(color: Colors.white, fontSize: 16),
                    ),
                    Slider(
                      max: 32,
                      min: 8,
                      value: fontSize,
                      onChanged: (value) {
                        setState(() {
                          fontSize = value;
                          settings.setfontSize(value);
                        });
                      },
                    )
                  ],
                ),
              ),
            ),
            Padding(
              padding: EdgeInsets.fromLTRB(10, 20, 10, 0),
              child: GestureDetector(
                onTap: () {},
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Padding size: ' + paddingSize.round().toString(),
                      style: TextStyle(color: Colors.white, fontSize: 16),
                    ),
                    Slider(
                      max: 32,
                      min: 0,
                      value: paddingSize,
                      onChanged: (value) {
                        setState(() {
                          paddingSize = value;
                          settings.setPadding(value);
                        });
                      },
                    )
                  ],
                ),
              ),
            ),
            Padding(
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
                        setState(() {
                          isTTsEnabled = value;
                          settings.setTts(isTTsEnabled);
                        });
                      })
                ],
              ),
            ),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 10),
              child: GestureDetector(
                onTap: () {},
                child: Row(
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
                      items: <String>[
                        'Dayrom',
                        'LouisGeorgeCafe',
                        'OpenDyslexic'
                      ].map<DropdownMenuItem<String>>(
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
          ],
        ),
      );
    } else {
      return Container();
    }
  }

  AppBar appBar() {
    return AppBar(
      title: Text(titleController.text),
      actions: [
        Padding(
            padding: EdgeInsets.only(right: 20.0),
            child: GestureDetector(
              onTap: () {
                setState(() {
                  isMenuShown = !isMenuShown;
                });
              },
              child: Icon(Icons.more_vert),
            )),
      ],
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
    settings.setScrollPosition(scrollPosition);
  }

  void showToast(String message) => Fluttertoast.showToast(msg: message);
}
