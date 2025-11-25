import React, { useState, useContext } from "react";
import { useNavigate } from "react-router-dom";
import { RecaptchaVerifier, signInWithPhoneNumber } from "firebase/auth";
import { auth, db } from "../firebase/firebase";
import { AuthContext } from "../contexts/AuthContext";
import { doc, getDoc, setDoc } from "firebase/firestore";

export default function LoginUI() {
  const navigate = useNavigate();
  const { loginUser } = useContext(AuthContext);

  const [phone, setPhone] = useState("");
  const [otp, setOtp] = useState("");
  const [step, setStep] = useState(1);
  const [confirmation, setConfirmation] = useState(null);

  // ---------- Setup invisible Recaptcha ----------
  const setupRecaptcha = () => {
    if (!window.recaptchaVerifier) {
      window.recaptchaVerifier = new RecaptchaVerifier(
        auth,
        "recaptcha-container",
        {
          size: "invisible",
        }
      );
    }
    return window.recaptchaVerifier;
  };

  // ---------- Send OTP ----------
  const handleSendOTP = async () => {
    if (!phone || phone.length !== 10)
      return alert("Enter a valid 10-digit phone number");

    try {
      const recaptcha = setupRecaptcha();
      const formattedPhone = "+91" + phone;

      const confirmationResult = await signInWithPhoneNumber(
        auth,
        formattedPhone,
        recaptcha
      );
      setConfirmation(confirmationResult);
      setStep(2);
      alert("OTP Sent!");
    } catch (err) {
      console.error("Send OTP Error:", err);
      alert("Failed to send OTP");
    }
  };

  // ---------- Verify OTP ----------
  const handleVerifyOTP = async () => {
    if (!otp || otp.length !== 6) return alert("Enter a valid 6-digit OTP");
    if (!confirmation) return alert("OTP not sent");

    try {
      const result = await confirmation.confirm(otp);
      const firebaseUser = result.user;

      // Firestore: check user exists
      const userRef = doc(db, "users", firebaseUser.uid);
      const userSnap = await getDoc(userRef);

      let userData;
      if (!userSnap.exists()) {
        // Create user if not exist
        userData = {
          uid: firebaseUser.uid,
          phone: firebaseUser.phoneNumber,
          name: "User",
          email: "",
          profileUrl: "",
        };
        await setDoc(userRef, userData);
      } else {
        userData = userSnap.data();
      }

      // Save in context
      loginUser(userData);

      // Navigate to Home and replace history
      navigate("/home", { replace: true });
    } catch (err) {
      console.error("OTP Verify Error:", err);
      alert("Invalid OTP");
    }
  };

  return (
    <div className="d-flex vh-100">
      {/* Left Side: Login Form */}
      <div className="d-flex flex-column justify-content-center align-items-center w-50 bg-light p-4">
        <div className="card shadow p-4 w-90" style={{ maxWidth: "400px" }}>
          {/* Logo */}
          <div className="text-center mb-4">
            <img
              src="../src/assets/food-delivery-app-logo.png"
              alt="FoodCar Logo"
              style={{ width: "120px" }}
            />
          </div>

          {/* Invisible Recaptcha container */}
          <div id="recaptcha-container"></div>

          {/* Step 1: Phone Input */}
          {step === 1 && (
            <>
              <div className="mb-3">
                <label htmlFor="phone" className="form-label">
                  Mobile Number
                </label>
                <div className="input-group">
                  <span className="input-group-text">+91</span>
                  <input
                    type="text"
                    id="phone"
                    className="form-control"
                    placeholder="Enter 10-digit number"
                    value={phone}
                    onChange={(e) => setPhone(e.target.value.replace(/\D/, ""))}
                    maxLength={10}
                  />
                </div>
              </div>
              <button
                className="btn w-100"
                style={{ backgroundColor: "brown", color: "white" }}
                onClick={handleSendOTP}
              >
                Send OTP
              </button>
            </>
          )}

          {/* Step 2: OTP Input */}
          {step === 2 && (
            <>
              <div className="mb-3">
                <label htmlFor="otp" className="form-label">
                  Enter OTP
                </label>
                <input
                  type="text"
                  id="otp"
                  className="form-control"
                  placeholder="6-digit OTP"
                  value={otp}
                  onChange={(e) => setOtp(e.target.value.replace(/\D/, ""))}
                  maxLength={6}
                />
              </div>
              <button
                className="btn btn-success w-100"
                onClick={handleVerifyOTP}
              >
                Verify OTP
              </button>
            </>
          )}
        </div>
      </div>

      {/* Right Side: FoodCar Banner */}
      <div
        style={{
      flex: 1, // take remaining space
      height: "100vh",
      backgroundImage: "url('../src/assets/food-banner.jpg')",
      backgroundSize: "cover",
      backgroundPosition: "center",
      display: "flex",
      justifyContent: "end",
      alignItems: "center",
    }}
      >
        <h1
          className="text-white text-center fw-bold"
          style={{ textShadow: "2px 2px 4px rgba(0,0,0,0.7)" }}
        >
          Welcome to FoodCar
        </h1>
      </div>
    </div>
  );
}
