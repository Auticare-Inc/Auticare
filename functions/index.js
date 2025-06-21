const functions = require("firebase-functions");
const admin = require("firebase-admin");
admin.initializeApp();

exports.sendGeofenceAlert = functions.database
    .ref("/alerts/{userId}")
    .onWrite((change, context) => {
      const data = change.after.val();
      if (!data) return null; // Skip delete events

      const userId = context.params.userId;

      const payload = {
        notification: {
          title: "Geofence Alert",
          body: "User has exited the safe zone!",
          sound: "default",
        },
      };

      // Send to topic (userId should match the subscribed topic on the app)
      return admin.messaging().sendToTopic(userId, payload);
    });
