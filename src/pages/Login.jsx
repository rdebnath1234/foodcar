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
import { QRCodeCanvas } from "qrcode.react";

const apkUrl = "https://your-apk-link.com";
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

  const setupRecaptcha = async () => {
    if (!window.recaptchaVerifier) {
      window.recaptchaVerifier = new RecaptchaVerifier(
        auth,
        "recaptcha-container",
        { size: "normal" }
      );
    }

    await window.recaptchaVerifier.render();
    return window.recaptchaVerifier;
  };

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
      toast("Failed to send OTP. Try again.");
    }

    setLoading(false);
  };

  useEffect(() => {
    if (timer === 0) return;
    const interval = setTimeout(() => setTimer(timer - 1), 1000);
    return () => clearTimeout(interval);
  }, [timer]);

  const verifyOTP = async () => {
    if (!confirmation) return;
    if (otp.length < 6) return toast("Enter full 6-digit OTP");

    setLoading(true);
    try {
      const result = await confirmation.confirm(otp);
      const user = result.user;

      const userRef = doc(db, "users", user.uid);
      const snap = await getDoc(userRef);

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
      toast("Invalid OTP. Try again.");
    }
    setLoading(false);
  };

  return (
    <div className="d-flex flex-column flex-md-row vh-100 position-relative">
      {/* FIXED LOGIN BOX */}
      <div
        className="d-flex justify-content-center align-items-center p-3 bg-light"
        style={{ width: "350px", minWidth: "350px" }}
      >
        <div className="card shadow p-4 w-100" style={{ maxWidth: "350px" }}>
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

      {/* FULL MAX BANNER */}
      <div
        className="flex-grow-1 d-none d-md-flex justify-content-center align-items-center position-relative"
        style={{
          right: 0,
          top: 0,
          height: "100vh",
          width: "calc(100vw - 350px)",
          backgroundImage: `url(${banner})`,
          backgroundSize: "cover",
          backgroundPosition: "center",
        }}
      >
        {/* Overlay */}
        <div
          style={{
            position: "absolute",
            width: "100%",
            height: "100%",
            background: "rgba(0,0,0,0.45)",
          }}
        ></div>

        <h1
          className="text-white fw-bold text-center position-relative"
          style={{
            fontSize: "3.5rem",
            textShadow: "3px 3px 18px rgba(0,0,0,1)",
          }}
        >
          Welcome to FoodCar
        </h1>
      </div>

      {/* QR BOTTOM CENTER */}
      <div
        className="position-absolute d-flex flex-column align-items-center"
        style={{
          bottom: "20px",
          left: "50%",
          transform: "translateX(-50%)",
        }}
      >
        <QRCodeCanvas value={apkUrl} size={100} />
        <div
          className="text-white mt-2"
          style={{ textShadow: "1px 1px 5px black" }}
        >
          Scan to Download App
        </div>
      </div>
    </div>
  );
}
