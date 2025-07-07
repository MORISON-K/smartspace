/**
 * Import function triggers from their respective submodules:
 *
 * const {onCall} = require("firebase-functions/v2/https");
 * const {onDocumentWritten} = require("firebase-functions/v2/firestore");
 *
 * See a full list of supported triggers at https://firebase.google.com/docs/functions
 */

const {onRequest} = require("firebase-functions/v2/https");
const logger = require("firebase-functions/logger");

// Create and deploy your first functions
// https://firebase.google.com/docs/functions/get-started

// exports.helloWorld = onRequest((request, response) => {
//   logger.info("Hello logs!", {structuredData: true});
//   response.send("Hello from Firebase!");
// });

const functions = require("firebase-functions");
const admin = require("firebase-admin");
admin.initializeApp();

//Notify Admin when seller uploads a listing
exports.notifyAdminOnNewListing = functions.firestore
.documenent("listings/listingId")
.onCreate( async (snap, context) => {
    const listing =snap.data();

    const payload = {
        notification: {
            title: "New listing has been submitted",
            body: `Seller ${listing.sellerName} submitted a new listing.`
        },
        topic: "admin",
    };

    await admin.messaging().send(messsage);
    console.log("Notification sent to admin");
});