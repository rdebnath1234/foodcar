import { Routes, Route } from "react-router-dom";
import Login from "./pages/Login";
import Home from "./pages/Home"; // example
import UserProfile from "./pages/UserProfile"; // example
export default function App() {
  return (
    <Routes>
      <Route path="/" element={<Login />} />
      <Route path="/home" element={<Home />} />
      <Route path="/profile" element={<UserProfile />} />
    </Routes>
  );
}
