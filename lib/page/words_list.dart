import 'dart:io';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
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
  double ttsSpeed = 1;
  final FlutterTts tts = FlutterTts();
  var _chars = 'AaBbCcDdEeFfGgHhIiJjKkLlMmNnOoPpQqRrSsTtUuVvWwXxYyZz1234567890';
  Random _rnd = Random();
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
          PopupMenuButton(
              color: Colors.grey[850],
              icon: Icon(Icons.menu),
              itemBuilder: (context) => [
                    PopupMenuItem(
                      child: TextButton(
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
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
                            exportTsv(false);
                          }),
                    ),
                    PopupMenuItem(
                      child: StatefulBuilder(
                        builder: (context, innerSetState) => Column(
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  ' Tts speed: $ttsSpeed',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 18,
                                  ),
                                ),
                                SizedBox(
                                  width: 18,
                                ),
                                TextButton(
                                  child: Row(
                                    children: [
                                      Text(
                                        'test',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 18,
                                        ),
                                      ),
                                      Icon(
                                        Icons.play_arrow,
                                        color: Colors.white,
                                      )
                                    ],
                                  ),
                                  onPressed: () {
                                    tts.speak(
                                        "Es wird die Geschwindigkeit eines Sprachsynthesizers");
                                  },
                                ),
                              ],
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
                                  });
                                });
                              },
                            )
                          ],
                        ),
                      ),
                    ),
                    PopupMenuItem(
                      child: TextButton(
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: <Widget>[
                              Text(
                                'Export with tts',
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
                            exportTsv(true);
                          }),
                    ),
                    PopupMenuItem(
                      child: TextButton(
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: <Widget>[
                              Text(
                                'Delete words',
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
                    ),
                    PopupMenuItem(
                      child: TextButton(
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: <Widget>[
                              Text(
                                'Delete storage',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 18,
                                ),
                              ),
                              Icon(
                                Icons.delete_forever_outlined,
                                color: Colors.white,
                              ),
                            ],
                          ),
                          onPressed: () async {
                            List files = new List.empty(growable: true);
                            final Directory? directory =
                                await getExternalStorageDirectory();
                            files = Directory("${directory!.path}/").listSync();
                            for (File file in files)
                              file.delete(recursive: true);
                          }),
                    ),
                  ])
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
                Expanded(
                    child: ListView.builder(
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
        color: Colors.grey[700],
        child: ExpansionTile(
          collapsedIconColor: Colors.white,
          collapsedTextColor: Colors.white,
          textColor: Colors.white,
          iconColor: Colors.white,
          tilePadding: EdgeInsets.symmetric(horizontal: 24),
          title: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                word.word,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 24,
                ),
              ),
              Row(
                children: [
                  IconButton(
                    color: Colors.white,
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
                    color: Colors.white,
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
                    padding: EdgeInsets.symmetric(horizontal: 24),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.start,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Definition:',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: Colors.white,
                          ),
                        ),
                        Text(
                          "   " + word.translation!,
                          style: TextStyle(color: Colors.white),
                        ),
                        SizedBox(
                          height: 12,
                        ),
                        Text(
                          'Sentence:',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: Colors.white,
                          ),
                        ),
                        Text(
                          "   " + word.sentence,
                          style: TextStyle(color: Colors.white),
                        ),
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

  void exportTsv(bool withTTS) async {
    var words = box.values.toList().cast<WordModel>();
    var status = await Permission.storage.status;
    if (!status.isGranted) {
      await Permission.storage.request();
    }
    if (status.isGranted) {
      final Directory? directory = await getExternalStorageDirectory();
      final File file = File('${directory!.path}/export.tsv');
      for (var word in words) {
        if (withTTS)
          tts.synthesizeToFile(word.sentence,
              "${word.word + word.sentence.split(' ').first + getRandomString(20)}.mp3");
        await file.writeAsString(
          '${word.word}\t${word.sentence}\t${word.translation}\t${word.audioReference}\n',
          mode: FileMode.append,
        );
      }
      showToast('Saved to:\n\n ${directory.path}/export.tsv');
    }
  }

  String getRandomString(int length) => String.fromCharCodes(Iterable.generate(
      length, (_) => _chars.codeUnitAt(_rnd.nextInt(_chars.length))));

  void showToast(String message) => Fluttertoast.showToast(msg: message);
}
