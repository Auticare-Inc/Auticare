const {onCall} = require("firebase-functions/v2/https");
// const functions = require("firebase-functions");
const admin = require("firebase-admin");

admin.initializeApp();

const sendNotificationAlert = onCall(async (event) => {
  const {title, body, token} = event.data;

  if (!title || !body || !token) {
    throw new Error("Missing errors");
  }
  const payload = {
    notification: {
      title: title,
      body: body,
      sound: "default",
    },
    token: token,
  };
  try {
    const response = await admin.messaging().send(payload);
    return {success: true, response};
  } catch (error) {
    console.error("error sending notification:", error);
    throw new Error("Notification failed");
  }
});

module.exports = {
  sendNotificationAlert,
};
