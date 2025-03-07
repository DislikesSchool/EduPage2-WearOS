import 'package:eduapge2/api.dart';
import 'package:eduapge2/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class Login extends StatefulWidget {
  const Login({super.key, required context});

  @override
  State<Login> createState() => _LoginState();
}

class _LoginState extends State<Login> {
  String email = "";
  String password = "";

  AppLocalizations get local => AppLocalizations.of(context)!;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              TextField(
                decoration: const InputDecoration(
                  hintText: "Username",
                ),
                onChanged: (value) => email = value,
              ),
              TextField(
                decoration: const InputDecoration(
                  hintText: "Password",
                ),
                onChanged: (value) => password = value,
                obscureText: true,
              ),
              ElevatedButton(
                onPressed: () async {
                  SharedPreferences prefs =
                      await SharedPreferences.getInstance();
                  await prefs.setString("email", email);
                  await prefs.setString("password", password);

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
                },
                child: const Text("Login"),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
