import 'package:eduapge2/l10n/app_localizations.dart';
import 'package:flutter/material.dart';

class Home extends StatefulWidget {
  const Home({super.key, required context});

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> {
  AppLocalizations get local => AppLocalizations.of(context)!;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: ListView(
        children: <Widget>[
          Text("Works!"),
        ],
      ),
    );
  }
}
