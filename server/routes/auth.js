import express from "express";
import User from "../models/User.js"; // Your Mongoose User model

const router = express.Router();

// Update user route
router.put("/update-user", async (req, res) => {
  const { uid, name, email, phone } = req.body;

  if (!uid) return res.status(400).json({ error: "UID is required" });

  try {
    // Find user by Firebase UID
    const user = await User.findOne({ firebaseUid: uid });

    if (!user) return res.status(404).json({ error: "User not found" });

    // Update fields if provided
    if (name) user.name = name;
    if (email) user.email = email;
    if (phone) user.phone = phone;

    const updatedUser = await user.save();
    res.json(updatedUser); // Return updated user
  } catch (err) {
    console.error("Update user error:", err);
    res.status(500).json({ error: "Server error" });
  }
});

export default router;
