import 'package:anal_phabet/utils.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite/sqflite.dart';

class SettingsMenu extends StatefulWidget {
  const SettingsMenu({Key? key}) : super(key: key);

  @override
  State<SettingsMenu> createState() => _SettingsMenuState();
}

class _SettingsMenuState extends State<SettingsMenu> {
  late final SharedPreferences _preferences;
  final TextEditingController _nameController = TextEditingController();

  @override
  void initState() {
    super.initState();
    SharedPreferences.getInstance().then((value) {
      _preferences = value;
      _nameController.text = _preferences.getString("name") ?? "";
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Einstellungen"),
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            bottom: Radius.circular(15.0),
          ),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(15.0),
        child: Column(
          children: [
            TextField(
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                labelText: "Name",
              ),
              controller: _nameController,
            ),
            const Text("nur echte Namen"),
            ElevatedButton(
                onPressed: () async {
                  final arguments =
                      (ModalRoute.of(context)?.settings.arguments ??
                          <String, dynamic>{}) as Map;
                  final Database db = await arguments["database"];
                  final users = await db.query("quotes", columns: ["user"]);

                  final String name = _nameController.text.trim();

                  for(Map i in users){
                    if(mapEquals(i, {"user" : name})){
                      showSnackBarMessage(context, "Nutzer existiert schon");
                      return;
                    }
                  }

                  _preferences.setString("name", _nameController.text);

                  Navigator.pop(context);
                },
                child: const Text("Bestätigen")),
          ],
        ),
      ),
    );
  }
}
