import 'package:flutter/material.dart';
import 'package:flutter_stripe/flutter_stripe.dart';
import 'package:stripe_test/payment_card_textform_screen.dart';
import 'package:stripe_test/payment_sheet_screen.dart';

enum PaymentStatus { init, success, fail, loading }

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  Stripe.publishableKey =
      "pk_test_51MEaDHFSzCxeR9xh5Czq3be8OhzlQS4ySygfwEu2RlFwjMuH7GdRXrIELIWs3vIZQmG9uR78IqpNABoeOQuGfOJ4000C9uxLId"; // add your publishable key
  Stripe.instance.applySettings();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Stripe Playground',
      theme: ThemeData(primaryColor: Colors.black),
      home: const StripePage(),
    );
  }
}

class StripePage extends StatelessWidget {
  const StripePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Stripe"), backgroundColor: Colors.black),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              MaterialButton(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                minWidth: MediaQuery.of(context).size.width,
                color: Colors.black,
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const PaymentSheetScreen()),
                  );
                },
                child: const Text(
                  "Payment Sheet",
                  style: TextStyle(color: Colors.white, fontSize: 16),
                ),
              ),
              const SizedBox(height: 16),
              MaterialButton(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                minWidth: MediaQuery.of(context).size.width,
                color: Colors.black,
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const PaymentCardTextFormScreen()),
                  );
                },
                child: const Text(
                  "Payment Card Form",
                  style: TextStyle(color: Colors.white, fontSize: 16),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
