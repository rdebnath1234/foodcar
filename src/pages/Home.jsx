import React, { useEffect, useState, useContext } from "react";
import { collection, doc, getDoc, getDocs } from "firebase/firestore";
import { db } from "../firebase/firebase";
import { AuthContext } from "../contexts/AuthContext";
import { getAuth, signOut } from "firebase/auth";
import { useNavigate } from "react-router-dom";
import "bootstrap/dist/css/bootstrap.min.css";
import { PencilSquare, StarFill } from "react-bootstrap-icons";

export default function Home() {
  const { user } = useContext(AuthContext);
  const [foodItems, setFoodItems] = useState([]);
  const [restaurants, setRestaurants] = useState([]);
  const [categories, setCategories] = useState([]);
  const [offers, setOffers] = useState([]);
  const [loading, setLoading] = useState(true);
  const [showProfile, setShowProfile] = useState(false);
  const [userData, setUserData] = useState(null);
  const [searchQuery, setSearchQuery] = useState("");
  const [location, setLocation] = useState("Fetching location...");
  const [activeTab, setActiveTab] = useState("food"); // "food" or "restaurants"

  const navigate = useNavigate();
  const auth = getAuth();

  const FALLBACK_AVATAR = "https://i.ibb.co/2FsfXqM/default-avatar.png";

  // Logout handler
  const handleLogout = async () => {
    try {
      await signOut(auth);
      setShowProfile(false);
      navigate("/"); // Redirect to login page
    } catch (err) {
      console.error("Logout error:", err);
    }
  };

  // Fetch data
  useEffect(() => {
    const fetchData = async () => {
      try {
        setLoading(true);

        const foodSnapshot = await getDocs(collection(db, "foodItems"));
        setFoodItems(foodSnapshot.docs.map((d) => ({ id: d.id, ...d.data() })));

        const restaurantSnapshot = await getDocs(collection(db, "restaurants"));
        setRestaurants(restaurantSnapshot.docs.map((d) => ({ id: d.id, ...d.data() })));

        // categories & offers are optional — use placeholders if not present
        try {
          const catSnapshot = await getDocs(collection(db, "categories"));
          setCategories(catSnapshot.docs.map((d) => ({ id: d.id, ...d.data() })));
        } catch {
          setCategories([]);
        }

        try {
          const offerSnapshot = await getDocs(collection(db, "offers"));
          setOffers(offerSnapshot.docs.map((d) => ({ id: d.id, ...d.data() })));
        } catch {
          setOffers([]);
        }

        // Load user profile doc from Firestore if logged in
        if (user?.uid) {
          const userDoc = await getDoc(doc(db, "users", user.uid));
          if (userDoc.exists()) setUserData(userDoc.data());
          else setUserData(null);
        } else {
          setUserData(null);
        }
      } catch (err) {
        console.error("Firestore fetch error:", err);
      } finally {
        setLoading(false);
      }
    };

    fetchData();

    // get browser location (best-effort)
    if (navigator.geolocation) {
      navigator.geolocation.getCurrentPosition(
        async (position) => {
          const { latitude, longitude } = position.coords;
          try {
            const res = await fetch(
              `https://nominatim.openstreetmap.org/reverse?format=jsonv2&lat=${latitude}&lon=${longitude}`
            );
            const data = await res.json();
            setLocation(data.address.city || data.address.town || data.address.village || "Unknown location");
          } catch {
            setLocation(`Lat: ${latitude.toFixed(2)}, Lng: ${longitude.toFixed(2)}`);
          }
        },
        () => setLocation("Location permission denied")
      );
    } else {
      setLocation("Geolocation not supported");
    }
  }, [user]);

  const toggleProfileDrawer = () => setShowProfile((s) => !s);

  // Filters
  const filteredFoodItems = foodItems.filter((f) =>
    f.name?.toLowerCase().includes(searchQuery.toLowerCase())
  );

  const filteredRestaurants = restaurants.filter((r) =>
    r.name?.toLowerCase().includes(searchQuery.toLowerCase()) ||
    r.cuisine?.toLowerCase().includes(searchQuery.toLowerCase())
  );

  if (loading) return <h3 className="text-center mt-5">Loading...</h3>;

  // small helper components for brevity
  const CategoryChip = ({ cat }) => (
    <div
      onClick={() => setSearchQuery(cat.name)}
      style={{
        width: 92,
        minWidth: 92,
        textAlign: "center",
        cursor: "pointer",
      }}
    >
      <div style={{
        width: 72,
        height: 72,
        borderRadius: 18,
        overflow: "hidden",
        margin: "0 auto 8px",
        boxShadow: "0 6px 18px rgba(0,0,0,0.08)"
      }}>
        <img src={cat.imageUrl || "https://source.unsplash.com/80x80/?food"} alt={cat.name} style={{ width: "100%", height: "100%", objectFit: "cover" }} />
      </div>
      <div style={{ fontSize: 13, color: "#333" }}>{cat.name}</div>
    </div>
  );

  const OfferCard = ({ o }) => (
    <div style={{ width: 320, minWidth: 320 }}>
      <div style={{
        borderRadius: 12,
        overflow: "hidden",
        height: 150,
        boxShadow: "0 8px 24px rgba(0,0,0,0.08)"
      }}>
        <img src={o.imageUrl || "https://source.unsplash.com/1200x400/?food,offer"} alt="offer" style={{ width: "100%", height: "100%", objectFit: "cover" }} />
      </div>
    </div>
  );

  const FoodCard = ({ item }) => (
    <div
      key={item.id}
      className="shadow-sm"
      style={{
        width: 220,
        borderRadius: 12,
        overflow: "hidden",
        background: "#fff",
        cursor: "pointer"
      }}
      onClick={() => {
        // open restaurant if item has restaurantId, else no-op
        if (item.restaurantId) navigate(`/restaurant/${item.restaurantId}`);
      }}
    >
      <div style={{ height: 140, overflow: "hidden" }}>
        <img src={item.imageUrl || "https://source.unsplash.com/400x300/?dish"} alt={item.name} style={{ width: "100%", height: "100%", objectFit: "cover" }} />
      </div>
      <div style={{ padding: 12 }}>
        <div style={{ fontWeight: 600, fontSize: 15 }}>{item.name}</div>
        <div style={{ color: "#2a9d8f", marginTop: 6, fontWeight: 600 }}>₹{item.price}</div>
        <div style={{ color: "#666", fontSize: 13, marginTop: 6 }}>{(item.description || "").slice(0, 70)}</div>
      </div>
    </div>
  );

  const RestaurantCard = ({ res }) => (
    <div
      key={res.id}
      onClick={() => navigate(`/restaurant/${res.id}`)}
      style={{
        width: 300,
        minWidth: 300,
        borderRadius: 12,
        overflow: "hidden",
        background: "#fff",
        boxShadow: "0 8px 20px rgba(0,0,0,0.06)",
        cursor: "pointer",
      }}
    >
      <div style={{ height: 160, overflow: "hidden" }}>
        <img src={res.imageUrl || "https://source.unsplash.com/800x600/?restaurant"} alt={res.name} style={{ width: "100%", height: "100%", objectFit: "cover" }} />
      </div>
      <div style={{ padding: 12 }}>
        <div style={{ display: "flex", justifyContent: "space-between", alignItems: "center" }}>
          <div>
            <div style={{ fontWeight: 700, fontSize: 16 }}>{res.name}</div>
            <div style={{ color: "#666", fontSize: 13, marginTop: 4 }}>{res.cuisine || "Multi-cuisine"} • {res.priceLevel ? `₹${res.priceLevel} for one` : "Price N/A"}</div>
          </div>
          <div style={{ textAlign: "right" }}>
            <div style={{ background: "#fff2d9", padding: "6px 8px", borderRadius: 8, fontWeight: 700 }}>
              <StarFill style={{ color: "#f59e0b", verticalAlign: "middle", marginRight: 6 }} />
              {res.rating ?? "4.2"}
            </div>
          </div>
        </div>
        <div style={{ marginTop: 8, color: "#777", fontSize: 13 }}>{res.shortDesc || res.about?.slice(0, 80) || "Popular spot"}</div>
      </div>
    </div>
  );

  return (
    <div style={{ display: "flex" }}>
      {/* Sidebar */}
      <aside style={{
        width: 220,
        height: "100vh",
        position: "fixed",
        left: 0,
        top: 0,
        padding: 20,
        background: "#fff",
        borderRight: "1px solid #eee",
        overflowY: "auto"
      }}>
        <img src="../src/assets/food-delivery-app-logo.png" alt="FoodCar" style={{ width: 140, display: "block", marginBottom: 14 }} />
        <h5 style={{ marginBottom: 18, color: "#222" }}>FoodCar</h5>

        <div style={{ display: "flex", flexDirection: "column", gap: 10 }}>
          <button className={`btn ${activeTab === "food" ? "btn-dark" : "btn-link"}`} onClick={() => setActiveTab("food")}>🍔 Food Orders</button>
          <button className={`btn ${activeTab === "restaurants" ? "btn-dark" : "btn-link"}`} onClick={() => setActiveTab("restaurants")}>🍽️ Restaurants</button>
        </div>
      </aside>

      {/* Main */}
      <main style={{ marginLeft: 220, flex: 1 }}>
        {/* Fixed top bar */}
        <div style={{
          position: "fixed",
          top: 0,
          left: 220,
          right: 0,
          zIndex: 1100,
          background: "#fff",
          borderBottom: "1px solid #eee",
          padding: "14px 20px",
          display: "flex",
          alignItems: "center",
          gap: 20
        }}>
          <div style={{ fontWeight: 700, color: "#333" }}>📍 {location}</div>

          <input
            value={searchQuery}
            onChange={(e) => setSearchQuery(e.target.value)}
            placeholder="Search for dishes, restaurants or cuisines"
            style={{
              flex: 1,
              maxWidth: 720,
              padding: "12px 14px",
              borderRadius: 12,
              border: "1px solid #e6e6e6",
              fontSize: 14
            }}
          />

          <div>
            {userData ? (
              <img
                src={userData.profileUrl || FALLBACK_AVATAR}
                alt="avatar"
                onClick={toggleProfileDrawer}
                style={{ width: 44, height: 44, borderRadius: 12, objectFit: "cover", cursor: "pointer" }}
              />
            ) : (
              <button className="btn btn-sm btn-primary" onClick={() => navigate("/")}>Login</button>
            )}
          </div>
        </div>

        {/* Content (push below fixed top bar) */}
        <div style={{ padding: 24, paddingTop: 104 }}> {/* 104px to clear top bar */}
          {/* Offers */}
          <section style={{ marginBottom: 28 }}>
            <h4 style={{ marginBottom: 12, fontWeight: 700 }}>Latest Offers</h4>
            <div style={{ display: "flex", gap: 16, overflowX: "auto", paddingBottom: 6 }}>
              {offers.length ? offers.map(o => <OfferCard key={o.id} o={o} />)
                : (
                  // placeholder offer cards
                  [1,2,3].map(i => (
                    <div key={i} style={{ width: 320 }}>
                      <div style={{ borderRadius: 12, overflow: "hidden", height: 150 }}>
                        <img src={`https://source.unsplash.com/1200x400/?food,offer,${i}`} alt="offer" style={{ width: "100%", height: "100%", objectFit: "cover" }} />
                      </div>
                    </div>
                  ))
                )}
            </div>
          </section>

          {/* Categories */}
          <section style={{ marginBottom: 28 }}>
            <h4 style={{ marginBottom: 12, fontWeight: 700 }}>Categories</h4>
            <div style={{ display: "flex", gap: 12, overflowX: "auto", paddingBottom: 6 }}>
              {categories.length ? categories.map(cat => <CategoryChip key={cat.id} cat={cat} />)
                : ["Biryani","Pizza","Burger","Desserts","Chinese","South Indian"].map((n, i) => (
                  <CategoryChip key={n + i} cat={{ id: n, name: n, imageUrl: `https://source.unsplash.com/80x80/?${n}` }} />
                ))
              }
            </div>
          </section>

          {/* Recommended (horizontal) */}
          <section style={{ marginBottom: 28 }}>
            <div style={{ display: "flex", justifyContent: "space-between", alignItems: "center", marginBottom: 12 }}>
              <h4 style={{ fontWeight: 700 }}>Recommended for you</h4>
              <small style={{ color: "#666" }}>Based on your taste</small>
            </div>

            <div style={{ display: "flex", gap: 16, overflowX: "auto", paddingBottom: 6 }}>
              {filteredFoodItems.length ? filteredFoodItems.slice(0, 10).map(item => <FoodCard key={item.id} item={item} />)
                : [1,2,3,4].map(i => (
                  <div key={i} style={{ width: 220, borderRadius: 12, background: "#fff", boxShadow: "0 8px 20px rgba(0,0,0,0.04)" }}>
                    <div style={{ height: 140 }}>
                      <img src={`https://source.unsplash.com/400x300/?dish,${i}`} alt="dish" style={{ width: "100%", height: "100%", objectFit: "cover" }} />
                    </div>
                    <div style={{ padding: 12 }}>
                      <div style={{ fontWeight: 600 }}>Sample Dish {i}</div>
                      <div style={{ color: "#2a9d8f", marginTop: 6 }}>₹149</div>
                    </div>
                  </div>
                ))
              }
            </div>
          </section>

          {/* Popular Restaurants (grid-ish horizontal) */}
          <section style={{ marginBottom: 28 }}>
            <div style={{ display: "flex", justifyContent: "space-between", alignItems: "center", marginBottom: 12 }}>
              <h4 style={{ fontWeight: 700 }}>Popular restaurants</h4>
              <small style={{ color: "#666" }}>Trending near you</small>
            </div>

            <div style={{ display: "flex", gap: 16, overflowX: "auto", paddingBottom: 6 }}>
              {filteredRestaurants.length ? filteredRestaurants.slice(0, 12).map(r => <RestaurantCard key={r.id} res={r} />)
                : [1,2,3,4,5].map(i => (
                  <div key={i} style={{ width: 300, borderRadius: 12, overflow: "hidden", background: "#fff", boxShadow: "0 8px 20px rgba(0,0,0,0.04)" }}>
                    <div style={{ height: 160 }}>
                      <img src={`https://source.unsplash.com/800x600/?restaurant,${i}`} alt="res" style={{ width: "100%", height: "100%", objectFit: "cover" }} />
                    </div>
                    <div style={{ padding: 12 }}>
                      <div style={{ fontWeight: 700 }}>Sample Restaurant {i}</div>
                      <div style={{ color: "#666", marginTop: 6 }}>Multi-cuisine • ₹350 for one</div>
                    </div>
                  </div>
                ))
              }
            </div>
          </section>

          {/* All Items / Restaurants (responsive grid below) */}
          <section style={{ marginBottom: 40 }}>
            {activeTab === "food" && (
              <>
                <h4 style={{ marginBottom: 12, fontWeight: 700 }}>All Food Items</h4>
                <div style={{
                  display: "grid",
                  gridTemplateColumns: "repeat(auto-fill, minmax(220px, 1fr))",
                  gap: 16
                }}>
                  {filteredFoodItems.length ? filteredFoodItems.map(fi => (
                    <div key={fi.id} className="shadow-sm" style={{ borderRadius: 12, overflow: "hidden", background: "#fff", cursor: "pointer" }} onClick={() => navigate(fi.restaurantId ? `/restaurant/${fi.restaurantId}` : "/")}>
                      <div style={{ height: 140, overflow: "hidden" }}>
                        <img src={fi.imageUrl || "https://source.unsplash.com/400x300/?food"} alt={fi.name} style={{ width: "100%", height: "100%", objectFit: "cover" }} />
                      </div>
                      <div style={{ padding: 12 }}>
                        <div style={{ fontWeight: 700 }}>{fi.name}</div>
                        <div style={{ marginTop: 6, color: "#2a9d8f", fontWeight: 700 }}>₹{fi.price}</div>
                        <div style={{ color: "#666", marginTop: 8, fontSize: 13 }}>{fi.description?.slice(0, 80)}</div>
                      </div>
                    </div>
                  )) : <p className="text-muted">No food items found.</p>}
                </div>
              </>
            )}

            {activeTab === "restaurants" && (
              <>
                <h4 style={{ marginBottom: 12, fontWeight: 700 }}>All Restaurants</h4>
                <div style={{
                  display: "grid",
                  gridTemplateColumns: "repeat(auto-fill, minmax(300px, 1fr))",
                  gap: 16
                }}>
                  {filteredRestaurants.length ? filteredRestaurants.map(r => (
                    <div key={r.id} onClick={() => navigate(`/restaurant/${r.id}`)} style={{ borderRadius: 12, overflow: "hidden", background: "#fff", boxShadow: "0 8px 20px rgba(0,0,0,0.04)", cursor: "pointer" }}>
                      <div style={{ height: 180, overflow: "hidden" }}>
                        <img src={r.imageUrl || "https://source.unsplash.com/800x600/?restaurant"} alt={r.name} style={{ width: "100%", height: "100%", objectFit: "cover" }} />
                      </div>
                      <div style={{ padding: 12 }}>
                        <div style={{ fontWeight: 800 }}>{r.name}</div>
                        <div style={{ color: "#666", marginTop: 6 }}>{r.cuisine || "Multi-cuisine"} • {r.priceLevel ? `₹${r.priceLevel} for one` : "Price N/A"}</div>
                        <div style={{ marginTop: 8, color: "#777" }}>{r.shortDesc || (r.about && r.about.slice(0, 100))}</div>
                      </div>
                    </div>
                  )) : <p className="text-muted">No restaurants found.</p>}
                </div>
              </>
            )}
          </section>
        </div>
      </main>

      {/* Profile Drawer (right) */}
      <div style={{
        position: "fixed",
        top: 0,
        right: showProfile ? 0 : -400,
        width: 360,
        height: "100vh",
        background: "#fff",
        zIndex: 1500,
        boxShadow: "-8px 0 30px rgba(0,0,0,0.12)",
        transition: "right 220ms ease"
      }}>
        <div style={{ padding: 20 }}>
          <div style={{ display: "flex", justifyContent: "space-between", alignItems: "center" }}>
            <h5 style={{ margin: 0 }}>My Profile</h5>
            <button className="btn btn-sm btn-outline-secondary" onClick={toggleProfileDrawer}>Close</button>
          </div>

          <div style={{ marginTop: 18, textAlign: "center" }}>
            <img src={(userData && (userData.profileUrl || userData.avatar)) || FALLBACK_AVATAR} alt="user" style={{ width: 110, height: 110, borderRadius: 18, objectFit: "cover" }} />
            <h5 style={{ marginTop: 12 }}>{userData?.name || "Guest User"}</h5>
            <div style={{ color: "#666" }}>{userData?.email || userData?.phone || "No contact info"}</div>
          </div>

          <hr style={{ margin: "18px 0" }} />

          <div style={{ display: "flex", flexDirection: "column", gap: 10 }}>
            <button className="btn btn-outline-primary" onClick={() => navigate("/profile")}>Edit Profile</button>
            <button className="btn btn-outline-secondary" onClick={() => navigate("/orders")}>My Orders</button>
            <button className="btn btn-outline-secondary" onClick={() => navigate("/favorites")}>Favorites</button>
            <button className="btn btn-danger" onClick={handleLogout}>Logout</button>
          </div>
        </div>
      </div>

      {/* Backdrop for profile drawer */}
      {showProfile && (
        <div onClick={toggleProfileDrawer} style={{
          position: "fixed",
          top: 0,
          left: 0,
          right: 0,
          bottom: 0,
          background: "rgba(0,0,0,0.28)",
          zIndex: 1400
        }} />
      )}
    </div>
  );
}
