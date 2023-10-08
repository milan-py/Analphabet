import 'dart:convert';

import 'package:anal_phabet/quote.dart';
import 'package:anal_phabet/utils.dart';
import "package:flutter/material.dart";
import 'package:http/http.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite/sqflite.dart';
import 'package:http/http.dart' as http;

class QuoteWidget extends StatefulWidget {
  QuoteWidget(
      {Key? key,
      required this.quote,
      required this.database,
      required this.onQuoteUpdate})
      : super(key: key);

  final Quote quote;
  final Future<Database> database;

  // callback that triggers after a quote has been edited or deleted
  final onQuoteUpdate;

  static String formatDate(DateTime dt) {
    return "${dt.day}.${dt.month}.${dt.year}";
  }

  @override
  State<QuoteWidget> createState() => _QuoteWidgetState();
}

class _QuoteWidgetState extends State<QuoteWidget> {
  late bool loadedFromServer;

  Future<void> editInDb(context) async {
    final dynamic newQuote = await Navigator.pushNamed(
        context, "/new_quote_menu",
        arguments: {"quote": widget.quote});

    if (newQuote == null) {
      return;
    }

    Database db = await widget.database;

    await db.delete(
      "quotes",
      where: "id = ?",
      whereArgs: [widget.quote.id],
    );
    await newQuote?.insertToDb(db);
    widget.onQuoteUpdate();
  }

  Future<void> deleteQuote() async {
    Database db = await widget.database;
    await db.delete(
      "quotes",
      where: "id = ?",
      whereArgs: [widget.quote.id],
    );
    widget.onQuoteUpdate();
  }

  Future<void> deleteQuoteOnServer(BuildContext context) async {
    try {
      Uri url = Uri.http(
        "quote.hopto.org:8080",
        "/${widget.quote.id}",
      );

      await http.delete(url);
    } on ClientException {
      showSnackBarMessage(context, "Konnte nicht löschen");
    }
  }

  @override
  Widget build(BuildContext context) {
    loadedFromServer = !(widget.quote.user == null || widget.quote.user == "");

    return GestureDetector(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 15),
        child: Row(
          children: [
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: loadedFromServer
                      ? Colors.blueGrey[600]
                      : Theme.of(context).primaryColor,
                  borderRadius: const BorderRadius.all(Radius.circular(20)),
                ),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(15, 10, 15, 10),
                  child: Column(
                    children: [
                      Text(
                        ",,${widget.quote.quote}\"",
                        style: const TextStyle(fontSize: 20),
                      ),
                      Align(
                        alignment: Alignment.centerRight,
                        child: Text("- ${widget.quote.author}"),
                      ),
                      Text(QuoteWidget.formatDate(widget.quote.timestamp)),
                      Text(loadedFromServer
                          ? "${widget.quote.user} - vom Server geladen"
                          : ""),
                      const SizedBox(
                        height: 10.0,
                      ),
                    ],
                  ),
                ),
              ),
            ),
            Column(
              children: [
                loadedFromServer
                    ? Container()
                    : IconButton(
                        onPressed: () async {
                          String? result = await showDialog<String>(
                            context: context,
                            builder: (BuildContext context) => AlertDialog(
                              title: const Text(
                                  "Nur Lokal oder auf dem Server und Lokal löschen?"),
                              actions: [
                                // quote.user == null: not loaded from server
                                TextButton(
                                    onPressed: () => Navigator.pop(
                                        context, "local and server"),
                                    child: const Text(
                                        "Lokal und auf Server löschen")),
                                TextButton(
                                  onPressed: () =>
                                      Navigator.pop(context, "server"),
                                  child: const Text("Nur Auf Server löschen"),
                                ),
                                TextButton(
                                  onPressed: () =>
                                      Navigator.pop(context, "Abbrechen"),
                                  child: const Text("cancel"),
                                ),
                              ],
                            ),
                          );
                          if (result == "server") {
                            deleteQuoteOnServer(context);
                          } else if (result == "local and server") {
                            deleteQuoteOnServer(context);
                            deleteQuote();
                          }
                        },
                        icon: const Icon(Icons.delete)),
                IconButton(
                  onPressed: () async {
                    Uri url = Uri.http(
                      "quote.hopto.org:8080",
                      "/",
                    );

                    final SharedPreferences preferences =
                        await SharedPreferences.getInstance();
                    final String name = preferences.getString("name") ?? "";

                    if (name.isEmpty) {
                      showSnackBarMessage(context,
                          "Name muss in den Einstellungen gesetzt werden.");
                      return;
                    }

                    try {
                      var quoteJson = widget.quote.toJson();
                      quoteJson["user"] = name;
                      http.Response response = await http.put(url,
                          body: jsonEncode(quoteJson),
                          headers: {"Content-Type": "application/json"});
                      if (response.statusCode == 200) {
                        return;
                      }
                      if (response.statusCode == 429) {
                        showSnackBarMessage(
                            context, "Zu viele Anfragen, 10 pro Tag erlaubt");
                        return;
                      }
                      if (jsonDecode(response.body)["error"] == "duplicate") {
                        showSnackBarMessage(
                            context, "Wurde bereits Hochgeladen");
                        return;
                      }
                    } catch (e) {
                      showSnackBarMessage(context, "Etwas ist schiefgelaufen");
                    }
                  },
                  icon: const Icon(Icons.upload),
                )
              ],
            ),
          ],
        ),
      ),
      onTap: () {
        editInDb(context);
      },
    );
  }
}
