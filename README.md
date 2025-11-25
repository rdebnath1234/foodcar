# 🍽️ FoodCar -- Food Ordering Application

FoodCar is a full-stack food ordering application built using **React +
Node.js + MongoDB + Firebase**.\
It allows users to browse restaurants, view menus, place orders, track
delivery, and make secure payments.

------------------------------------------------------------------------

## 🚀 Features

### 👤 **Authentication**

-   Phone number login (Firebase OTP)
-   Secure backend verification
-   User saved in MongoDB

### 🍔 **Food Ordering**

-   Browse menu items\
-   Add to cart\
-   Place orders\
-   Order tracking\
-   User profile

### 💳 **Payments**

-   Razorpay / Stripe integration\
-   Secure checkout flow

### 🔥 **Notifications**

-   Firebase push notifications\
-   Order status updates

### ⭐ **Extras**

-   Reviews & ratings\
-   Loyalty points & rewards\
-   Admin dashboard (menu, orders, users)

------------------------------------------------------------------------

## 🛠️ Tech Stack

### **Frontend**

-   React.js\
-   Vite\
-   Firebase Auth\
-   Tailwind CSS

### **Backend**

-   Node.js\
-   Express.js\
-   MongoDB\
-   Mongoose\
-   Firebase Admin SDK

### **Dev Tools**

-   Git & GitHub\
-   Postman\
-   Render / Railway / Vercel for Deployment

------------------------------------------------------------------------

## 📁 Project Structure

    foodcar/
    ├── client/           # React Frontend
    │   ├── src/
    │   │   ├── components/
    │   │   ├── contexts/
    │   │   ├── pages/
    │   │   └── assets/
    │   └── vite.config.js
    │
    ├── server/           # Node Backend
    │   ├── src/
    │   │   ├── routes/
    │   │   ├── models/
    │   │   ├── controllers/
    │   │   ├── config/
    │   │   └── index.js
    │   └── package.json
    │
    ├── .gitignore
    ├── README.md
    └── package.json

------------------------------------------------------------------------

## ⚙️ Setup & Installation

### 1️⃣ Clone the repository

``` bash
git clone https://github.com/rdebnath1234/foodcar.git
cd foodcar
```

### 2️⃣ Install dependencies

#### Frontend:

``` bash
cd client
npm install
npm run dev
```

#### Backend:

``` bash
cd server
npm install
npm start
```

------------------------------------------------------------------------

## 🔐 Environment Variables

### **server/.env**

    MONGO_URI=your_mongodb_url
    FIREBASE_SERVICE_ACCOUNT=your_firebase_credentials
    JWT_SECRET=your_secret

### **client/.env**

    VITE_FIREBASE_API_KEY=
    VITE_FIREBASE_AUTH_DOMAIN=
    VITE_FIREBASE_PROJECT_ID=
    VITE_FIREBASE_STORAGE_BUCKET=
    VITE_FIREBASE_MESSAGING_SENDER_ID=
    VITE_FIREBASE_APP_ID=

------------------------------------------------------------------------

## 🚢 Deployment

-   Frontend: **Vercel / Netlify**
-   Backend: **Render / Railway**
-   Database: **MongoDB Atlas**
-   OTP Auth: **Firebase Authentication**

------------------------------------------------------------------------

## 📸 Screenshots

(Add UI screenshots here later)

------------------------------------------------------------------------

## 📞 Contact

**Developer:** Riya Debnath Das\
**GitHub:** https://github.com/rdebnath1234
