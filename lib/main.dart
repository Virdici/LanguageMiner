import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:language_miner/model/wordModel.dart';
import 'package:language_miner/page/texts_list.dart';
import 'package:language_miner/page/words_list.dart';
import 'package:language_miner/model/textModel.dart';
import 'package:language_miner/model/bookmarkModel.dart';

void main() async {
  await Hive.initFlutter();

  Hive
    ..registerAdapter(TextModelAdapter())
    ..registerAdapter(WordModelAdapter())
    ..registerAdapter(BookmarkModelAdapter());

  runApp(
    MaterialApp(
      theme: ThemeData(
          primaryColor: Colors.grey[900],
          backgroundColor: Colors.black,
          appBarTheme: AppBarTheme(backgroundColor: Colors.grey[900]),
          scaffoldBackgroundColor: Colors.black,
          bottomNavigationBarTheme: BottomNavigationBarThemeData(
              selectedItemColor: Colors.green[400],
              backgroundColor: Colors.grey[900],
              unselectedItemColor: Colors.grey[700]),
          textTheme: TextTheme(
            headline1: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
                fontFamily: 'OpenDyslexic'),
            headline2: TextStyle(
                color: Colors.black,
                fontSize: 16,
                fontWeight: FontWeight.bold,
                fontFamily: 'OpenDyslexic'),
          )),
      routes: {
        '/': (BuildContext context) => MyApp(),
      },
    ),
  );
}

class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  int _pageIndex = 0;
  List<Widget> pages = [TextPg(), WordPg()];

  void changePage(int index) {
    setState(() {});
    _pageIndex = index;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: pages.elementAt(_pageIndex),
      ),
      bottomNavigationBar: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.auto_stories),
            label: 'Texts',
            backgroundColor: Colors.red,
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.translate),
            label: 'Words',
            backgroundColor: Colors.green,
          ),
        ],
        currentIndex: _pageIndex,
        onTap: changePage,
      ),
    );
  }
}

class TextPg extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: Hive.openBox<TextModel>('texts'),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.done) {
          if (snapshot.hasError)
            return Text(snapshot.error.toString());
          else
            return TextsPage();
        } else
          return Scaffold();
      },
    );
  }
}

class WordPg extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: Hive.openBox<WordModel>('words'),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.done) {
          if (snapshot.hasError)
            return Text(snapshot.error.toString());
          else
            return WordsPage();
        } else
          return Scaffold();
      },
    );
  }
}
