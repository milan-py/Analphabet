import 'package:anal_phabet/quote.dart';
import 'package:flutter/material.dart';

class NewQuoteMenu extends StatefulWidget {
  const NewQuoteMenu({Key? key}) : super(key: key);

  @override
  State<NewQuoteMenu> createState() => _NewQuoteMenuState();
}

class _NewQuoteMenuState extends State<NewQuoteMenu> {
  int _involvedPersonCount = 1;
  final TextEditingController _quoteController = TextEditingController();
  final TextEditingController _authorController = TextEditingController();
  final TextEditingController _contextController = TextEditingController();

  late Map arguments;

  List<TextEditingController> _involvedPersonControllers = [
    TextEditingController()
  ];

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    _quoteController.dispose();
    _authorController.dispose();

    super.dispose();
  }

  bool hasBeenBuilt = false;

  @override
  Widget build(BuildContext context) {
    arguments = (ModalRoute.of(context)?.settings.arguments ??
        <String, dynamic>{}) as Map;

    if (arguments["quote"] != null && !hasBeenBuilt) {
      final Quote quote = arguments["quote"];

      _quoteController.text = quote.quote;
      _authorController.text = quote.author;
      _contextController.text = quote.context;

      _involvedPersonCount = quote.involvedPersons.length;
      _involvedPersonControllers = List.generate(
          _involvedPersonCount, (index) => TextEditingController());
      for (var i = 0; i < _involvedPersonCount; ++i) {
        _involvedPersonControllers[i].text = quote.involvedPersons.elementAt(i);
      }
    }

    hasBeenBuilt = true;

    return Scaffold(
      appBar: AppBar(
        title: Text(
            arguments["quote"] == null ? "neues Zitat" : "Zitat bearbeiten"),
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            bottom: Radius.circular(15),
          ),
        ),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            children: [
              QuoteMenuField(controller: _quoteController, labelText: "Zitat",),
              const SizedBox(height: 10.0),
              QuoteMenuField(controller: _contextController, labelText: "Kontext",),
              const SizedBox(height: 10.0),
              QuoteMenuField(controller: _authorController, labelText: "Autor",),
              const SizedBox(height: 10.0),
              const Text(
                "involvierte Personen:",
                style: TextStyle(fontSize: 16.0),
              ),
              const SizedBox(height: 5.0),
              Expanded(
                child: ListView.builder(
                  itemCount: _involvedPersonCount + 1,
                  itemBuilder: (BuildContext context, int index) {
                    if (index == _involvedPersonCount) {
                      return IconButton(
                        onPressed: () {
                          setState(() {
                            ++_involvedPersonCount;
                            _involvedPersonControllers
                                .add(TextEditingController());
                          });
                        },
                        icon: const Icon(Icons.add),
                      );
                    }
                    return Padding(
                      padding: const EdgeInsets.fromLTRB(10.0, 0, 10.0, 0),
                      child: Column(
                        children: [
                          Row(
                            children: [
                              Expanded(child: QuoteMenuField(controller: _involvedPersonControllers.elementAt(index), labelText: "",)),
                              IconButton(onPressed: () {
                                setState(() {
                                  --_involvedPersonCount;
                                  _involvedPersonControllers.removeAt(index);
                                });
                              }, icon: const Icon(Icons.delete))
                            ],
                          ),
                          const SizedBox(height: 8.0),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        tooltip: "Erstelle",
        onPressed: () {
          final Quote quote = Quote(
            quote: _quoteController.text,
            context: _contextController.text,
            author: _authorController.text,
            involvedPersons: List.generate(_involvedPersonCount, (index) {
              return _involvedPersonControllers.elementAt(index).text;
            }),
            timestamp: arguments["quote"] == null
                ? DateTime.now()
                : arguments["quote"].timestamp,
          );

          Navigator.pop(context, quote);
        },
        child: const Icon(Icons.check),
      ),
    );
  }
}

class QuoteMenuField extends StatelessWidget {

  const QuoteMenuField({
    Key? key,
    required this.controller, required this.labelText,
  }) : super(key: key);

  final String labelText;
  final TextEditingController controller;

  @override
  Widget build(BuildContext context) {
    return TextField(
      autocorrect: false,
      controller: controller,

      textInputAction: TextInputAction.next,
      decoration: InputDecoration(
          border: const OutlineInputBorder(), labelText: labelText,),
    );
  }
}
