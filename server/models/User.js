import mongoose from "mongoose";

const userSchema = new mongoose.Schema({
  firebaseUid: { type: String, required: true, unique: true },
  name: { type: String },
  email: { type: String },
  phone: { type: String },
  profileUrl: { type: String },
  about: { type: String },
  contact: { type: String },
});

const User = mongoose.model("User", userSchema);

export default User; // ✅ Make sure default export is here
