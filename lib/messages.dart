import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:dio_http_cache/dio_http_cache.dart';
import 'package:eduapge2/api.dart';
import 'package:eduapge2/message.dart';
import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'package:flutter/material.dart';
import 'package:flutter_session_manager/flutter_session_manager.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:html_unescape/html_unescape.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MessagesPage extends StatefulWidget {
  final SessionManager sessionManager;

  const MessagesPage({super.key, required this.sessionManager});

  @override
  State<MessagesPage> createState() => TimeTablePageState();
}

extension MoveElement<T> on List<T> {
  void move(int from, int to) {
    RangeError.checkValidIndex(from, this, "from", length);
    RangeError.checkValidIndex(to, this, "to", length);
    var element = this[from];
    if (from < to) {
      setRange(from, to, this, from + 1);
    } else {
      setRange(to + 1, from + 1, this, to);
    }
    this[to] = element;
  }
}

class TimeTablePageState extends State<MessagesPage> {
  bool loading = true;
  bool loaded = false;
  late List<dynamic> apidataMsg;
  AppLocalizations? loc;
  bool _isFetching = false;

  late Widget messages;

  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
  }

  @override
  void setState(VoidCallback fn) {
    if (!mounted) return;
    super.setState(fn);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  getData() async {
    setState(() {
      loading = true; //make loading true to show progressindicator
    });

    _scrollController.addListener(() async {
      if (!_isFetching &&
          _scrollController.position.pixels >=
              _scrollController.position.maxScrollExtent - 200) {
        _isFetching = true;
        await _fetchMessages();
        _isFetching = false;
      }
    });
    messages =
        getMessages(EP2Data.getInstance().timeline.items.values.toList());

    loading = false;
    setState(() {}); //refresh UI

    SharedPreferences sp = await SharedPreferences.getInstance();
    if (sp.getBool('quickstart') ?? false) {
      String token = sp.getString("token")!;
      String baseUrl = FirebaseRemoteConfig.instance.getString("testUrl");
      Dio dio = Dio();
      Response response = await dio.get(
        "$baseUrl/api/timeline/recent",
        options: buildCacheOptions(
          const Duration(days: 5),
          maxStale: const Duration(days: 14),
          forceRefresh: true,
          options: Options(
            headers: {
              "Authorization": "Bearer $token",
            },
          ),
        ),
      );
      widget.sessionManager.set("messages", jsonEncode(response.data["Items"]));
      messages = getMessages(response.data["Items"].values.toList());
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    loc ??= AppLocalizations.of(context);
    if (!loaded) {
      loaded = true;
      getData();
    }
    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 0,
      ),
      body: !loading
          ? Stack(
              children: <Widget>[messages],
            )
          : Text(AppLocalizations.of(context)!.loading),
      backgroundColor: Theme.of(context).colorScheme.background,
    );
  }

  Future<void> _pullRefresh() async {
    setState(() {
      loading = true; //make loading true to show progressindicator
    });

    messages =
        getMessages(EP2Data.getInstance().timeline.items.values.toList());

    loading = false;
    setState(() {}); //refresh UI
  }

  Future<void> _fetchMessages() async {
    SharedPreferences sp = await SharedPreferences.getInstance();
    String token = sp.getString("token")!;
    String baseUrl = FirebaseRemoteConfig.instance.getString("testUrl");
    Dio dio = Dio();
    DateTime oldestTimestamp = DateTime.now();
    for (var message in apidataMsg.toList()) {
      DateTime timestamp = DateTime.parse(message["cas_pridania"]);
      if (timestamp.isBefore(oldestTimestamp)) {
        oldestTimestamp = timestamp;
      }
    }

    // Calculate from and to dates
    DateTime from = oldestTimestamp.subtract(const Duration(days: 14));
    DateTime to = oldestTimestamp;

    // Add query parameters for from and to dates
    Response response = await dio.get(
      "$baseUrl/api/timeline",
      queryParameters: {
        "from": from.toIso8601String(),
        "to": to.toIso8601String(),
      },
      options: buildCacheOptions(
        const Duration(days: 5),
        maxStale: const Duration(days: 14),
        forceRefresh: true,
        options: Options(
          headers: {
            "Authorization": "Bearer $token",
          },
        ),
      ),
    );
    widget.sessionManager.set("messages", jsonEncode(response.data["Items"]));
    messages = getMessages(response.data["Items"].values.toList());
    setState(() {});
  }

  Widget getMessages(List<TimelineItem> apidataMsg) {
    HtmlUnescape unescape = HtmlUnescape();
    List<Widget> rows = <Widget>[];
    List<TimelineItem> msgs =
        apidataMsg.where((msg) => msg.type == "sprava").toList();
    msgs.sort((a, b) => b.timeAdded.compareTo(a.timeAdded));
    List<TimelineItem> msgsWOR = List.from(msgs);
    List<Map<String, int>> bump = [];
    for (TimelineItem msg in msgs) {
      if (msg.reactionTo != "") {
        if (!bump.any((element) =>
            element["ineid"]!.compareTo(int.parse(msg.reactionTo)) == 0)) {
          bump.add({
            "ineid": int.parse(msg.reactionTo),
            "index": msgsWOR.indexOf(msg)
          });
          msgsWOR.remove(msg);
        } else {
          msgsWOR.remove(msg);
        }
      }
    }
    for (TimelineItem msg in msgsWOR) {
      bool isImportantMessage = false;
      if (msg.data["Value"]["messageContent"] != null) {
        isImportantMessage = true;
      }
      rows.add(Card(
        //color: msg["isSeen"] ? null : Theme.of(context).colorScheme.tertiaryContainer,
        child: InkWell(
          onTap: () {
            Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (BuildContext buildContext) => MessagePage(
                        sessionManager: widget.sessionManager,
                        id: int.parse(msg.id))));
          },
          child: Padding(
            padding: const EdgeInsets.all(10),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    if (isImportantMessage)
                      const Text(
                        "!  ",
                        style: TextStyle(
                            fontSize: 20, fontWeight: FontWeight.bold),
                      ),
                    Text(
                      msg.ownerName.replaceAll(RegExp(r'\s+'), ' '),
                      style: const TextStyle(fontSize: 18),
                    ),
                    const Icon(
                      Icons.arrow_right_rounded,
                      size: 18,
                    ),
                    Expanded(
                      child: Text(
                        unescape.convert(msg.userName),
                        overflow: TextOverflow.fade,
                        maxLines: 5,
                        softWrap: false,
                        style: const TextStyle(fontSize: 18),
                      ),
                    )
                  ],
                ),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        unescape.convert(msg.text),
                        style: const TextStyle(fontSize: 12),
                        overflow: TextOverflow.fade,
                        maxLines: 5,
                        softWrap: false,
                      ),
                    )
                  ],
                ),
                if (msg.reactionTo != "")
                  for (TimelineItem r in msgs
                      .where((element) =>
                          element.reactionTo == msg.otherId.toString())
                      .toList())
                    Row(
                      children: [
                        const SizedBox(width: 10),
                        const Icon(Icons.subdirectory_arrow_right_rounded),
                        Expanded(
                          child: Card(
                            elevation: 10,
                            child: Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: Text(
                                "${r.ownerName}: ${unescape.convert(r.text)}",
                                softWrap: false,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                if (msg.data["Value"].containsKey("attachements") &&
                    msg.data["Value"]["attachements"].length > 0)
                  Padding(
                    padding: const EdgeInsets.only(top: 5),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        const Icon(
                          Icons.attach_file_rounded,
                          size: 18,
                        ),
                        Text(loc?.messagesAttachments(
                                msg.data["Value"]["attachements"].length) ??
                            ""),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ),
      ));
    }
    for (Map<String, int> b in bump) {
      if (!msgs.any((element) => element.id == b["ineid"].toString())) continue;
      TimelineItem toBump =
          msgs.firstWhere((element) => element.id == b["ineid"].toString());
      rows.move(msgsWOR.indexOf(toBump), b["index"]!);
    }
    return Card(
      elevation: 5,
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Stack(
          children: <Widget>[
            Text(
              AppLocalizations.of(context)!.messagesTitle,
              style: const TextStyle(
                fontSize: 24,
              ),
            ),
            Padding(
                padding: const EdgeInsets.only(top: 40),
                child: RefreshIndicator(
                  onRefresh: _pullRefresh,
                  child: ListView.builder(
                    controller: _scrollController,
                    itemCount: rows.length,
                    itemBuilder: (BuildContext context, int index) {
                      return rows[index];
                    },
                  ),
                )),
          ],
        ),
      ),
    );
  }
}
