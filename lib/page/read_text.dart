import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:language_miner/Controllers/dictController.dart';
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

    return Scaffold(
      appBar: AppBar(
        title: Text(titleController.text),
      ),
      body: SingleChildScrollView(
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
                        recognizer: new TapGestureRecognizer()
                          ..onTap = () => {modal(paragraphsList[i])}),
            ],
          ),
        ),
      ),
    );
  }

  Future modal(String sentence) {
    // List<String> words = sentence.split(new RegExp(r"[ ,'„!?.\n]"));
    List<String> words = sentence.split(new RegExp(
        r"\ +|(?<=[^a-zA-Z0-9äöüÄÖÜß ])(?=[a-zA-Z0-9äöüÄÖÜß])|(?<=[a-zA-Z0-9äöüÄÖÜß])(?=[^a-zA-Z0-9äöüÄÖÜß ])|(?<=[^a-zA-Z0-9äöüÄÖÜß ])(?=[^a-zA-Z0-9äöüÄÖÜß ])"));
    late String selectedWord;
    print(words);
    return showModalBottomSheet<void>(
      context: context,
      builder: (BuildContext context) {
        return Container(
          height: 250,
          color: Colors.grey[500],
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                SelectableText.rich(TextSpan(
                  children: <TextSpan>[
                    for (var i = 0; i < words.length; i++)
                      TextSpan(
                          text: words[i] + ' ',
                          recognizer: new TapGestureRecognizer()
                            ..onTap = () => {
                                  print("selected word: " + words[i]),
                                  selectedWord = words[i]
                                }),
                  ],
                )),
                ElevatedButton(
                    child: const Text('Close BottomSheet'),
                    onPressed: () => {
                          // WordController.addWord(
                          //     selectedWord, 'translation', sentence)
                          DictController.getTerm(selectedWord),
                        })
              ],
            ),
          ),
        );
      },
    );
  }
}
