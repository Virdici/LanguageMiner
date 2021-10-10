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
          IconButton(
              onPressed: () {
                showDialog(
                    context: context,
                    builder: (context) => AddTextDialog(
                          onClickedDone: TextController.addText,
                        ));
              },
              icon: Icon(Icons.add))
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

  Widget buildContent(List<TextModel> transactions) {
    if (transactions.isEmpty) {
      return Center(
        child: Text(
          'No texts here!',
          style: TextStyle(fontSize: 24),
        ),
      );
    } else {
      return Column(
        children: [
          SizedBox(height: 24),
          Expanded(
            child: ListView.builder(
              padding: EdgeInsets.all(8),
              itemCount: transactions.length,
              itemBuilder: (BuildContext context, int index) {
                final transaction = transactions[index];
                return buildTransaction(context, transaction);
              },
            ),
          ),
        ],
      );
    }
  }

  Widget buildTransaction(BuildContext context, TextModel text) {
    final date = DateFormat.yMMMd().format(text.timeCreated);

    return Card(
      color: Colors.white,
      child: ExpansionTile(
        tilePadding: EdgeInsets.symmetric(horizontal: 24, vertical: 8),
        title: Text(
          text.title,
          maxLines: 2,
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        subtitle: Row(
          children: [
            Text(date),
            SizedBox(width: 26),
            Text('Sentences: ' +
                text.contents
                    .split(RegExp(
                        r"(?<!\w\.\w.)(?<![A-Z][a-z]\.)(?<=\.|\?)(\s|[A-Z].*)"))
                    .length
                    .toString()),
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
              label: Text('Read'),
              icon: Icon(Icons.book),
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
                label: Text('Edit'),
                icon: Icon(Icons.edit),
                onPressed: () => showDialog(
                    context: context,
                    builder: (context) => AddTextDialog(
                        text: text,
                        onClickedDone: (title, contents) =>
                            TextController.editText(text, title, contents)))),
          ),
          Expanded(
            child: TextButton.icon(
              label: Text('Delete'),
              icon: Icon(Icons.delete),
              onPressed: () => TextController.deleteText(text),
            ),
          )
        ],
      );
}
