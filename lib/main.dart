import 'dart:convert';
import 'dart:io';
import 'package:anal_phabet/settings_menu.dart';
import 'package:anal_phabet/utils.dart';
import 'package:flutter/gestures.dart';
import 'package:path_provider/path_provider.dart';
import 'package:anal_phabet/quote.dart';
import 'package:anal_phabet/quote_display.dart';
import 'package:anal_phabet/quote_menu.dart';
import 'package:anal_phabet/login_page.dart';
import 'package:flutter/material.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import 'package:share_plus/share_plus.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher_string.dart';
import 'package:uuid/uuid.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  AndroidOptions getAndroidOptions() => const AndroidOptions(
        encryptedSharedPreferences: true,
      );

  final storage = FlutterSecureStorage(aOptions: getAndroidOptions());
  loginSecret =
      await storage.read(key: 'secret', aOptions: getAndroidOptions());
  userName = await storage.read(key: 'name', aOptions: getAndroidOptions());

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData(
        brightness: Brightness.light,
        useMaterial3: true,
      ),
      darkTheme: ThemeData(
        brightness: Brightness.dark,
        useMaterial3: true,
      ),
      themeMode: ThemeMode.system,
      title: "Analphabet",
      initialRoute: loginSecret == null ? "/login_menu" : "/",
      routes: {
        "/": (context) => const MyHomePage(title: "Analphabet"),
        "/new_quote_menu": (context) => const NewQuoteMenu(),
        "/settings_menu": (context) => const SettingsMenu(),
        "/login_menu": (context) => const LoginPage()
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

    WidgetsBinding.instance.addPostFrameCallback(
      (_) => initializeDb().then(
        (value) {
          updateWithQuotesFromDb();
        },
      ),
    );
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
                    // fixme: Lizenzen können nicht angezeigt werden
                    context: context,
                    applicationVersion: "v1.1",
                    applicationLegalese: "von Milan Bömer",
                    applicationIcon: Expanded(
                      child: Image.asset("assets/app_icon.png",
                          fit: BoxFit.contain),
                    ),
                    children: [
                      RichText(
                        text: TextSpan(
                          style: Theme.of(context).textTheme.bodyMedium,
                          children: [
                            const TextSpan(text: "Discord-Server des Abizeitungs-komitees: "),
                            TextSpan(
                              text: 'https://discord.gg/apXKgdPKXh',
                              style: const TextStyle(
                                  color: Colors.blue,
                                  ),
                              recognizer: TapGestureRecognizer()
                                ..onTap = () {
                                  launchUrlString(
                                      'https://discord.gg/apXKgdPKXh');
                                },
                            ),
                            const TextSpan(text: '\nBei einem Problem mit der App bitte ein Ticket auf dem Discord-Server erstellen.')
                          ],
                        ),
                      )
                    ],
                  );
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
                  Uri url = Uri.https(
                    serverUrl,
                    "/", {'username': userName}
                  );
                  try {
                    http.Response response = await http.get(url, headers: {
                      'auth': generateAuthCode()
                    }).timeout(const Duration(seconds: 4));

                    if(mounted && handleInvalidAuth(context, response)) {
                      return;
                    }

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
