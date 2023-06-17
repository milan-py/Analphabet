import 'dart:convert';
import 'dart:io';
import 'package:anal_phabet/settings_menu.dart';
import 'package:anal_phabet/utils.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:anal_phabet/quote.dart';
import 'package:anal_phabet/quote_display.dart';
import 'package:anal_phabet/quote_menu.dart';
import 'package:flutter/material.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import 'package:share_plus/share_plus.dart';
import 'package:http/http.dart' as http;
import 'package:uuid/uuid.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData(
        primaryColor: const Color.fromARGB(255, 229, 222, 252),
        brightness: Brightness.light,
        useMaterial3: true,
      ),
      darkTheme: ThemeData(
        brightness: Brightness.dark,
        useMaterial3: true,
      ),
      themeMode: ThemeMode.system,
      title: "Analphabet",
      routes: {
        "/": (context) => const MyHomePage(title: "Analphabet"),
        "/new_quote_menu": (context) => const NewQuoteMenu(),
        "/settings_menu": (context) => const SettingsMenu(),
      },
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  late Future<Database> _database;
  List<Quote> quotes = [];

  Future<void> initializeDb() async {
    WidgetsFlutterBinding.ensureInitialized();

    _database = openDatabase(
      join(await getDatabasesPath(), "quotes_database.db"),
      onCreate: (db, version) {
        return db.execute(
          "CREATE TABLE quotes(quote TEXT, context TEXT, author TEXT, involvedPersons TEXT, timestamp TEXT, user TEXT, id TEXT)",
        );
      },
      version: 1,
    );
  }

  Future<void> addQuoteToDb(Quote? quote) async {
    final Database db = await _database;
    quote?.insertToDb(db);
  }

  Future<void> updateWithQuotesFromDb() async {
    final Database db = await _database;

    final List<Map<String, dynamic>> maps = await db.query("quotes");

    setState(() {
      quotes = List.generate(
        maps.length,
        (index) {
          List<String> involvedPersons = [];
          for (var i in jsonDecode(maps[index]["involvedPersons"])) {
            involvedPersons.add(i as String);
          }

          return Quote(
              quote: maps[index]["quote"],
              context: maps[index]["context"],
              author: maps[index]["author"],
              involvedPersons: involvedPersons,
              timestamp: DateTime.parse(maps[index]["timestamp"]),
              user: maps[index]["user"],
              id: maps[index]["id"]);
        },
      );
      quotes.sort((a, b) => a.timestamp.compareTo(b.timestamp));
    });
  }

  @override
  void initState() {
    super.initState();
    initializeDb().then((value) {
      updateWithQuotesFromDb();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        actions: [
          IconButton(
              onPressed: () {
                Navigator.pushNamed(context, "/settings_menu",
                    arguments: {"database": _database});
              },
              icon: const Icon(Icons.settings))
        ],
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            bottom: Radius.circular(15),
          ),
        ),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(0, 20, 0, 50),
          child: ListView.builder(
            itemCount: quotes.length,
            itemBuilder: (BuildContext context, int index) {
              return Column(
                children: [
                  QuoteWidget(
                    quote: quotes.elementAt(index),
                    database: _database,
                    onQuoteUpdate: () => updateWithQuotesFromDb(),
                  ),
                  const SizedBox(
                    height: 10.0,
                  ),
                ],
              );
            },
          ),
        ),
      ),
      bottomNavigationBar: BottomAppBar(
        shape: const CircularNotchedRectangle(),
        color: Theme.of(context).primaryColor,
        child: Row(
          mainAxisSize: MainAxisSize.max,
          mainAxisAlignment: MainAxisAlignment.start,
          children: <Widget>[
            IconButton(
                // shows about dialog
                onPressed: () {
                  showAboutDialog(
                      context: context,
                      applicationVersion: "0.4",
                      applicationLegalese: "von Milan Bömer",
                      applicationIcon: Expanded(
                        child: Image.asset("assets/app_icon.png",
                            fit: BoxFit.contain),
                      ),
                      children: [
                        RichText(
                          text: TextSpan(
                            style: Theme.of(context).textTheme.bodyMedium,
                            children: const [
                              TextSpan(text: "Sehr experimentell"),
                            ],
                          ),
                        )
                      ]);
                },
                icon: const Icon(Icons.info)),
            // makes bottom app bar bigger
            const SizedBox(
              height: 60.0,
              width: 1.0,
            ),
            TextButton(
              child: const Text("Export"),
              onPressed: () async {
                final String jsonStr = jsonEncode(quotes);
                Directory tempDirectory = await getTemporaryDirectory();
                tempDirectory.path;
                await File("${tempDirectory.path}/zitate.json")
                    .writeAsString(jsonStr);
                Share.shareXFiles([XFile("${tempDirectory.path}/zitate.json")]);
              },
            ),
            // imports quotes from json
            TextButton(
              onPressed: () async {
                FilePickerResult? result =
                    await FilePicker.platform.pickFiles();
                if (result == null) {
                  return;
                }

                File file = File(result.files.single.path ?? "");
                String jsonStr = await file.readAsString();

                for (var i in jsonDecode(jsonStr)) {
                  addQuoteToDb(Quote.fromJson(i));
                }
                await updateWithQuotesFromDb();
              },
              child: const Text("Import"),
            ),
            IconButton(
              onPressed: () {
                final int quoteCount = quotes.length;

                showDialog(
                  context: context,
                  builder: (_) => AlertDialog(
                    title: const Text("Statistik"),
                    content: Text(
                        "$quoteCount Zitat${quoteCount == 1 ? "" : "e"} gesammelt"),
                  ),
                );
              },
              icon: const Icon(Icons.query_stats_rounded),
            ),
            IconButton(
                onPressed: () async {
                  Uri url = Uri.http(
                    "quotes.hopto.org:8080",
                    "/",
                  );
                  try {
                    http.Response response = await http.get(url);

                    Database db = await _database;

                    for (var i in jsonDecode(response.body)) {
                      Uuid uuid = const Uuid();
                      i["id"] = uuid
                          .v4(); // needs to be done since the server doesn't return ids, because you could delete quotes with the id
                      Quote currentQuote = Quote.fromJson(i);
                      await db.delete("quotes",
                          where: "id = ?", whereArgs: [currentQuote.id]);
                      if ((await db.query("quotes",
                              where:
                                  "quote = ? AND context = ? AND author = ? and involvedPersons = ? AND timestamp = ?",
                              whereArgs: [
                            currentQuote.quote,
                            currentQuote.context,
                            currentQuote.author,
                            jsonEncode(currentQuote.involvedPersons),
                            currentQuote.timestamp.toIso8601String(),
                          ]))
                          .isEmpty) {
                        await addQuoteToDb(currentQuote);
                      }
                    }
                    await updateWithQuotesFromDb();
                  } on http.ClientException {
                    showSnackBarMessage(
                        context, "Konnte nicht synchronisieren");
                  }
                },
                icon: const Icon(Icons.download)),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        // adds a new quote
        onPressed: () async {
          final dynamic quote =
              await Navigator.pushNamed(context, "/new_quote_menu");
          await addQuoteToDb(quote);
          await updateWithQuotesFromDb();
        },
        tooltip: "Hinzufügen",
        child: const Icon(Icons.add),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endDocked,
    );
  }
}
