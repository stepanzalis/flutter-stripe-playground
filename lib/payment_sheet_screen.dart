import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_stripe/flutter_stripe.dart';
import 'package:http/http.dart';
import 'package:stripe_test/main.dart';

class PaymentSheetScreen extends StatefulWidget {
  const PaymentSheetScreen({Key? key}) : super(key: key);

  @override
  State<PaymentSheetScreen> createState() => _PaymentSheetScreenState();
}

class _PaymentSheetScreenState extends State<PaymentSheetScreen> {
  late CardFormEditController controller;
  PaymentStatus status = PaymentStatus.init;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Payment Sheet"), backgroundColor: Colors.black),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text("Payment status: ${status.name}"),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              child: MaterialButton(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                minWidth: MediaQuery.of(context).size.width / 2,
                color: Colors.black,
                onPressed: () => tryToShowPaymentSheet(),
                child: const Center(
                  child: Text(
                    "Pay",
                    style: TextStyle(color: Colors.white, fontSize: 16),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> tryToShowPaymentSheet() async {
    try {
      setState(() => status = PaymentStatus.loading);
      final paymentData = await _createPaymentSheetIntentId();

      await Stripe.instance.initPaymentSheet(
        paymentSheetParameters: SetupPaymentSheetParameters(
          merchantDisplayName: 'Telus',
          paymentIntentClientSecret: paymentData['clientSecret'],
          customerEphemeralKeySecret: paymentData['ephemeralKey'],
          customerId: paymentData['customer'],
          style: ThemeMode.dark,
        ),
      );

      await Stripe.instance.presentPaymentSheet();
      setState(() => status = PaymentStatus.success);
    } catch (e) {
      setState(() => status = PaymentStatus.fail);
    }
  }

  Future<Map> _createPaymentSheetIntentId() async {
    try {
      final response = await post(
        Uri.parse("https://us-central1-stripe-chr-connect-test.cloudfunctions.net/paymentSheet"),
      );

      return json.decode(response.body);
    } catch (e) {
      setState(() => status = PaymentStatus.fail);
      return {};
    }
  }
}
