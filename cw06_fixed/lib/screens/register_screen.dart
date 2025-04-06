import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'task_list_screen.dart';

class RegisterScreen extends StatefulWidget {
  final void Function()? toggleTheme;
  final ThemeMode themeMode;

  const RegisterScreen({super.key, this.toggleTheme, this.themeMode = ThemeMode.system});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  String error = '';

  void register() async {
    final email = emailController.text.trim();
    final password = passwordController.text;

    if (email.isEmpty || password.isEmpty) {
      setState(() {
        error = 'Email and password cannot be empty.';
      });
      return;
    }

    try {
      await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => TaskListScreen(
            toggleTheme: widget.toggleTheme ?? () {},
            themeMode: widget.themeMode,
          ),
        ),
      );
    } catch (e) {
      setState(() {
        error = 'Registration failed. Try a new email.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: widget.themeMode == ThemeMode.dark ? Colors.black : const Color(0xFFF5EDF9),
      body: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text("CW06 Register", style: TextStyle(fontSize: 26)),
            const SizedBox(height: 20),
            TextField(controller: emailController, decoration: const InputDecoration(labelText: "Email")),
            TextField(
              controller: passwordController,
              obscureText: true,
              decoration: const InputDecoration(labelText: "Password"),
            ),
            const SizedBox(height: 20),
            ElevatedButton(onPressed: register, child: const Text("Register")),
            if (error.isNotEmpty) Text(error, style: const TextStyle(color: Colors.red)),
          ],
        ),
      ),
    );
  }
}
