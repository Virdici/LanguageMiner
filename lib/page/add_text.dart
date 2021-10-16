import 'package:flutter/material.dart';
import 'package:language_miner/Controllers/textController.dart';

import '../model/textModel.dart';

class AddTextDialog extends StatefulWidget {
  final TextModel? text;
  final Function(String title, String contents) onClickedDone;

  const AddTextDialog({
    Key? key,
    this.text,
    required this.onClickedDone,
  }) : super(key: key);

  @override
  _TextDialogState createState() => _TextDialogState();
}

class _TextDialogState extends State<AddTextDialog> {
  final formKey = GlobalKey<FormState>();
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
  void dispose() {
    titleController.dispose();
    contentsController.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.text != null;
    final title = isEditing ? 'Edit text' : 'Add text';

    return returnDialog(title, context, isEditing);
  }

  Widget returnDialog(String title, BuildContext context, bool isEditing) {
    return Dialog(
      insetPadding: EdgeInsets.symmetric(horizontal: 10),
      child: Form(
        key: formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              SizedBox(height: 26),
              buildTitle(),
              SizedBox(height: 24),
              buildContents(),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  buildCancelButton(context),
                  buildAddButton(context, isEditing: isEditing),
                ],
              )
            ],
          ),
        ),
      ),
    );
  }

  Widget buildTitle() => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: TextFormField(
          controller: titleController,
          keyboardType: TextInputType.multiline,
          decoration: InputDecoration(
            border: OutlineInputBorder(),
            hintText: 'Enter Title',
          ),
          validator: (name) => name != null && name.isEmpty
              ? 'Enter a title'
              : TextController.checkIfExists(name!)
                  ? 'Title already exists'
                  : null,
        ),
      );

  Widget buildContents() => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: TextFormField(
          controller: contentsController,
          keyboardType: TextInputType.multiline,
          maxLines: null,
          decoration: InputDecoration(
            border: OutlineInputBorder(),
            hintText: 'Enter Contents',
          ),
          validator: (name) =>
              name != null && name.isEmpty ? 'Enter a contents' : null,
        ),
      );

  Widget buildCancelButton(BuildContext context) => TextButton(
        child: Text(
          'Cancel',
          style: TextStyle(color: Colors.red),
        ),
        onPressed: () => Navigator.of(context).pop(),
      );

  Widget buildAddButton(BuildContext context, {required bool isEditing}) {
    final text = isEditing ? 'Save' : 'Add';

    return TextButton(
      child: Text(text),
      onPressed: () async {
        final isValid = formKey.currentState!.validate();

        if (isValid) {
          final title = titleController.text;
          final contents = contentsController.text;

          widget.onClickedDone(title, contents);

          Navigator.of(context).pop();
        }
      },
    );
  }
}
