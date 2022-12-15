const functions = require("firebase-functions");
const stripe = require("stripe")(functions.config().stripe.testkey);

const generateIntentResponse = function (intent) {
    switch (intent.status) {
        case 'requires_confirmation': {
            console.log("Payment confirmation needed")
            return {
                clientSecret: intent.client_secret,
                requireAction: true,
                status: intent.status
            }
        }
        case 'requires_action': {
            console.log("Payment action needed")
            return {
                clientSecret: intent.client_secret,
                requireAction: true,
                status: intent.status
            }
        }
        case 'requires_payment_method': {
            return {
                "error": "Requires payment method, your card was denied"
            }
        }
        case 'succeeded': {
            console.log("Payment success")
            return {
                clientSecret: intent.client_secret,
                status: intent.status
            }
        }

    }
    return { error: "Failed" + intent.status }
}

/// Create payment 
exports.createPaymentIntentId = functions.https.onRequest(async (req, res) => {
    try {
        const { paymentMethodId } = req.body;

        const orderAmount = 100000; //in format that two last zeros are cents

        const params = {
            amount: orderAmount,
            currency: "czk",
            payment_method: paymentMethodId,
            payment_method_types: ['card'],
        }

        const intent = await stripe.paymentIntents.create(params);
        return res.send(generateIntentResponse(intent));
    } catch (error) {
        return res.send({ error: error.message });
    }
});

/// Confirms payment when needed
exports.confirmPaymentIntentId = functions.https.onRequest(async (req, res) => {
    const { paymentIntentId } = req.body;

    try {
        if (paymentIntentId) {
            const intent = await stripe.paymentIntents.confirm(paymentIntentId);
            return res.send(generateIntentResponse(intent));
        }
        return res.sendStatus(400);

    } catch (error) {
        return res.send({ error: error.message });
    }
});

/// Payment sheet request
exports.paymentSheet = functions.https.onRequest(async (req, res) => {
    /** 
    TODO: 
     send customerId from frontend, check if exists in stripe (using GET `stripe.customers`), in case that it exists, just create ephemeralKey from the id
     if customer does not exist, create customer in stripe and create ephemeralKey from the id 
    */
    const customer = await stripe.customers.create();

    const ephemeralKey = await stripe.ephemeralKeys.create(
        { customer: customer.id },
        { apiVersion: '2022-11-15' }
    );
    const paymentIntent = await stripe.paymentIntents.create({
        amount: 1099,
        currency: 'eur',
        customer: customer.id,
        automatic_payment_methods: {
            enabled: true,
        },
    });

    res.json({
        clientSecret: paymentIntent.client_secret,
        ephemeralKey: ephemeralKey.secret,
        customer: customer.id,
    });
});

