/**
 * Import function triggers from their respective submodules:
 *
 * const {onCall} = require("firebase-functions/v2/https");
 * const {onDocumentWritten} = require("firebase-functions/v2/firestore");
 *
 * See a full list of supported triggers at https://firebase.google.com/docs/functions
 */


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
.document("listings/{listingId}")
.onCreate( async (snap, context) => {
    const listing =snap.data();

    const message = {
        notification: {
            title: "New listing has been submitted",
            body: `Seller ${listing.sellerName} submitted a new listing.`
        },
        topic: "admin",
    };

    await admin.messaging().send(message);
    console.log("Notification sent to admin");
});

//Notify Seller when listing is approved or rejected
exports.notifySellerOnStatusChange = functions.firestore
.document("listings/{listingId}")
.onUpdate(async (change, context) => {
    const before = change.before.data();
    const after = change.after.data();

    if (before.status !== after.status) {
        const sellerId = after.user_id;
        if (!sellerId) return;
    
        const sellerDoc = await admin.firestore().collection("users").doc(sellerId).get();
        const sellerData = sellerDoc.data();
        const fcmToken = sellerData && sellerData.fcmToken;
        if(!fcmToken) return;
    
        let messageBody = "";
        if (after.status ==="approved") {
            messageBody = `Your listing "${after.title}" has been approved.`;
        } else if(after.status === "rejected") {
            messageBody = `Your listing "${after.title}" has been rejected.`;
        } else {
            return;
        }
    
        const message = {
            notification: {
                title: "Listing Status Updated",
                body: messageBody,
            },
            token: fcmToken,
        };
    
        await admin.messaging().send(message);
        console.log("Notification sent to seller");
    }
});

//Notify Buyers when a listing is approved
exports.notifyBuyersOnApprovedListing = functions.firestore
  .document("listings/{listingId}")
  .onUpdate(async (change, context) => {
    const before = change.before.data();
    const after = change.after.data();

    if (before.status !== "approved" && after.status === "approved") {
      const message = {
        notification: {
          title: "New Property Available!",
          body: `A new listing "${after.title}" is now live. Check it out.`,
        },
        topic: "buyer",
      };

      await admin.messaging().send(message);
      console.log("Notification sent to buyers.");
    }
  });