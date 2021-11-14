import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:intl/intl.dart';
import 'package:language_miner/Controllers/textController.dart';
import 'package:language_miner/model/textModel.dart';
import 'package:language_miner/page/add_text.dart';
import 'package:language_miner/page/read_text.dart';

class TextsPage extends StatefulWidget {
  @override
  _TextsPageState createState() => _TextsPageState();
}

class _TextsPageState extends State<TextsPage> {
  final List<TextModel> texts = [];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Texts'),
        actions: [
          TextButton(
              child: Row(
                children: <Widget>[
                  Text(
                    'Add',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                    ),
                  ),
                  Icon(
                    Icons.add,
                    color: Colors.white,
                  ),
                ],
              ),
              onPressed: () {
                showDialog(
                    context: context,
                    builder: (context) => AddTextDialog(
                          onClickedDone: TextController.addText,
                        ));
              }),
        ],
      ),
      body: ValueListenableBuilder<Box<TextModel>>(
        valueListenable: Hive.box<TextModel>('texts').listenable(),
        builder: (context, box, _) {
          final texts = box.values.toList().cast<TextModel>();
          return buildContent(texts);
        },
      ),
    );
  }

  Widget buildContent(List<TextModel> texts) {
    if (texts.isEmpty) {
      return Center(
        child: Text(
          'No texts here!',
          style: TextStyle(fontSize: 24),
        ),
      );
    } else {
      return Column(
        children: [
          Expanded(
            child: ListView.builder(
              itemCount: texts.length,
              itemBuilder: (BuildContext context, int index) {
                final text = texts[index];
                return buildText(context, text);
              },
            ),
          ),
        ],
      );
    }
  }

  Widget buildText(BuildContext context, TextModel text) {
    final date = DateFormat.yMMMd().format(text.timeCreated);

    return Card(
      color: Colors.grey[700],
      child: ExpansionTile(
        collapsedIconColor: Colors.white,
        collapsedTextColor: Colors.white,
        textColor: Colors.white,
        iconColor: Colors.white,
        tilePadding: EdgeInsets.symmetric(horizontal: 24),
        title: Text(
          text.title,
          maxLines: 2,
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        subtitle: Row(
          children: [
            Text(
              date,
            ),
            SizedBox(width: 26),
            Text(
              'Sentences: ' +
                  text.contents
                      .split(RegExp(
                          r"(?<!\w\.\w.)(?<![A-Z][a-z]\.)(?<=\.|\?)(\s|[A-Z].*)"))
                      .length
                      .toString(),
            )
          ],
        ),
        children: [
          buildButtons(context, text),
        ],
      ),
    );
  }

  Widget buildButtons(BuildContext context, TextModel text) => Row(
        children: [
          Expanded(
            child: TextButton.icon(
              label: Text(
                'Read',
                style: TextStyle(color: Colors.white),
              ),
              icon: Icon(
                Icons.book,
                color: Colors.white,
              ),
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => ReadText(
                    text: text,
                  ),
                ),
              ),
            ),
          ),
          Expanded(
            child: TextButton.icon(
                label: Text(
                  'Edit',
                  style: TextStyle(color: Colors.white),
                ),
                icon: Icon(
                  Icons.edit,
                  color: Colors.white,
                ),
                onPressed: () => showDialog(
                    context: context,
                    builder: (context) => AddTextDialog(
                        text: text,
                        onClickedDone: (title, contents) =>
                            TextController.editText(text, title, contents)))),
          ),
          Expanded(
            child: TextButton.icon(
              label: Text(
                'Delete',
                style: TextStyle(color: Colors.white),
              ),
              icon: Icon(
                Icons.delete,
                color: Colors.white,
              ),
              //TODO: Delete with bookmarks
              onPressed: () => TextController.deleteText(text),
            ),
          )
        ],
      );
}
