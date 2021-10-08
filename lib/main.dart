import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:language_miner/model/wordModel.dart';
import 'package:language_miner/page/texts_list.dart';
import 'package:language_miner/page/words_list.dart';
import 'package:language_miner/model/textModel.dart';

void main() async {
  await Hive.initFlutter();

  Hive
    ..registerAdapter(TextModelAdapter())
    ..registerAdapter(WordModelAdapter());

  runApp(MaterialApp(
    title: 'yap',
    theme: ThemeData(
        primaryColor: Colors.grey,
        backgroundColor: Colors.black,
        scaffoldBackgroundColor: Colors.black,
        bottomNavigationBarTheme:
            BottomNavigationBarThemeData(backgroundColor: Colors.grey),
        textTheme: TextTheme(
            headline1: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold))),
    routes: {
      '/': (BuildContext context) => MyApp(),
    },
  ));
}

class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  int _pageIndex = 0;
  late PageController _pageController;
  List<Widget> pages = [TextPg(), WordPg()];

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void changePage(int index) {
    setState(() {});
    _pageIndex = index;
    _pageController.animateToPage(index,
        duration: Duration(milliseconds: 300), curve: Curves.easeOut);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // backgroundColor: Color(Colors.black.hashCode),
      body: PageView(
        controller: _pageController,
        children: pages,
      ),
      bottomNavigationBar: BottomNavigationBar(
        items: [
          BottomNavigationBarItem(
            icon: Icon(Icons.book),
            label: 'Texts',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.label_important_rounded),
            label: 'Words',
          )
        ],
        currentIndex: _pageIndex,
        onTap: changePage,
        selectedItemColor: Colors.green,
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

























// Future main() async {
//   await Hive.initFlutter();
//   Hive.registerAdapter(TextModelAdapter());
//   await Hive.openBox<TextModel>('texts');

//   runApp(MaterialApp(
//     title: 'yap',
//     home: Home(),
//   ));
// }

// class Home extends StatefulWidget {
//   @override
//   _HomeState createState() => _HomeState();
// }

// class _HomeState extends State<Home> {
//   int _pageIndex = 0;

//   List<Widget> pages = <Widget>[TextsPage(), WordsPage()];

//   void onTap(int index) {
//     setState(() {
//       _pageIndex = index;
//     });
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: Text('LangReader'),
//       ),
//       body: Center(
//         child: pages.elementAt(_pageIndex),
//       ),
//       bottomNavigationBar: BottomNavigationBar(
//         items: [
//           BottomNavigationBarItem(
//             icon: Icon(Icons.book),
//             label: 'Texts',
//           ),
//           BottomNavigationBarItem(
//             icon: Icon(Icons.label_important_rounded),
//             label: 'Words',
//           )
//         ],
//         currentIndex: _pageIndex,
//         onTap: onTap,
//         selectedItemColor: Colors.green,
//       ),
//     );
//   }
// }
