import 'package:flutter/material.dart';

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

  @override
  void initState() {
    super.initState();

    if (widget.text != null) {
      final text = widget.text!;

      titleController.text = text.title;
      contentsController.text = text.contents;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(titleController.text),
      ),
      body: Center(
        child: Container(
          child: Expanded(
              child: SingleChildScrollView(
            child: SelectableText(
              contentsController.text,
              style: TextStyle(fontSize: 26),
            ),
          )),
        ),
      ),
    );
  }
}
