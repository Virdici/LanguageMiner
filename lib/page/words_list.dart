import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:language_miner/Controllers/wordController.dart';
import 'package:language_miner/model/wordModel.dart';
import 'package:language_miner/page/add_word.dart';

class WordsPage extends StatefulWidget {
  @override
  _WordsPageState createState() => _WordsPageState();
}

class _WordsPageState extends State<WordsPage> {
  late Box box;
  Future initBox() async {
    box = await Hive.openBox<WordModel>('words');
  }

  @override
  // ignore: must_call_super
  void initState() {
    initBox();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: ValueListenableBuilder<Box<WordModel>>(
        valueListenable: Hive.box<WordModel>('words').listenable(),
        builder: (context, box, _) {
          final words = box.values.toList().cast<WordModel>();
          if (words.isEmpty) {
            return Center(
              child: Text('No words yet!'),
            );
          } else {
            return Column(
              children: [
                SizedBox(
                  height: 8,
                ),
                Expanded(
                    child: ListView.builder(
                  padding: EdgeInsets.all(10),
                  itemCount: words.length,
                  itemBuilder: (BuildContext context, int index) {
                    final word = words[index];
                    return wordCard(word, words.length);
                  },
                ))
              ],
            );
          }
        },
      ),
      floatingActionButton: FloatingActionButton(
          child: Icon(Icons.add),
          onPressed: () => showDialog(
              // wordBox.clear(); //clear box
              context: context,
              builder: (context) => AddWordDialog(
                    onClickedDone: WordController.addWord,
                  ))),
    );
  }

  Widget wordCard(WordModel word, int i) {
    return Card(
        color: Colors.white,
        child: ExpansionTile(
          tilePadding: EdgeInsets.fromLTRB(24, 8, 24, 2),
          title: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                mainAxisAlignment: MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    word.word,
                    style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.blue,
                        fontSize: 24),
                  ),
                  Container(
                    child: Text(
                      word.translation!,
                      softWrap: true,
                    ),
                  )
                ],
              ),
              IconButton(
                onPressed: () => WordController.deleteWord(word),
                icon: Icon(Icons.delete),
              )
            ],
          ),
          children: [
            Container(
              child: Align(
                  alignment: Alignment.centerLeft,
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(24, 8, 64, 2),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(word.sentence),
                        IconButton(
                          onPressed: () => showDialog(
                            context: context,
                            builder: (context) => AddWordDialog(
                                word: word,
                                onClickedDone: (wordName, translation,
                                        sentence) =>
                                    WordController.editText(
                                        word, wordName, translation, sentence)),
                          ),
                          icon: Icon(Icons.edit),
                        )
                      ],
                    ),
                  )),
            )
          ],
        ));
  }

  // @override
  // void dispose() {
  //   Hive.close();
  //   super.dispose();
  // }
}
