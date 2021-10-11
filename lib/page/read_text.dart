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
  //tts

  final FlutterTts tts = FlutterTts();

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
      });
    });
    Future.delayed(Duration.zero, () => setPosition(context));
    //tts
    tts.setLanguage('de');
    tts.setSpeechRate(0.5);
  }

  void setPosition(BuildContext context) {
    scrollController.animateTo(scrollPosition,
        duration: new Duration(microseconds: 1), curve: Curves.bounceIn);
  }

  void increaseTextSize() {
    setState(() {
      if (fontSize >= 48) {
        fontSize = 48;
        settings.setfontSize(48);
      } else {
        fontSize += 2;
        settings.setfontSize(fontSize += 2);
      }
    });
  }

  void decreaseTextSize() {
    setState(() {
      if (fontSize <= 4) {
        fontSize = 4;
        settings.setfontSize(4);
      } else {
        fontSize -= 2;
        settings.setfontSize(fontSize -= 2);
      }
    });
  }

  void increasePadding() {
    setState(() {
      if (paddingSize >= 48) {
        paddingSize = 48;
        settings.setPadding(48);
      } else {
        paddingSize += 4;
        settings.setPadding(paddingSize += 4);
      }
    });
  }

  void decreasePadding() {
    setState(() {
      if (paddingSize <= 0) {
        paddingSize = 0;
        settings.setPadding(0);
      } else {
        paddingSize -= 4;
        settings.setPadding(paddingSize -= 4);
      }
    });
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
      body: GestureDetector(
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
    );
  }

  AppBar appBar() {
    return AppBar(
      title: Text(titleController.text),
      actions: [
        IconButton(
          onPressed: () {
            tts.speak('„Ich glaube, wir haben Schwein gehabt“, sagte Peter.');
          },
          icon: Icon(Icons.play_arrow),
        ),
        PopupMenuButton(
          color: Colors.grey,
          icon: Icon(Icons.menu),
          itemBuilder: (context) => [
            PopupMenuItem(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('font size'),
                  Row(
                    children: [
                      IconButton(
                        onPressed: decreaseTextSize,
                        icon: Icon(Icons.remove),
                        color: Colors.black,
                      ),
                      IconButton(
                        onPressed: increaseTextSize,
                        icon: Icon(
                          Icons.add,
                          color: Colors.black,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              value: 0,
            ),
            PopupMenuItem(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Padding Size'),
                  Row(
                    children: [
                      IconButton(
                        onPressed: decreasePadding,
                        icon: Icon(Icons.remove),
                        color: Colors.black,
                      ),
                      IconButton(
                        onPressed: increasePadding,
                        icon: Icon(
                          Icons.add,
                          color: Colors.black,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              value: 0,
            ),
          ],
        )
      ],
    );
  }

  Widget textSpan(String text) {
    List<String> words = text.split(new RegExp(
        r"(?<=[^a-zA-Z0-9äöüÄÖÜß])(?=[a-zA-Z0-9äöüÄÖÜß])|(?<=[a-zA-Z0-9äöüÄÖÜß])(?=[^a-zA-Z0-9äöüÄÖÜß])|(?<=[^a-zA-Z0-9äöüÄÖÜß])(?=[^a-zA-Z0-9äöüÄÖÜß])"));
    return Wrap(
      children: [
        for (var i = 0; i < words.length; i++)
          GestureDetector(
            child: Text(
              words[i],
              style: TextStyle(
                  color: Colors.white,
                  fontSize: fontSize,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'OpenDyslexic'),
            ),
            onTap: () async => {
              selectedSentence = text,
              selectedWord = words[i],
              dictTerms = await DictController.getTerm(words[i]),
              WordController.checkIfExists(words[i], selectedSentence)
                  ? showToast('Term already saved')
                  : modalDefinitions(dictTerms, words[i]),
              // modalSentence(words[i]),
            },
            onLongPress: () {
              tts.speak(text);
            },
          )
      ],
    );
  }

  Future modalDefinitions(
      List<Map<dynamic, dynamic>> definitions, String word) {
    tts.speak(word);
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
                          fontFamily: 'OpenDyslexic'),
                    ),
                  ),
                  for (var i = 0; i < definitions.length; i++)
                    // Text(definitions[i]['definition'].toString())
                    definitionCard(definitions[i])
                  // Text(definitions.length.toString())
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
                padding: const EdgeInsets.fromLTRB(18, 0, 18, 8),
                child: Text(
                  definitionFormated,
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: fontSize,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'OpenDyslexic'),
                ),
              ),
            ),
          ),
          onTap: () {
            WordController.addWord(
                selectedWord, definitionFormated, selectedSentence);
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
