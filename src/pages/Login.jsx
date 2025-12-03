import React, { useState, useEffect, useRef, useContext } from "react";
import { useNavigate } from "react-router-dom";
import {
  signInWithPhoneNumber,
  RecaptchaVerifier,
  onAuthStateChanged,
} from "firebase/auth";
import { auth, db } from "../firebase/firebase";
import { AuthContext } from "../contexts/AuthContext";
import { doc, getDoc, setDoc } from "firebase/firestore";
import logo from "../assets/food-delivery-app-logo.png";
import banner from "../assets/food-banner.jpg";
import "bootstrap/dist/css/bootstrap.min.css";

const toast = (msg) => alert(msg);

export default function LoginUI() {
  const { loginUser } = useContext(AuthContext);
  const navigate = useNavigate();

  const otpInputRef = useRef(null);

  const [phone, setPhone] = useState("");
  const [otp, setOtp] = useState("");
  const [step, setStep] = useState(1);
  const [confirmation, setConfirmation] = useState(null);
  const [timer, setTimer] = useState(0);
  const [loading, setLoading] = useState(false);

  // Auto redirect if already logged in
  useEffect(() => {
    onAuthStateChanged(auth, async (user) => {
      if (user) {
        const userRef = doc(db, "users", user.uid);
        const snap = await getDoc(userRef);

        if (snap.exists()) {
          loginUser(snap.data());
          navigate("/home", { replace: true });
        }
      }
    });
  }, []);

  // Setup Recaptcha
  const setupRecaptcha = async () => {
    if (!window.recaptchaVerifier) {
      window.recaptchaVerifier = new RecaptchaVerifier(
        auth, // <-- auth FIRST
        "recaptcha-container",
        { size: "normal" }
      );
    }

    await window.recaptchaVerifier.render();
    return window.recaptchaVerifier;
  };

  // Send OTP
  const handleSendOTP = async () => {
    if (phone.length !== 10) return toast("Enter a valid number");

    setLoading(true);

    try {
      const recaptcha = await setupRecaptcha();
      const result = await signInWithPhoneNumber(
        auth,
        `+91${phone}`,
        recaptcha
      );

      setConfirmation(result);
      setTimer(30);
      setStep(2);

      setTimeout(() => otpInputRef.current?.focus(), 300);
      toast("OTP Sent!");
    } catch (err) {
      console.error(err);
      toast("Failed to send OTP. Try again.");
    }

    setLoading(false);
  };

  // Timer logic
  useEffect(() => {
    if (timer === 0) return;
    const interval = setTimeout(() => setTimer(timer - 1), 1000);
    return () => clearTimeout(interval);
  }, [timer]);

  // Verify OTP
  const verifyOTP = async () => {
    if (!confirmation) return;
    if (otp.length < 6) return toast("Enter full 6-digit OTP");

    setLoading(true);
    try {
      const result = await confirmation.confirm(otp);
      const user = result.user;

      // Check Firestore
      const userRef = doc(db, "users", user.uid);
      const snap = await getDoc(userRef);

      // Create user if not exists
      if (!snap.exists()) {
        await setDoc(userRef, {
          uid: user.uid,
          phone: user.phoneNumber,
          createdAt: new Date(),
        });
      }

      loginUser({ uid: user.uid, phone: user.phoneNumber });
      toast("Login Successful!");
      navigate("/home", { replace: true });
    } catch (err) {
      console.error(err);
      toast("Invalid OTP. Try again.");
    }
    setLoading(false);
  };

  return (
    <div className="d-flex flex-column flex-md-row h-100">
      <div className="col-12 col-md-6 d-flex justify-content-center align-items-center p-3 bg-light">
        <div className="card shadow p-4 w-100" style={{ maxWidth: "400px" }}>
          <div className="text-center mb-4">
            <img src={logo} alt="logo" style={{ width: "120px" }} />
          </div>

          {step === 1 && (
            <>
              <label className="fw-semibold">Mobile Number</label>
              <div className="input-group mb-3">
                <span className="input-group-text">+91</span>
                <input
                  disabled={loading}
                  className="form-control"
                  maxLength={10}
                  placeholder="Enter phone"
                  value={phone}
                  onChange={(e) => setPhone(e.target.value.replace(/\D/g, ""))}
                />
              </div>
              <button
                className="btn btn-dark w-100"
                disabled={loading}
                onClick={handleSendOTP}
              >
                {loading ? "Sending..." : "Send OTP"}
              </button>
              <div id="recaptcha-container" className="mt-3"></div>
            </>
          )}

          {step === 2 && (
            <>
              <label className="fw-semibold">Enter OTP</label>
              <input
                ref={otpInputRef}
                disabled={loading}
                className="form-control mb-3"
                maxLength={6}
                placeholder="6-digit OTP"
                value={otp}
                onChange={(e) => setOtp(e.target.value.replace(/\D/g, ""))}
              />

              <button
                className="btn btn-success w-100 mb-3"
                disabled={loading}
                onClick={verifyOTP}
              >
                {loading ? "Verifying..." : "Verify OTP"}
              </button>

              <button
                className="btn btn-outline-primary w-100"
                disabled={timer > 0 || loading}
                onClick={handleSendOTP}
              >
                {timer > 0 ? `Resend OTP in ${timer}s` : "Resend OTP"}
              </button>
            </>
          )}
        </div>
      </div>

      {/* RIGHT BANNER IMAGE */}
      <div
        className="col-12 col-md-6 d-none d-md-flex justify-content-center align-items-center"
        style={{
          backgroundImage: `url(${banner})`,
          backgroundSize: "cover",
          backgroundPosition: "center",
        }}
      >
        <h1
          className="text-white fw-bold shadow-lg text-center"
          style={{ textShadow: "2px 2px 10px black" }}
        >
          Welcome to FoodCar
        </h1>
      </div>
    </div>
  );
}
