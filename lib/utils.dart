import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:otp/otp.dart';
import 'package:timezone/data/latest.dart' as timezone;
import 'package:timezone/timezone.dart' as timezone;

const serverUrl = 'quote.hopto.org:8080';
String? loginSecret;
String? userName;

void showSnackBarMessage(BuildContext context, String message) {
  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
    content: Text(message, style: Theme.of(context).textTheme.bodyMedium,),
    backgroundColor: Theme.of(context).colorScheme.errorContainer,
    behavior: SnackBarBehavior.floating,

  ));
}

String generateAuthCode([String? secret]) {
  timezone.initializeTimeZones();
  final germanTimeZone = timezone.getLocation('Europe/Berlin');
  final date = timezone.TZDateTime.from(DateTime.now(), germanTimeZone);

  return OTP.generateTOTPCodeString(secret ?? loginSecret!, date.millisecondsSinceEpoch, algorithm: Algorithm.SHA1, isGoogle: true, interval: 60, length: 10);
}

bool handleInvalidAuth(BuildContext context, http.Response response) {
  if(response.statusCode != 401) {
    return false;
  }

  showSnackBarMessage(context, "Zugangsdaten ungültig");
  return true;
}