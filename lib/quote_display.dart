import 'dart:convert';

import 'package:anal_phabet/quote.dart';
import "package:flutter/material.dart";
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite/sqflite.dart';
import 'package:http/http.dart' as http;

class QuoteWidget extends StatelessWidget {
  const QuoteWidget(
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

  Future<void> editInDb(context) async {
    final dynamic newQuote = await Navigator.pushNamed(
        context, "/new_quote_menu",
        arguments: {"quote": quote});

    if (newQuote == null) {
      return;
    }

    Database db = await database;

    await db.delete("quotes",
        where: "quote = ? AND author = ?",
        whereArgs: [quote.quote, quote.author]);
    await newQuote?.insertToDb(db);
    onQuoteUpdate();
  }

  Future<void> deleteQuote() async {
    Database db = await database;
    await db.delete("quotes",
        where: "quote = ? AND author = ?",
        whereArgs: [quote.quote, quote.author]);
    onQuoteUpdate();
  }

  static void showSnackBarMessage(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(message),
    ));
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 15),
        child: Row(
          children: [
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: Theme.of(context).primaryColor,
                  borderRadius: const BorderRadius.all(Radius.circular(20)),
                ),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(15, 10, 15, 10),
                  child: Column(
                    children: [
                      Text(
                        ",,${quote.quote}\"",
                        style: const TextStyle(fontSize: 20),
                      ),
                      Align(
                        alignment: Alignment.centerRight,
                        child: Text("- ${quote.author}"),
                      ),
                      Text(formatDate(quote.timestamp)),
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
                IconButton(
                    onPressed: () async {
                      String? result = await showDialog<String>(
                        context: context,
                        builder: (BuildContext context) => AlertDialog(
                          title: const Text("Löschen?"),
                          actions: [
                            TextButton(
                                onPressed: () => Navigator.pop(context, "Nein"),
                                child: const Text("Nein")),
                            TextButton(
                              onPressed: () => Navigator.pop(context, "Ja"),
                              child: const Text("Ja"),
                            )
                          ],
                        ),
                      );
                      if (result == "Ja") {
                        deleteQuote();
                      }
                    },
                    icon: const Icon(Icons.delete)),
                IconButton(
                  onPressed: () async {
                    Uri url = Uri.http(
                      "quotes.hopto.org:8080",
                      "/",
                    );

                    final SharedPreferences preferences = await SharedPreferences.getInstance();
                    final String name = preferences.getString("name") ?? "";



                    if(name.isEmpty){
                      showSnackBarMessage(context,
                          "Name muss in den Einstellungen gesetzt werden.");
                      return;
                    }

                    try {
                      var quoteJson = quote.toJson();
                      quoteJson["user"] = name;
                      http.Response response = await http.put(url, body: jsonEncode(quoteJson), headers: {
                        "Content-Type": "application/json"
                      });
                      if (response.statusCode == 200) {
                        return;
                      }
                      if (response.statusCode == 429) {
                        showSnackBarMessage(context,
                            "Zu viele Anfragen, 10 pro Tag erlaubt");
                        return;
                      }
                      if (jsonDecode(response.body)["error"] == "duplicate") {
                        showSnackBarMessage(
                            context, "Wurde bereits Hochgeladen");
                        return;
                      }
                    } catch (e) {
                      showSnackBarMessage(
                          context, "Etwas ist schiefgelaufen");
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
