import 'dart:convert';
import 'package:anal_phabet/quote.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

/* for an SQL query which is supposed to have search criteria by Quote object
Example:
  await db.query(
    "quotes",
    where:
        where,
    whereArgs: whereArgs(quote),
  );
 */
String where =
    "quote = ? AND author = ? AND context = ? AND involvedPersons = ?";

List<String> whereArgs(Quote quote) {
  return [
    quote.quote,
    quote.author,
    quote.context,
    jsonEncode(quote.involvedPersons),
  ];
}

void showSnackBarMessage(BuildContext context, String message) {
  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
    content: Text(message),
  ));
}
