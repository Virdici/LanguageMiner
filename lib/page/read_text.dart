import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:hive/hive.dart';
import 'package:language_miner/Controllers/dictController.dart';
import 'package:language_miner/Controllers/wordController.dart';
import 'package:language_miner/model/wordModel.dart';
import '../model/textModel.dart';

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
  // late ScrollController _scrollController;
  double fontSize = 12;

  int scrollPos = 0;
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
    // debugPrint(paragraphsList.toString());
  }

  void changeTextSize(String size) {
    switch (size) {
      case '0':
        setState(() {
          fontSize = 24;
        });
        break;
      case '1':
        break;
      default:
    }
  }

  Widget textSpan(String text) {
    List<String> words = text.split(new RegExp(
        r"\ +|(?<=[^a-zA-Z0-9äöüÄÖÜß ])(?=[a-zA-Z0-9äöüÄÖÜß])|(?<=[a-zA-Z0-9äöüÄÖÜß])(?=[^a-zA-Z0-9äöüÄÖÜß ])|(?<=[^a-zA-Z0-9äöüÄÖÜß ])(?=[^a-zA-Z0-9äöüÄÖÜß ])"));
    return Wrap(
      children: [
        for (var i = 0; i < words.length; i++)
          GestureDetector(
            child: Text(
              RegExp(r'[<>?!,.„“]').hasMatch(words[i])
                  ? words[i]
                  : ' ' + words[i],
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
                  : modalDefinitions(dictTerms),
              // modalSentence(words[i]),
            },
          )
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    // _scrollController = new ScrollController()                       //get scroll position
    //   ..addListener(() {
    //     print(_scrollController.offset);
    //   });
    return Scaffold(
      appBar: AppBar(
        title: Text(titleController.text),
        actions: [
          PopupMenuButton(
              icon: Icon(Icons.menu),
              itemBuilder: (context) => [
                    PopupMenuItem(
                      child: Text('penis'),
                      value: 0,
                    ),
                  ],
              onSelected: (item) => {changeTextSize(item.toString())})
        ],
      ),
      body: ListView.builder(
          itemCount: paragraphsList.length,
          itemBuilder: (context, index) {
            return textSpan(paragraphsList[index]);
          }),
    );
  }

  // @override
  // Widget build(BuildContext context) {
  //   // _scrollController = new ScrollController()                       //get scroll position
  //   //   ..addListener(() {
  //   //     print(_scrollController.offset);
  //   //   });
  //   return Scaffold(
  //     appBar: AppBar(
  //       title: Text(titleController.text),
  //       actions: [
  //         PopupMenuButton(
  //             icon: Icon(Icons.menu),
  //             itemBuilder: (context) => [
  //                   PopupMenuItem(
  //                     child: Text('penis'),
  //                     value: 0,
  //                   ),
  //                 ],
  //             onSelected: (item) => {changeTextSize(item.toString())})
  //       ],
  //     ),
  //     body: ListView.builder(
  //         itemCount: paragraphsList.length,
  //         itemBuilder: (context, index) {
  //           return GestureDetector(
  //             child: Text(
  //               paragraphsList[index],
  //               style: TextStyle(
  //                   color: Colors.white,
  //                   fontSize: fontSize,
  //                   fontWeight: FontWeight.bold,
  //                   fontFamily: 'OpenDyslexic'),
  //             ),
  //             onTap: () => {
  //               selectedSentence = paragraphsList[index],
  //               modalSentence(paragraphsList[index])
  //             },
  //           );
  //         }),
  //   );
  // }

  Future modalSentence(String sentence) {
    // split sentence into words and characters
    List<String> words = sentence.split(new RegExp(
        r"\ +|(?<=[^a-zA-Z0-9äöüÄÖÜß ])(?=[a-zA-Z0-9äöüÄÖÜß])|(?<=[a-zA-Z0-9äöüÄÖÜß])(?=[^a-zA-Z0-9äöüÄÖÜß ])|(?<=[^a-zA-Z0-9äöüÄÖÜß ])(?=[^a-zA-Z0-9äöüÄÖÜß ])"));
    print(words);
    return showModalBottomSheet<void>(
      context: context,
      builder: (BuildContext context) {
        return Container(
          height: 300,
          color: Colors.grey[900],
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  SelectableText.rich(TextSpan(
                    children: <TextSpan>[
                      for (var i = 0; i < words.length; i++)
                        TextSpan(
                            text: words[i] + ' ',
                            style: Theme.of(context).textTheme.headline1,
                            recognizer: new TapGestureRecognizer()
                              ..onTap = () async => {
                                    print("selected word: " + words[i]),
                                    selectedWord = words[i],
                                    dictTerms = await DictController.getTerm(
                                        selectedWord),
                                    modalDefinitions(dictTerms)
                                  }),
                    ],
                  )),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Future modalDefinitions(List<Map<dynamic, dynamic>> definitions) {
    return showModalBottomSheet<void>(
        context: context,
        builder: (BuildContext context) {
          return Container(
            color: Colors.grey[500],
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                for (var i = 0; i < definitions.length; i++)
                  // Text(definitions[i]['definition'].toString())
                  definitionCard(definitions[i])
                // Text(definitions.length.toString())
              ],
            ),
          );
        });
  }

  Widget definitionCard(Map<dynamic, dynamic> definition) {
    String definitionFormated =
        definition['definition'].toString().replaceAll('<br>', '');
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 24, 8, 8),
      child: GestureDetector(
          child: Card(
            child: Align(
              alignment: Alignment.centerLeft,
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Text(
                  definitionFormated,
                  style: TextStyle(fontSize: 16),
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

  void showToast(String message) => Fluttertoast.showToast(msg: message);
}
