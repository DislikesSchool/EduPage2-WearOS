import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:eduapge2/api.dart';
import 'package:eduapge2/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

class Load extends StatefulWidget {
  const Load({super.key, required context});

  @override
  State<Load> createState() => _LoadState();
}

class _LoadState extends State<Load> {
  bool loading = true;
  bool paired = false;
  bool loggingIn = true;

  AppLocalizations get local => AppLocalizations.of(context)!;

  String code = "";

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    tryLogin();
  }

  void tryLogin() {
    EP2Data.getInstance()
        .init(
      onProgressUpdate: (String info, double progress) {},
      local: AppLocalizations.of(context)!,
    )
        .then((value) {
      if (value) {
        Navigator.pushNamed(context, "/home");
      } else {
        setState(() {
          loggingIn = false;
        });
        getCode();
      }
    });
  }

  void getCode() {
    Dio dio = Dio();
    dio
        .get(
      "https://ep2.vypal.me/qrlogin",
      options: Options(
        responseType: ResponseType.stream,
      ),
    )
        .then((value) {
      value.data.stream.listen((event) async {
        String eventString = String.fromCharCodes(event);

        Map<String, String> eventMap = {};
        List<String> lines = eventString.split('\n');
        for (var line in lines) {
          int idx = line.indexOf(':');
          if (idx != -1) {
            String key = line.substring(0, idx).trim();
            String value = line.substring(idx + 1).trim();
            eventMap[key] = value;
          }
        }

        if (eventMap.containsKey('event') && eventMap['event'] == 'code') {
          setState(() {
            code = eventMap['data'] ?? '';
          });
        } else if (eventMap.containsKey('event') &&
            eventMap['event'] == 'data') {
          Map<String, dynamic> data = eventMap['data'] != null
              ? jsonDecode(eventMap['data'] ?? '{}')
              : {};
          SharedPreferences prefs = await SharedPreferences.getInstance();
          await prefs.setString("email", data['username'] ?? '');
          await prefs.setString("password", data['password'] ?? '');
          await prefs.setString("customEndpoint", data['endpoint'] ?? '');
          await prefs.setString("server", data['server'] ?? '');

          setState(() {
            loggingIn = true;
          });

          bool success = await EP2Data.getInstance().init(
            onProgressUpdate: (String info, double progress) {},
            local: local,
          );
          if (success) {
            Navigator.pushNamed(context, "/home");
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text("Login failed"),
              ),
            );
          }
        }
      });
    }).catchError((error) {
      setState(() {
        code = "";
      });
      getCode();
    });
  }

  @override
  Widget build(BuildContext context) {
    return loggingIn
        ? const Scaffold(
            body: Center(
              child: CircularProgressIndicator(),
            ),
          )
        : Scaffold(
            backgroundColor: Colors.black,
            body: ListView(
              children: <Widget>[
                SizedBox(height: MediaQuery.of(context).size.height / 6),
                AspectRatio(
                  aspectRatio: 1 / 0.6,
                  child: Center(
                    child: code == ""
                        ? const CircularProgressIndicator()
                        : QrImageView(
                            backgroundColor: Colors.grey.shade300,
                            data: "https://ep2.vypal.me/l/$code",
                          ),
                  ),
                ),
                const SizedBox(height: 20),
                const Center(
                  child: Icon(
                    Icons.keyboard_arrow_down_rounded,
                  ),
                ),
                const Center(child: Text("Not working?")),
                Center(
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pushNamed(context, "/login");
                    },
                    child: const Text("Login manually"),
                  ),
                ),
                SizedBox(height: MediaQuery.of(context).size.height / 6),
              ],
            ),
          );
  }
}
