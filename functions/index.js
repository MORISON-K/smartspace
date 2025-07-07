/**
 * Firebase Functions v2 clean implementation for SmartSpace notifications.
 *
 * This version uses:
 * - onDocumentCreated
 * - onDocumentUpdated
 *
 * Fully deployable without v1 function syntax issues.
 */

const {
  onDocumentCreated,
  onDocumentUpdated,
} = require("firebase-functions/v2/firestore");
const admin = require("firebase-admin");
admin.initializeApp();

// Notify Admin when seller uploads a listing
exports.notifyAdminOnNewListing = onDocumentCreated(
    "listings/{listingId}",
    async (event) => {
      const listing = event.data.data();

      const message = {
        notification: {
          title: "New listing has been submitted",
          body: `Seller ${listing.sellerName} submitted a new listing.`,
        },
        topic: "admin",
      };

      await admin.messaging().send(message);
      console.log("Notification sent to admin");
    },
);

// Notify Seller when listing is approved or rejected
exports.notifySellerOnStatusChange = onDocumentUpdated(
    "listings/{listingId}",
    async (event) => {
      const before = event.data.before.data();
      const after = event.data.after.data();

      if (before.status !== after.status) {
        const sellerId = after.user_id;
        if (!sellerId) return;

        const sellerDoc = await admin.firestore().collection("users")
            .doc(sellerId).get();
        const sellerData = sellerDoc.data();
        const fcmToken = sellerData && sellerData.fcmToken;
        if (!fcmToken) return;

        let messageBody = "";
        if (after.status === "approved") {
          messageBody = `Your listing "${after.title}" has been approved.`;
        } else if (after.status === "rejected") {
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
    },
);

// Notify Buyers when a listing is approved
exports.notifyBuyersOnApprovedListing = onDocumentUpdated(
    "listings/{listingId}",
    async (event) => {
      const before = event.data.before.data();
      const after = event.data.after.data();

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
    },
);
