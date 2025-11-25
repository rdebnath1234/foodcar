import React, { useContext, useState } from "react";
import { useNavigate } from "react-router-dom";
import { AuthContext } from "../contexts/AuthContext";

export default function UserProfile() {
  const navigate = useNavigate();
  const {
    user,
    loginUser,
    logoutUser: contextLogoutUser,
    loading,
  } = useContext(AuthContext);

  const [name, setName] = useState(user?.name || "");
  const [email, setEmail] = useState(user?.email || "");
  const [phone, setPhone] = useState(user?.phone || "");
  const [saving, setSaving] = useState(false);

  const BACKEND_URL = import.meta.env.VITE_API_URL; // e.g., http://localhost:5001/api

  if (loading) return <p>Loading user info...</p>;
  if (!user) return <p>No user logged in.</p>;

  // Save updated user to server
  const handleSave = async () => {
    if (!name && !email && !phone) return alert("Enter at least one field");

    setSaving(true);

    try {
      // Get Firebase ID token
      const idToken = await user.getIdToken();

      const res = await fetch(`${BACKEND_URL}/auth/update-user`, {
        method: "PUT",
        headers: {
          "Content-Type": "application/json",
          Authorization: `Bearer ${idToken}`, // <--- IMPORTANT
        },
        body: JSON.stringify({ name, email, phone }),
      });

      if (!res.ok) throw new Error("Failed to update user");

      const updatedUser = await res.json();

      loginUser(updatedUser);

      alert("Profile updated successfully!");
      navigate("/home", { replace: true });
    } catch (err) {
      console.error("Update error:", err);
      alert("Error updating profile");
    } finally {
      setSaving(false);
    }
  };

  const handleLogout = () => {
    contextLogoutUser();
    navigate("/home", { replace: true });
  };

  return (
    <div
      style={{
        padding: "20px",
        maxWidth: "400px",
        border: "1px solid #ccc",
        borderRadius: "10px",
      }}
    >
      <h2>User Profile</h2>

      <div className="mb-2">
        <label>
          <strong>Phone:</strong>
        </label>
        <input
          type="text"
          value={phone}
          onChange={(e) => setPhone(e.target.value)}
          className="form-control"
        />
      </div>

      <div className="mb-2">
        <label>
          <strong>Name:</strong>
        </label>
        <input
          type="text"
          value={name}
          onChange={(e) => setName(e.target.value)}
          className="form-control"
        />
      </div>

      <div className="mb-2">
        <label>
          <strong>Email:</strong>
        </label>
        <input
          type="email"
          value={email}
          onChange={(e) => setEmail(e.target.value)}
          className="form-control"
        />
      </div>

      <p>
        <strong>Firebase UID:</strong> {user.uid}
      </p>

      <button
        onClick={handleSave}
        disabled={saving}
        className="btn btn-primary"
        style={{ marginRight: "10px" }}
      >
        {saving ? "Saving..." : "Save"}
      </button>
      <button onClick={handleLogout} className="btn btn-secondary">
        Logout
      </button>
    </div>
  );
}
