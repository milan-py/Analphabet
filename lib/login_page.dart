import 'dart:async';

import 'package:anal_phabet/utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:qr_code_scanner/qr_code_scanner.dart';
import 'package:http/http.dart' as http;

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage>
    with SingleTickerProviderStateMixin {
  final GlobalKey qrKey = GlobalKey(debugLabel: 'QR');
  QRViewController? controller;

  bool isShowingSnackBar = false;
  bool isAuthorizing = false;

  final TextEditingController usernameController = TextEditingController();

  void _onQRViewCreated(QRViewController controller) {
    this.controller = controller;
    controller.scannedDataStream.listen(
      (scanData) async {
        try {
          if (usernameController.text.isEmpty) {
            showSnackBarTimed(context, 'Name muss zuerst angegeben werden');
            return;
          }

          if (isAuthorizing) {
            return;
          }

          isAuthorizing = true;

          Uri auth = Uri.parse(scanData.code!);
          String secret = auth.queryParameters['secret']!;

          http.Response response = await http.post(
              Uri.https(serverUrl, '/register',
                  {'username': usernameController.text}),
              headers: {'auth': generateAuthCode(secret)}).timeout(const Duration(seconds: 4));
          if (response.statusCode == 401) {
            if (context.mounted) {
              showSnackBarTimed(context, 'Registrierung ungültig');
            }
            Future.delayed(const Duration(seconds: 3), () {
              isAuthorizing = false;
            });

            return;
          }

          if (response.statusCode != 200) {
            if (context.mounted) {
              showSnackBarTimed(context, 'Registrierungsfehler');
            }
            Future.delayed(const Duration(seconds: 3), () {
              isAuthorizing = false;
            });

            return;
          }

          loginSecret = secret;
          userName = usernameController.text;

          AndroidOptions getAndroidOptions() => const AndroidOptions(
                encryptedSharedPreferences: true,
              );

          final storage = FlutterSecureStorage(aOptions: getAndroidOptions());
          await storage.write(
              key: 'secret', value: secret, aOptions: getAndroidOptions());
          await storage.write(key: 'name', value: usernameController.text);

          if (mounted) {
            await Navigator.of(context)
                .pushNamedAndRemoveUntil('/', (Route<dynamic> route) => false);
          }
        } catch (e) {
          print("ERROR: $e");
          if (mounted) {
            showSnackBarTimed(context, 'Fehler beim Scannen');
          }
          isAuthorizing = false;
        }
      },
    );
  }

  void showSnackBarTimed(BuildContext context, String message) {
    if (!isShowingSnackBar) {
      isShowingSnackBar = true;
      showSnackBarMessage(context, message);

      Future.delayed(const Duration(seconds: 3), () {
        isShowingSnackBar = false;
      });
    }
  }

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Text('Login'),
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            bottom: Radius.circular(15),
          ),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(15.0),
        child: Column(
          children: [
            Expanded(
                flex: 5,
                child: QRView(
                  key: qrKey,
                  onQRViewCreated: _onQRViewCreated,
                )),
            const SizedBox(
              height: 20.0,
            ),
            Expanded(
              flex: 4,
              child: TextField(
                controller: usernameController,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  labelText: 'Name',
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
