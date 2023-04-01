import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:dio_http_cache/dio_http_cache.dart';
import 'package:eduapge2/login.dart';
import 'package:flutter/material.dart';
import 'package:flutter_session_manager/flutter_session_manager.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LoadingScreen extends StatefulWidget {
  final Function loadedCallback;

  const LoadingScreen(
      {super.key, required this.sessionManager, required this.loadedCallback});

  final SessionManager sessionManager;

  @override
  State<StatefulWidget> createState() => LoadingScreenState();
}

class LoadingScreenState extends State<LoadingScreen> {
  late SessionManager sessionManager;
  late SharedPreferences sharedPreferences;

  bool runningInit = false;

  Dio dio = Dio();
  double progress = 0.0;
  String loaderText = "Načítání...";

  String baseUrl = "https://lobster-app-z6jfk.ondigitalocean.app/api";

  @override
  void initState() {
    super.initState();

    init();
  }

  Future<void> init() async {
    sharedPreferences = await SharedPreferences.getInstance();
    progress = 0.1;
    loaderText = "Načítání přihlašovacích údajů...";
    dio.interceptors
        .add(DioCacheManager(CacheConfig(baseUrl: baseUrl)).interceptor);
    setState(() {});
    loadUser();
  }

  Future<void> loadUser() async {
    String? failedToken;
    if (sharedPreferences.getString("token") != null) {
      String? token = sharedPreferences.getString("token");
      progress = 0.2;
      loaderText = "Přihlašování...";
      setState(() {});
      Response response = await dio
          .get(
        "$baseUrl/login",
        options: buildCacheOptions(
          const Duration(days: 5),
          forceRefresh: true,
          options: Options(
            headers: {
              "Authorization": "Bearer $token",
            },
          ),
        ),
      )
          .catchError((obj) {
        sharedPreferences.remove("token");
        failedToken = token;
        return Response(
          requestOptions: RequestOptions(path: "$baseUrl/login"),
          statusCode: 500,
        );
      });

      if (response.statusCode == 200) {
        progress = 0.5;
        loaderText = "Přihlášeno";
        setState(() {});
        sessionManager.set('user', response.data);
        return loadTimetable();
      } else {
        failedToken = token;
      }
    } else if (sharedPreferences.getString("email") != null &&
        sharedPreferences.getString("password") != null) {
      String? email = sharedPreferences.getString("email");
      String? password = sharedPreferences.getString("password");

      progress = 0.3;
      loaderText = "Získávání přístupového tokenu...";
      setState(() {});

      Response response = await dio
          .post(
        "$baseUrl/token",
        data: {
          "email": email,
          "password": password,
        },
        options: buildCacheOptions(
          const Duration(days: 5),
          forceRefresh: true,
        ),
      )
          .catchError((obj) {
        return Response(
          requestOptions: RequestOptions(path: "$baseUrl/token"),
          statusCode: 500,
        );
      });

      if (response.statusCode == 500) {
        sharedPreferences.remove("email");
        sharedPreferences.remove("password");
        runningInit = false;
        // ignore: use_build_context_synchronously
        Navigator.push(context,
                MaterialPageRoute(builder: (context) => const LoginPage()))
            .then((value) => init());
      } else {
        if (response.data["token"] == failedToken) {
          sharedPreferences.remove("email");
          sharedPreferences.remove("password");
          runningInit = false;
          // ignore: use_build_context_synchronously
          Navigator.push(context,
                  MaterialPageRoute(builder: (context) => const LoginPage()))
              .then((value) => init());
        } else {
          sessionManager.set("token", response.data["token"]);
          loaderText = "Ověřování...";
          setState(() {});
          response = await dio
              .get(
            "$baseUrl/login",
            options: buildCacheOptions(
              const Duration(days: 5),
              forceRefresh: true,
              options: Options(
                headers: {
                  "Authorization": "Bearer ${response.data["token"]}",
                },
              ),
            ),
          )
              .catchError((obj) {
            sharedPreferences.remove("token");
            failedToken = response.data["token"];
            return Response(
              requestOptions: RequestOptions(path: "$baseUrl/login"),
              statusCode: 500,
            );
          });

          if (response.statusCode == 200) {
            progress = 0.6;
            loaderText = "Přihlášeno";
            setState(() {});
            sessionManager.set('user', response.data);
            return loadTimetable();
          } else {
            runningInit = false;
            // ignore: use_build_context_synchronously
            Navigator.push(context,
                    MaterialPageRoute(builder: (context) => const LoginPage()))
                .then((value) => init());
          }
        }
      }
    } else {
      runningInit = false;
      Navigator.push(context,
              MaterialPageRoute(builder: (context) => const LoginPage()))
          .then((value) => init());
    }
  }

  DateTime getWeekDay() {
    DateTime now = DateTime.now();
    if (now.weekday > 5) {
      now.add(Duration(days: 8 - now.weekday));
    }
    return DateTime(now.year, now.month, now.day);
  }

  Future<void> loadTimetable() async {
    progress = 0.7;
    loaderText = "Stahování rozvrhu...";
    setState(() {});

    String token = sharedPreferences.getString("token")!;

    Response response = await dio.get(
      "$baseUrl/timetable/${getWeekDay().toString()}",
      options: buildCacheOptions(
        const Duration(days: 5),
        forceRefresh: true,
        options: Options(
          headers: {
            "Authorization": "Bearer $token",
          },
        ),
      ),
    );

    sessionManager.set("timetable", response.data);
    return loadMessages();
  }

  Future<void> loadMessages() async {
    progress = 0.9;
    loaderText = "Načítání zpráv...";
    setState(() {});

    String token = sharedPreferences.getString("token")!;

    Response response = await dio.get(
      "$baseUrl/messages",
      options: buildCacheOptions(
        const Duration(days: 5),
        forceRefresh: true,
        options: Options(
          headers: {
            "Authorization": "Bearer $token",
          },
        ),
      ),
    );

    sessionManager.set("messages", jsonEncode(response.data));

    progress = 1.0;
    loaderText = "Hotovo!";
    setState(() {});
    widget.loadedCallback();
  }

  @override
  Widget build(BuildContext context) {
    sessionManager = widget.sessionManager;
    return Column(
      children: [
        LinearProgressIndicator(
          value: progress,
        ),
        const Spacer(),
        const CircularProgressIndicator(),
        Text("\n$loaderText"),
        const Spacer(),
      ],
    );
  }
}
