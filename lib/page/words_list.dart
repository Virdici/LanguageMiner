import 'dart:io';

import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:hive/hive.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:language_miner/Controllers/wordController.dart';
import 'package:language_miner/model/wordModel.dart';
import 'package:language_miner/page/add_word.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';

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
      appBar: new AppBar(
        title: Text('Words'),
        actions: [
          TextButton(
              child: Row(
                children: <Widget>[
                  Text(
                    'Export',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                    ),
                  ),
                  Icon(
                    Icons.import_export,
                    color: Colors.white,
                  ),
                ],
              ),
              onPressed: () async {
                exportTsv();
              }),
          TextButton(
              child: Row(
                children: <Widget>[
                  Text(
                    'Delete all',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                    ),
                  ),
                  Icon(
                    Icons.delete,
                    color: Colors.white,
                  ),
                ],
              ),
              onPressed: () {
                box.clear();
              }),
        ],
      ),
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
                )),
              ],
            );
          }
        },
      ),
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
              Text(
                word.word,
                style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.blue,
                    fontSize: 24),
              ),
              Row(
                children: [
                  IconButton(
                    onPressed: () => showDialog(
                      context: context,
                      builder: (context) => AddWordDialog(
                          word: word,
                          onClickedDone: (wordName, translation, sentence) =>
                              WordController.editText(
                                  word, wordName, translation, sentence)),
                    ),
                    icon: Icon(Icons.edit),
                  ),
                  IconButton(
                    onPressed: () => WordController.deleteWord(word),
                    icon: Icon(Icons.delete),
                  ),
                ],
              )
            ],
          ),
          children: [
            Container(
              child: Align(
                  alignment: Alignment.centerLeft,
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(24, 8, 64, 2),
                    child: Column(
                      children: [
                        Align(
                            child: Text(word.translation!),
                            alignment: Alignment.centerLeft),
                        Align(
                            child: Text(word.sentence),
                            alignment: Alignment.centerLeft),
                        SizedBox(
                          height: 12,
                        )
                      ],
                    ),
                  )),
            )
          ],
        ));
  }

  void exportTsv() async {
    var words = box.values.toList().cast<WordModel>();

    var status = await Permission.storage.status;
    if (!status.isGranted) {
      await Permission.storage.request();
    }
    if (status.isGranted) {
      // final Directory directory = await getApplicationDocumentsDirectory();
      final Directory? directory = await getExternalStorageDirectory();
      final File file = File('${directory!.path}/export.tsv');
      for (var word in words) {
        await file.writeAsString(
          '${word.word}\t${word.sentence}\t${word.translation}\n',
          mode: FileMode.append,
        );
      }
      showToast('Saved to:\n\n ${directory.path}/export.tsv');
    }
  }

  void showToast(String message) => Fluttertoast.showToast(msg: message);
}
