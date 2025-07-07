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
      try {
        // Validate event data exists
        if (!event.data || !event.data.data) {
          console.error("Invalid event data received");
          return;
        }

        const listing = event.data.data();

        // Validate required listing data
        if (!listing) {
          console.error("No listing data found in document");
          return;
        }

        // Use fallback values for missing data
        const sellerName = listing.sellerName || "Unknown Seller";
        const listingTitle = listing.title || "Untitled Listing";

        const message = {
          notification: {
            title: "New listing has been submitted",
            body: `Seller ${sellerName} submitted: ${listingTitle}`,
          },
          topic: "admin",
        };

        const response = await admin.messaging().send(message);
        console.log("Notification sent to admin successfully:", response);
      } catch (error) {
        console.error("Error sending notification to admin:", {
          error: error.message,
          code: error.code,
          listingId: event.params && event.params.listingId,
          stack: error.stack,
        });
        // Don't throw - we don't want to retry this function
      }
    },
);

// Notify Seller when listing is approved or rejected
exports.notifySellerOnStatusChange = onDocumentUpdated(
    "listings/{listingId}",
    async (event) => {
      try {
        // Validate event data exists
        if (!event.data || !event.data.before || !event.data.after) {
          console.error("Invalid event data received for status change");
          return;
        }

        const before = event.data.before.data();
        const after = event.data.after.data();

        // Validate document data
        if (!before || !after) {
          console.error("Missing document data in before/after states");
          return;
        }

        // Only proceed if status actually changed
        if (before.status === after.status) {
          return;
        }

        const sellerId = after.user_id;
        if (!sellerId) {
          console.warn("No seller ID found in listing document");
          return;
        }

        // Fetch seller document with error handling
        let sellerDoc;
        try {
          sellerDoc = await admin.firestore().collection("users")
              .doc(sellerId).get();
        } catch (firestoreError) {
          console.error("Error fetching seller document:", {
            sellerId,
            error: firestoreError.message,
          });
          return;
        }

        if (!sellerDoc.exists) {
          console.warn("Seller document not found:", sellerId);
          return;
        }

        const sellerData = sellerDoc.data();
        const fcmToken = sellerData && sellerData.fcmToken;

        if (!fcmToken) {
          console.warn("No FCM token found for seller:", sellerId);
          return;
        }

        let messageBody = "";
        const listingTitle = after.title || "Your listing";

        if (after.status === "approved") {
          messageBody = `Your listing "${listingTitle}" has been approved.`;
        } else if (after.status === "rejected") {
          messageBody = `Your listing "${listingTitle}" has been rejected.`;
        } else {
          console.info("Status change not relevant for notifications:",
              after.status);
          return;
        }

        const message = {
          notification: {
            title: "Listing Status Updated",
            body: messageBody,
          },
          token: fcmToken,
        };

        const response = await admin.messaging().send(message);
        console.log("Notification sent to seller successfully:", {
          sellerId,
          status: after.status,
          response,
        });
      } catch (error) {
        console.error("Error in notifySellerOnStatusChange:", {
          error: error.message,
          code: error.code,
          listingId: event.params && event.params.listingId,
          stack: error.stack,
        });
        // Don't throw - we don't want to retry this function
      }
    },
);

// Notify Buyers when a listing is approved
exports.notifyBuyersOnApprovedListing = onDocumentUpdated(
    "listings/{listingId}",
    async (event) => {
      try {
        // Validate event data exists
        if (!event.data || !event.data.before || !event.data.after) {
          console.error("Invalid event data received for buyer notification");
          return;
        }

        const before = event.data.before.data();
        const after = event.data.after.data();

        // Validate document data
        if (!before || !after) {
          console.error("Missing document data in before/after states");
          return;
        }

        // Only notify if status changed from non-approved to approved
        if (before.status === "approved" || after.status !== "approved") {
          return;
        }

        const listingTitle = after.title || "A new property";

        const message = {
          notification: {
            title: "New Property Available!",
            body: `${listingTitle} is now live. Check it out.`,
          },
          topic: "buyer",
        };

        const response = await admin.messaging().send(message);
        console.log("Notification sent to buyers successfully:", {
          listingId: event.params && event.params.listingId,
          listingTitle,
          response,
        });
      } catch (error) {
        console.error("Error in notifyBuyersOnApprovedListing:", {
          error: error.message,
          code: error.code,
          listingId: event.params && event.params.listingId,
          stack: error.stack,
        });
        // Don't throw - we don't want to retry this function
      }
    },
);
