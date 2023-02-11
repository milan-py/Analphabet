import 'package:anal_phabet/quote.dart';
import "package:flutter/material.dart";
import 'package:sqflite/sqflite.dart';

class QuoteWidget extends StatelessWidget {
  const QuoteWidget(
      {Key? key, required this.quote, required this.database, required this.onQuoteUpdate})
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

    int rowsAffected = await db.delete("quotes",
        where: "quote = ? AND author = ?",
        whereArgs: [quote.quote, quote.author]);
    await newQuote?.insertToDb(db);
    onQuoteUpdate();
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
                        const SizedBox(height: 10.0,),
                      ],
                    ),
                  ),
                ),
              ),
              IconButton(onPressed: () async {
                Database db = await database;
                await db.delete("quotes",
                  where: "quote = ? AND author = ?",
                  whereArgs: [quote.quote, quote.author]);
                onQuoteUpdate();
                }, icon: const Icon(Icons.delete)),
            ],
          ),
        ),
        onTap: () {
          editInDb(context);
        });
  }
}
