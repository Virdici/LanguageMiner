import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
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

  @override
  Widget build(BuildContext context) {
    // _scrollController = new ScrollController()                       //get scroll position
    //   ..addListener(() {
    //     print(_scrollController.offset);
    //   });

    double _scaleFactor = 1;
    double _baseScaleFactor = 1;

    return Scaffold(
      appBar: AppBar(
        title: Text(titleController.text),
      ),
      body: GestureDetector(
        onScaleStart: (details) {
          _baseScaleFactor = _scaleFactor;
        },
        onScaleUpdate: (details) {
          _scaleFactor = (_baseScaleFactor * details.scale).roundToDouble();
          setState(() {});
          print(_scaleFactor);
        },
        child: SingleChildScrollView(
          // controller: _scrollController =                              //set scroll position
          //     ScrollController(initialScrollOffset: 9485),
          child: SelectableText.rich(
            TextSpan(
              style: TextStyle(color: Colors.black, fontSize: 16),
              children: <TextSpan>[
                for (var i = 0; i < paragraphsList.length; i++)
                  paragraphsList[i] ==
                          '''
'''
                      ? TextSpan(text: '''
      
      
''')
                      : TextSpan(
                          text: paragraphsList[i] + " ",
                          style: Theme.of(context).textTheme.headline1,
                          recognizer: new TapGestureRecognizer()
                            ..onTap = () => {
                                  selectedSentence = paragraphsList[i],
                                  modalSentence(paragraphsList[i])
                                }),
              ],
            ),
          ),
        ),
      ),
    );
  }

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
          color: Colors.grey[500],
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
                            style: TextStyle(fontSize: 24),
                            text: words[i] + ' ',
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
                  // ElevatedButton(
                  //     child: const Text('Close BottomSheet'),
                  //     onPressed: () async => {
                  //           // WordController.addWord(
                  //           //     selectedWord, 'translation', sentence)
                  //           dictTerms =
                  //               await DictController.getTerm(selectedWord),
                  //           print(dictTerms)
                  //         })
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
            height: 300,
            color: Colors.grey[500],
            child: Center(
                child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                for (var i = 0; i < definitions.length; i++)
                  // Text(definitions[i]['definition'].toString())
                  definitionCard(definitions[i])
                // Text(definitions.length.toString())
              ],
            )),
          );
        });
  }

  Widget definitionCard(Map<dynamic, dynamic> definition) {
    String definitionFormated =
        definition['definition'].toString().replaceAll('<br>', '\n');
    return GestureDetector(
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
      },
    );
  }
}
