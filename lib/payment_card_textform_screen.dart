import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_stripe/flutter_stripe.dart';
import 'package:http/http.dart';
import 'package:stripe_test/main.dart';

class PaymentCardTextFormScreen extends StatefulWidget {
  const PaymentCardTextFormScreen({Key? key}) : super(key: key);

  @override
  State<PaymentCardTextFormScreen> createState() => _PaymentCardTextFormScreenState();
}

class _PaymentCardTextFormScreenState extends State<PaymentCardTextFormScreen> {
  late CardFormEditController controller;
  PaymentStatus status = PaymentStatus.init;

  @override
  void initState() {
    super.initState();
    controller = CardFormEditController();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Payment Card Form"), backgroundColor: Colors.black),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            if (status == PaymentStatus.success)
              const Center(
                child: Text("Payment successful"),
              ),
            if (status == PaymentStatus.fail)
              const Center(
                child: Text("Payment failed"),
              )
            else ...[CardFormField(controller: controller)],
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: MaterialButton(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                minWidth: MediaQuery.of(context).size.width / 2,
                color: Colors.black,
                onPressed: () {
                  if (status == PaymentStatus.success) {
                    Navigator.of(context).pop();
                  } else {
                    tryToPay();
                  }
                },
                child: Center(
                  child: Text(
                    status == PaymentStatus.success || status == PaymentStatus.fail ? "Back" : "Pay",
                    style: const TextStyle(color: Colors.white, fontSize: 16),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  Future<void> tryToPay() async {
    try {
      setState(() => status = PaymentStatus.loading);

      final paymentMethod = await Stripe.instance.createPaymentMethod(
        params: const PaymentMethodParams.card(
          paymentMethodData: PaymentMethodData(billingDetails: BillingDetails()),
        ),
      );

      final paymentIntent = await _postCreatePaymentIntentId(paymentMethod.id);
      debugPrint(paymentIntent.toString());
      final clientSecret = paymentIntent['clientSecret'];

      if (paymentIntent['error'] != null) {
        debugPrint("Payment intent error: ${paymentIntent}");
        setState(() => status = PaymentStatus.fail);
        return;
      }

      // Payment is done
      if (clientSecret != null && paymentIntent['requiresAction'] == null) {
        setState(() => status = PaymentStatus.success);
      }

      // We need to confirm the payment
      if (clientSecret != null && paymentIntent['requiresAction'] == true) {
        await _confirmPaymentIntentId(clientSecret);
      }
    } catch (e) {
      setState(() => status = PaymentStatus.fail);
    }
  }

  Future<void> _confirmPaymentIntentId(String clientSecret) async {
    try {
      final paymentIntent = await Stripe.instance.handleNextAction(clientSecret);
      if (paymentIntent.status == PaymentIntentsStatus.RequiresConfirmation) {
        debugPrint("Required confirmation, sending confirmation request");
        final Map response = await _postConfirmPaymentIntent(paymentIntent.id);

        if (response['error'] != null) {
          debugPrint("Confirmation error: $response");
          setState(() => status = PaymentStatus.fail);
        } else {
          setState(() => status = PaymentStatus.success);
        }
      }
    } catch (e) {
      debugPrint("Confirmation error: $e");
      setState(() => status = PaymentStatus.fail);
    }
  }

  /// API calls
  Future<Map> _postCreatePaymentIntentId(String paymentMethodId) async {
    final response = await post(
      Uri.parse("https://us-central1-stripe-chr-connect-test.cloudfunctions.net/createPaymentIntentId"),
      headers: {"Content-Type": "application/json"},
      body: json.encode({
        "currency": "czk",
        "paymentMethodId": paymentMethodId,
      }),
    );

    return json.decode(response.body);
  }

  Future<Map> _postConfirmPaymentIntent(String paymentIntentId) async {
    try {
      final response = await post(
        Uri.parse("https://us-central1-stripe-chr-connect-test.cloudfunctions.net/confirmPaymentIntentId"),
        headers: {"Content-Type": "application/json"},
        body: json.encode({"paymentIntentId": paymentIntentId}),
      );

      return json.decode(response.body);
    } catch (e) {
      setState(() => status = PaymentStatus.fail);
      return {};
    }
  }
}
