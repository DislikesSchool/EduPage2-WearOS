import 'package:eduapge2/l10n/app_localizations.dart';
import 'package:eduapge2/pages/quick.dart';
import 'package:flutter/material.dart';
import 'package:rotary_scrollbar/widgets/rotary_scrollbar.dart';

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
      body: RotaryScrollbar(
        controller: PageController(),
        child: PageView(
          scrollDirection: Axis.vertical,
          children: [
            QuickInfo(context: context),
            Container(
              color: Colors.green,
            ),
            Container(
              color: Colors.blue,
            ),
          ],
        ),
      ),
    );
  }
}
