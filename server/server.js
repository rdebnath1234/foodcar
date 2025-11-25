import express from "express";
import mongoose from "mongoose";
import dotenv from "dotenv";
import fs from "fs";
import admin from "firebase-admin";

// ===================
// Load environment variables
// ===================
dotenv.config();

// ===================
// Express app
// ===================
const app = express();
app.use(express.json());
const PORT = process.env.PORT || 5001;

// ===================
// MongoDB connection
// ===================
mongoose
  .connect(process.env.MONGO_URI)
  .then(() => console.log("MongoDB connected successfully"))
  .catch((err) => console.error("MongoDB connection error:", err));

// ===================
// Firebase initialization
// ===================
try {
  const serviceAccount = JSON.parse(
    fs.readFileSync("./firebase-service-account.json", "utf-8")
  );

  admin.initializeApp({
    credential: admin.credential.cert(serviceAccount),
  });

  console.log("Firebase initialized successfully");
} catch (err) {
  console.error("Firebase initialization error:", err);
}

// ===================
// Firestore upload function
// ===================
const uploadFirestoreData = async (collectionName, jsonFilePath) => {
  try {
    const data = JSON.parse(fs.readFileSync(jsonFilePath, "utf-8"));
    const colRef = admin.firestore().collection(collectionName);

    for (const item of data) {
      const docId = item.id || undefined;

      if (docId) {
        const docSnap = await colRef.doc(docId).get();
        if (docSnap.exists) {
          console.log(`Document with id ${docId} already exists in ${collectionName}, skipping.`);
          continue;
        }
      }

      const docRef = docId ? colRef.doc(docId) : colRef.doc();
      await docRef.set(item);
      console.log(`Uploaded document ${docId || docRef.id} to ${collectionName}`);
    }

    console.log(`Finished uploading data to Firestore collection: ${collectionName}`);
  } catch (err) {
    console.error(`Error uploading Firestore data for ${collectionName}:`, err);
  }
};

// ===================
// Start server and upload data
// ===================
app.listen(PORT, async () => {
  console.log(`Server running on port ${PORT}`);

  if (admin.apps.length) {
    await uploadFirestoreData("foodItems", "./data/foodOrders.json");
    await uploadFirestoreData("restaurants", "./data/dining.json");
  } else {
    console.error("Skipping Firestore upload: Firebase not initialized");
  }
});
