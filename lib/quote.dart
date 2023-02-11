import 'dart:convert';

import 'package:sqflite/sqflite.dart';

class Quote {
  final String quote;
  final String context;
  final String author;
  final List<String> involvedPersons;
  final DateTime timestamp;

  const Quote({
    required this.quote,
    required this.context,
    required this.author,
    required this.involvedPersons,
    required this.timestamp,
  });

  Map<String, String> _toMap() {
    // for json encoding an database insertion
    return {
      "quote": quote,
      "context": context,
      "author": author,
      "involvedPersons": jsonEncode(involvedPersons),
      "timestamp": timestamp.toIso8601String(),
    };
  }

  Map<String, dynamic> toJson() {
    return _toMap();
  }

  factory Quote.fromJson(dynamic json) {
    List<String> involvedPersons = [];
    for (var i in jsonDecode(json["involvedPersons"])) {
      involvedPersons.add(i as String);
    }

    return Quote(
      quote: json["quote"],
      context: json["context"],
      author: json["author"],
      involvedPersons: involvedPersons,
      timestamp: DateTime.parse(json["timestamp"]),
    );
  }

  Future<void> insertToDb(Database db) async {
    await db.insert("quotes", _toMap());
  }

  @override
  String toString() {
    return "Quote(quote: $quote, context: $context, author: $author, involvedPersons: $involvedPersons, timestamp: $timestamp)";
  }
}
