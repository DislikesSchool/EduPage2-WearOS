import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:dio_http_cache/dio_http_cache.dart';
import 'package:flutter_session_manager/flutter_session_manager.dart';

class MessagesPage extends StatefulWidget {
  final SessionManager sessionManager;

  const MessagesPage({super.key, required this.sessionManager});

  @override
  State<MessagesPage> createState() => TimeTablePageState();
}

class TimeTablePageState extends State<MessagesPage> {
  bool loading = true;
  var apidata_msg;

  late Widget messages;

  @override
  void initState() {
    getData(); //fetching data
    super.initState();
  }

  getData() async {
    setState(() {
      loading = true; //make loading true to show progressindicator
    });

    apidata_msg = await widget.sessionManager.get('messages');
    messages = getMessages(apidata_msg);

    loading = false;
    setState(() {}); //refresh UI
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 0,
      ),
      body: !loading
          ? Stack(
              children: <Widget>[messages],
            )
          : const Text("Načítání..."),
      backgroundColor: Theme.of(context).colorScheme.background,
    );
  }

  Future<void> _pullRefresh() async {
    setState(() {
      loading = true; //make loading true to show progressindicator
    });

    apidata_msg = await widget.sessionManager.get('messages');
    messages = getMessages(apidata_msg);

    loading = false;
    setState(() {}); //refresh UI
  }

  Widget getMessages(var apidataMsg) {
    List<Widget> rows = <Widget>[];
    apidataMsg ??= [
      {
        "type": "sprava",
        "title": "Načítání...",
        "text": "Nebude to trvat dlouho",
      }
    ];
    apidataMsg = apidataMsg.where((msg) => msg["type"] == "sprava").toList();
    for (Map<String, dynamic> msg in apidataMsg) {
      String attText = msg["attachments"].length < 5
          ? msg["attachments"].length > 1
              ? "y"
              : "a"
          : "";
      rows.add(Card(
        color: msg["isSeen"] ? null : const Color.fromARGB(255, 124, 95, 0),
        child: Padding(
            padding: const EdgeInsets.all(10),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Text(msg["owner"]["firstname"] +
                        " " +
                        msg["owner"]["lastname"]),
                    const Icon(Icons.arrow_right_rounded),
                    Expanded(
                      child: Text(
                        msg["title"],
                        overflow: TextOverflow.fade,
                        maxLines: 5,
                        softWrap: false,
                      ),
                    )
                  ],
                ),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        msg["text"],
                        style: const TextStyle(fontSize: 10),
                        overflow: TextOverflow.fade,
                        maxLines: 5,
                        softWrap: false,
                      ),
                    )
                  ],
                ),
                if (msg["attachments"].length > 0)
                  Padding(
                    padding: const EdgeInsets.only(top: 5),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        const Icon(
                          Icons.attach_file_rounded,
                          size: 18,
                        ),
                        Text(msg["attachments"].length.toString()),
                        Text(" Přípon$attText"),
                      ],
                    ),
                  ),
              ],
            )),
      ));
    }
    return Card(
      elevation: 5,
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Stack(
          children: <Widget>[
            const Text(
              'Zprávy',
              style: TextStyle(
                fontSize: 24,
              ),
            ),
            Padding(
                padding: const EdgeInsets.only(top: 40),
                child: RefreshIndicator(
                  onRefresh: _pullRefresh,
                  child: ListView(
                    children: rows,
                  ),
                )),
          ],
        ),
      ),
    );
  }
}
