import 'package:flutter/material.dart';
import 'package:language_miner/model/wordModel.dart';

class AddWordDialog extends StatefulWidget {
  final WordModel? word;
  final Function(String word, String translation, String sentence)
      onClickedDone;

  const AddWordDialog({this.word, required this.onClickedDone});

  @override
  _AddWordDialogState createState() => _AddWordDialogState();
}

class _AddWordDialogState extends State<AddWordDialog> {
  final formKey = GlobalKey<FormState>();
  final wordController = TextEditingController();
  final translationController = TextEditingController();
  final sentenceController = TextEditingController();

  @override
  void initState() {
    super.initState();

    if (widget.word != null) {
      wordController.text = widget.word!.word;
      translationController.text = widget.word!.translation!;
      sentenceController.text = widget.word!.sentence;
    }
  }

  @override
  void dispose() {
    wordController.dispose();
    translationController.dispose();
    sentenceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.word != null;
    final title = isEditing ? 'Edit word' : 'Add word';
    return AlertDialog(
      title: Text(title),
      content: Form(
        key: formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            SizedBox(height: 8),
            TextFormField(
              controller: wordController,
              keyboardType: TextInputType.multiline,
              decoration: InputDecoration(
                border: OutlineInputBorder(),
                hintText: 'Enter word',
              ),
              validator: (valWord) =>
                  valWord != null && valWord.isEmpty ? 'Enter a word' : null,
            ),
            SizedBox(height: 8),
            TextFormField(
              controller: translationController,
              keyboardType: TextInputType.multiline,
              maxLines: null,
              decoration: InputDecoration(
                border: OutlineInputBorder(),
                hintText: 'Enter translation',
              ),
            ),
            SizedBox(height: 8),
            TextFormField(
              controller: sentenceController,
              keyboardType: TextInputType.multiline,
              maxLines: null,
              decoration: InputDecoration(
                border: OutlineInputBorder(),
                hintText: 'Enter sentence',
              ),
              validator: (valWord) => valWord != null && valWord.isEmpty
                  ? 'Enter a sentence'
                  : null,
            ),
          ],
        ),
      ),
      actions: [
        buildCancelButton(context),
        buildAddButton(context, isEditing),
      ],
    );
  }

  Widget buildCancelButton(BuildContext context) => TextButton(
        child: Text(
          'Cancel',
          style: TextStyle(color: Colors.red),
        ),
        onPressed: () => Navigator.of(context).pop(),
      );

  Widget buildAddButton(BuildContext context, bool isEditing) {
    final text = isEditing ? 'Save' : 'Add';

    return TextButton(
      onPressed: () async {
        final isValid = formKey.currentState!.validate();

        if (isValid) {
          final word = wordController.text;
          final translation = translationController.text;
          final sentence = sentenceController.text;

          widget.onClickedDone(word, translation, sentence);
          Navigator.of(context).pop();
        }
      },
      child: Text(text),
    );
  }
}
