import React, { useEffect, useState, useContext } from "react";
import { collection, doc, getDoc, getDocs } from "firebase/firestore";
import { db } from "../firebase/firebase";
import { AuthContext } from "../contexts/AuthContext";
import { getAuth, signOut } from "firebase/auth";
import { useNavigate } from "react-router-dom";
import "bootstrap/dist/css/bootstrap.min.css";
import { PencilSquare, StarFill, ThreeDotsVertical } from "react-bootstrap-icons";
import logo from "../assets/food-delivery-app-logo.png"
// Single-file, self-contained modernized Home component
// Drop this file into your React app (e.g. src/pages/Home.jsx) and ensure
// firebase and AuthContext are configured as in your project.

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
  const [activeTab, setActiveTab] = useState("food");

  const navigate = useNavigate();
  const auth = getAuth();
  const FALLBACK_AVATAR = "https://i.ibb.co/2FsfXqM/default-avatar.png";

  const handleLogout = async () => {
    try {
      await signOut(auth);
      setShowProfile(false);
      navigate("/");
    } catch (err) {
      console.error("Logout error:", err);
    }
  };

  useEffect(() => {
    let mounted = true;
    const fetchData = async () => {
      try {
        setLoading(true);
        const foodSnapshot = await getDocs(collection(db, "foodItems"));
        const restaurantSnapshot = await getDocs(collection(db, "restaurants"));

        if (!mounted) return;

        setFoodItems(foodSnapshot.docs.map((d) => ({ id: d.id, ...d.data() })));
        setRestaurants(restaurantSnapshot.docs.map((d) => ({ id: d.id, ...d.data() })));

        try {
          const catSnapshot = await getDocs(collection(db, "categories"));
          setCategories(catSnapshot.docs.map((d) => ({ id: d.id, ...d.data() })));
        } catch (e) {
          setCategories([]);
        }

        try {
          const offerSnapshot = await getDocs(collection(db, "offers"));
          setOffers(offerSnapshot.docs.map((d) => ({ id: d.id, ...d.data() })));
        } catch (e) {
          setOffers([]);
        }

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
        if (mounted) setLoading(false);
      }
    };

    fetchData();

    if (navigator.geolocation) {
      navigator.geolocation.getCurrentPosition(
        async (position) => {
          const { latitude, longitude } = position.coords;
          try {
            const res = await fetch(
              `https://nominatim.openstreetmap.org/reverse?format=jsonv2&lat=${latitude}&lon=${longitude}`
            );
            const data = await res.json();
            if (mounted)
              setLocation(
                data?.address?.city || data?.address?.town || data?.address?.village || "Unknown location"
              );
          } catch (e) {
            if (mounted) setLocation(`Lat: ${latitude.toFixed(2)}, Lng: ${longitude.toFixed(2)}`);
          }
        },
        () => mounted && setLocation("Location permission denied")
      );
    } else {
      setLocation("Geolocation not supported");
    }

    return () => {
      mounted = false;
    };
  }, [user]);

  const toggleProfileDrawer = () => setShowProfile((s) => !s);

  const filteredFoodItems = foodItems.filter((f) =>
    f.name?.toLowerCase().includes(searchQuery.toLowerCase())
  );

  const filteredRestaurants = restaurants.filter((r) =>
    r.name?.toLowerCase().includes(searchQuery.toLowerCase()) ||
    r.cuisine?.toLowerCase().includes(searchQuery.toLowerCase())
  );

  if (loading) return <div className="loading-root">Loading...</div>;

  /* ---------- Helper components (kept inside same file) ---------- */
  const CategoryChip = ({ cat }) => (
    <div
      onClick={() => setSearchQuery(cat.name || "")}
      className="category-chip"
    >
      <div className="cat-image">
        <img src={cat.imageUrl || `https://source.unsplash.com/80x80/?${cat.name || "food"}`} alt={cat.name} />
      </div>
      <div className="cat-name">{cat.name}</div>
    </div>
  );

  const OfferCard = ({ o }) => (
    <div className="offer-card">
      <img src={o.imageUrl || "https://source.unsplash.com/1200x400/?food,offer"} alt="offer" />
    </div>
  );

  const FoodCard = ({ item }) => (
    <div
      className="food-card card-hover"
      onClick={() => item.restaurantId && navigate(`/restaurant/${item.restaurantId}`)}
    >
      <div className="food-img-wrap">
        <img src={item.imageUrl || "https://source.unsplash.com/400x300/?dish"} alt={item.name} />
      </div>
      <div className="food-body">
        <div className="food-title">{item.name}</div>
        <div className="food-meta">
          <div className="food-price">₹{item.price}</div>
          <div className="food-rating">{item.rating ?? "4.2"} ★</div>
        </div>
        <div className="food-desc">{(item.description || "").slice(0, 80)}</div>
      </div>
    </div>
  );

  const RestaurantCard = ({ res }) => (
    <div className="res-card card-hover" onClick={() => navigate(`/restaurant/${res.id}`)}>
      <div className="res-img">
        <img src={res.imageUrl || "https://source.unsplash.com/800x600/?restaurant"} alt={res.name} />
      </div>
      <div className="res-body">
        <div className="res-head">
          <div>
            <div className="res-name">{res.name}</div>
            <div className="res-sub">{res.cuisine || "Multi-cuisine"} • {res.priceLevel ? `₹${res.priceLevel} for one` : "Price N/A"}</div>
          </div>
          <div className="res-rating">
            <StarFill /> {res.rating ?? "4.2"}
          </div>
        </div>
        <div className="res-desc">{res.shortDesc || res.about?.slice(0, 100) || "Popular spot near you"}</div>
      </div>
    </div>
  );

  return (
    <div className="modern-root">
      {/* Styles injected so file can remain single-file; feel free to move to App.css */}
      <style>{`
        :root{ --accent:#ff4b4b; --muted:#6b7280; --glass: rgba(255,255,255,0.6); }
        .modern-root{ min-height:100vh; display:flex; background: linear-gradient(180deg, #fff7f6 0%, #f6fbff 100%); color:#111; font-family: Inter, 'Segoe UI', Roboto, system-ui, -apple-system; }

        /* Sidebar */
        aside.sidebar{ width:220px; padding:20px; position:fixed; left:0; top:0; bottom:0; border-right:1px solid rgba(17,24,39,0.06); background: linear-gradient(180deg, rgba(255,255,255,0.85), rgba(255,255,255,0.6)); backdrop-filter: blur(6px); }
        .brand{ display:flex; flex-direction:column; align-items:flex-start; gap:8px; }
        .brand img{ width:130px; }
        .brand h5{ margin:0; font-weight:800; letter-spacing: -0.2px; }
        .nav-buttons{ display:flex; flex-direction:column; gap:10px; margin-top:18px; }
        .tab-btn{ padding:10px 14px; border-radius:999px; border:none; font-weight:700; cursor:pointer; }
        .tab-active{ background: var(--accent); color:white; box-shadow: 0 8px 18px rgba(255,75,75,0.16); }
        .tab-inactive{ background: transparent; color:var(--muted); }

        /* Main area */
        main.content{ margin-left:220px; flex:1; }
        .topbar{ position:fixed; left:220px; right:0; top:0; height:72px; display:flex; align-items:center; gap:16px; padding:12px 20px; border-bottom:1px solid rgba(17,24,39,0.06); background: linear-gradient(180deg, rgba(255,255,255,0.85), rgba(255,255,255,0.6)); backdrop-filter: blur(6px); z-index:1100; }
        .loc{ font-weight:700; color: #111; min-width:160px; }
        .search-wrap{ flex:1; display:flex; justify-content:center; }
        .search-input{ width:100%; max-width:760px; border-radius:999px; padding:12px 18px; border:none; box-shadow: 0 6px 20px rgba(16,24,40,0.04); font-size:14px; }
        .avatar-btn img{ width:44px; height:44px; border-radius:10px; cursor:pointer; object-fit:cover; }

        /* page content area */
        .page-pad{ padding:110px 28px 48px 28px; max-width:1400px; margin:0 auto; }

        section h4{ margin-bottom:12px; font-weight:800; }

        /* Offers */
        .offers-row{ display:flex; gap:16px; overflow-x:auto; padding-bottom:6px; }
        .offer-card{ min-width:320px; border-radius:14px; overflow:hidden; box-shadow:0 10px 30px rgba(16,24,40,0.06); }
        .offer-card img{ width:100%; height:150px; object-fit:cover; display:block; }

        /* categories */
        .cats-row{ display:flex; gap:12px; overflow-x:auto; padding-bottom:6px; }
        .category-chip{ width:92px; min-width:92px; text-align:center; cursor:pointer; }
        .cat-image{ width:72px; height:72px; border-radius:14px; overflow:hidden; margin:0 auto 8px; box-shadow:0 8px 22px rgba(16,24,40,0.06); }
        .cat-image img{ width:100%; height:100%; object-fit:cover; }
        .cat-name{ font-size:13px; color:#111; }

        /* horizontal lists */
        .h-list{ display:flex; gap:16px; overflow-x:auto; padding-bottom:6px; }

        /* Card styles */
        .glass-card{ background: rgba(255,255,255,0.8); border-radius:14px; }
        .card-hover{ transition: transform .22s ease, box-shadow .22s ease; }
        .card-hover:hover{ transform: translateY(-6px) scale(1.02); box-shadow:0 20px 40px rgba(16,24,40,0.12); }

        .food-card{ width:240px; border-radius:12px; overflow:hidden; background:white; box-shadow:0 6px 28px rgba(16,24,40,0.04); }
        .food-img-wrap{ height:150px; overflow:hidden; }
        .food-img-wrap img{ width:100%; height:100%; object-fit:cover; display:block; }
        .food-body{ padding:12px; }
        .food-title{ font-weight:800; font-size:16px; }
        .food-meta{ display:flex; justify-content:space-between; align-items:center; margin-top:8px; }
        .food-price{ color:var(--accent); font-weight:800; }
        .food-rating{ background: #fff4f4; padding:6px 8px; border-radius:10px; font-weight:700; }
        .food-desc{ margin-top:8px; color:var(--muted); font-size:13px; }

        .res-card{ width:300px; border-radius:12px; overflow:hidden; background:white; box-shadow:0 8px 28px rgba(16,24,40,0.04); }
        .res-img{ height:160px; overflow:hidden; }
        .res-img img{ width:100%; height:100%; object-fit:cover; }
        .res-body{ padding:12px; }
        .res-name{ font-weight:900; font-size:16px; }
        .res-sub{ color:var(--muted); margin-top:6px; font-size:13px; }
        .res-head{ display:flex; justify-content:space-between; align-items:center; }
        .res-rating{ background:#fff7ed; padding:6px 8px; border-radius:10px; font-weight:800; display:flex; align-items:center; gap:8px; }

        /* grid lists */
        .grid{ display:grid; grid-template-columns: repeat(auto-fill, minmax(220px, 1fr)); gap:16px; }
        .grid-res{ display:grid; grid-template-columns: repeat(auto-fill, minmax(300px, 1fr)); gap:16px; }

        /* profile drawer */
        .profile-drawer{ position:fixed; top:0; right: ${showProfile ? '0' : '-380px'}; width:360px; height:100vh; background: linear-gradient(180deg, rgba(255,255,255,0.85), rgba(255,255,255,0.6)); backdrop-filter: blur(10px); box-shadow:-10px 0 40px rgba(16,24,40,0.12); padding:20px; z-index:1500; transition: right .22s ease; }
        .profile-drawer img{ width:110px; height:110px; border-radius:18px; object-fit:cover; }
        .profile-actions{ display:flex; flex-direction:column; gap:10px; margin-top:12px; }

        /* backdrop */
        .backdrop{ position:fixed; inset:0; background: rgba(0,0,0,0.28); z-index:1400; }

        /* loading */
        .loading-root{ min-height:100vh; display:flex; align-items:center; justify-content:center; font-size:20px; font-weight:700; }

        /* responsive tweaks */
        @media (max-width: 900px){
          aside.sidebar{ display:none; }
          main.content{ margin-left:0; }
          .topbar{ left:0; }
          .page-pad{ padding-left:16px; padding-right:16px; }
          .food-card{ width:200px; }
        }
      `}</style>

      {/* Sidebar */}
      <aside className="sidebar">
        <div className="brand">
          <img src={logo} alt="FoodCar" />
          <h5>FoodCar</h5>
          <div style={{ color: "var(--muted)" }}>Fast. Fresh. Local.</div>
        </div>

        <div className="nav-buttons">
          <button
            className={`tab-btn ${activeTab === "food" ? "tab-active" : "tab-inactive"}`}
            onClick={() => setActiveTab("food")}
          >
            🍔 Food Orders
          </button>

          <button
            className={`tab-btn ${activeTab === "restaurants" ? "tab-active" : "tab-inactive"}`}
            onClick={() => setActiveTab("restaurants")}
          >
            🍽️ Restaurants
          </button>

          <button className="tab-btn tab-inactive" onClick={() => navigate('/offers')}>🎟️ Offers</button>
          <button className="tab-btn tab-inactive" onClick={() => navigate('/orders')}>🧾 My orders</button>
        </div>
      </aside>

      {/* Main */}
      <main className="content">
        <div className="topbar">
          <div className="loc">📍 {location}</div>
          <div className="search-wrap">
            <input
              value={searchQuery}
              onChange={(e) => setSearchQuery(e.target.value)}
              placeholder="Search dishes, restaurants or cuisines"
              className="search-input"
            />
          </div>

          <div className="avatar-btn">
            {userData ? (
              <img src={userData.profileUrl || FALLBACK_AVATAR} alt="avatar" onClick={toggleProfileDrawer} />
            ) : (
              <button className="btn btn-sm btn-primary" onClick={() => navigate('/')}>Login</button>
            )}
          </div>
        </div>

        <div className="page-pad">
          {/* Offers */}
          <section style={{ marginBottom: 28 }}>
            <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
              <h4>Latest Offers</h4>
              <small style={{ color: 'var(--muted)' }}>Hot deals</small>
            </div>

            <div className="offers-row" style={{ marginTop: 8 }}>
              {offers.length ? offers.map(o => <OfferCard key={o.id} o={o} />)
                : [1,2,3].map(i => (
                  <div key={i} className="offer-card">
                    <img src={`https://source.unsplash.com/1200x400/?food,offer,${i}`} alt="offer" />
                  </div>
                ))}
            </div>
          </section>

          {/* Categories */}
          <section style={{ marginBottom: 28 }}>
            <h4>Categories</h4>
            <div className="cats-row" style={{ marginTop: 8 }}>
              {categories.length ? categories.map(cat => <CategoryChip key={cat.id} cat={cat} />)
                : ['Biryani','Pizza','Burger','Desserts','Chinese','South Indian'].map((n,i) => (
                  <CategoryChip key={n+i} cat={{ id:n, name:n, imageUrl:`https://source.unsplash.com/80x80/?${n}` }} />
                ))}
            </div>
          </section>

          {/* Recommended */}
          <section style={{ marginBottom: 28 }}>
            <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
              <h4>Recommended for you</h4>
              <small style={{ color: 'var(--muted)' }}>Based on your taste</small>
            </div>

            <div className="h-list" style={{ marginTop: 8 }}>
              {filteredFoodItems.length ? filteredFoodItems.slice(0, 10).map(item => <FoodCard key={item.id} item={item} />)
                : [1,2,3,4].map(i => (
                  <div key={i} className="glass-card" style={{ width:220, borderRadius:12, overflow:'hidden' }}>
                    <div style={{ height:140 }}>
                      <img src={`https://source.unsplash.com/400x300/?dish,${i}`} alt="dish" style={{ width:'100%', height:'100%', objectFit:'cover' }} />
                    </div>
                    <div style={{ padding:12 }}>
                      <div style={{ fontWeight:600 }}>Sample Dish {i}</div>
                      <div style={{ color:'var(--accent)', marginTop:6, fontWeight:700 }}>₹149</div>
                    </div>
                  </div>
                ))}
            </div>
          </section>

          {/* Popular restaurants */}
          <section style={{ marginBottom: 28 }}>
            <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
              <h4>Popular restaurants</h4>
              <small style={{ color: 'var(--muted)' }}>Trending near you</small>
            </div>

            <div className="h-list" style={{ marginTop: 8 }}>
              {filteredRestaurants.length ? filteredRestaurants.slice(0, 12).map(r => <RestaurantCard key={r.id} res={r} />)
                : [1,2,3,4,5].map(i => (
                  <div key={i} className="res-card">
                    <div className="res-img">
                      <img src={`https://source.unsplash.com/800x600/?restaurant,${i}`} alt="res" />
                    </div>
                    <div className="res-body">
                      <div style={{ fontWeight:700 }}>Sample Restaurant {i}</div>
                      <div style={{ color: 'var(--muted)', marginTop:6 }}>Multi-cuisine • ₹350 for one</div>
                    </div>
                  </div>
                ))}
            </div>
          </section>

          {/* All Items / Restaurants */}
          <section style={{ marginBottom: 40 }}>
            {activeTab === 'food' && (
              <>
                <h4 style={{ marginBottom:12 }}>All Food Items</h4>
                <div className="grid">
                  {filteredFoodItems.length ? filteredFoodItems.map(fi => (
                    <div key={fi.id} className="food-card card-hover" onClick={() => navigate(fi.restaurantId ? `/restaurant/${fi.restaurantId}` : '/')}>
                      <div className="food-img-wrap">
                        <img src={fi.imageUrl || 'https://source.unsplash.com/400x300/?food'} alt={fi.name} />
                      </div>
                      <div className="food-body">
                        <div className="food-title">{fi.name}</div>
                        <div className="food-meta">
                          <div className="food-price">₹{fi.price}</div>
                          <div className="food-rating">{fi.rating ?? '4.2'} ★</div>
                        </div>
                        <div className="food-desc">{fi.description?.slice(0,80)}</div>
                      </div>
                    </div>
                  )) : <p className="text-muted">No food items found.</p>}
                </div>
              </>
            )}

            {activeTab === 'restaurants' && (
              <>
                <h4 style={{ marginBottom:12 }}>All Restaurants</h4>
                <div className="grid-res">
                  {filteredRestaurants.length ? filteredRestaurants.map(r => (
                    <div key={r.id} className="res-card card-hover" onClick={() => navigate(`/restaurant/${r.id}`)}>
                      <div className="res-img">
                        <img src={r.imageUrl || 'https://source.unsplash.com/800x600/?restaurant'} alt={r.name} />
                      </div>
                      <div className="res-body">
                        <div className="res-name">{r.name}</div>
                        <div className="res-sub">{r.cuisine || 'Multi-cuisine'} • {r.priceLevel ? `₹${r.priceLevel} for one` : 'Price N/A'}</div>
                        <div style={{ marginTop:8, color:'var(--muted)' }}>{r.shortDesc || (r.about && r.about.slice(0,100))}</div>
                      </div>
                    </div>
                  )) : <p className="text-muted">No restaurants found.</p>}
                </div>
              </>
            )}
          </section>
        </div>
      </main>

      {/* Profile Drawer */}
      <div className="profile-drawer" aria-hidden={!showProfile}>
        <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
          <h5 style={{ margin: 0 }}>My Profile</h5>
          <button className="btn btn-sm btn-outline-secondary" onClick={toggleProfileDrawer}>Close</button>
        </div>

        <div style={{ marginTop:18, textAlign:'center' }}>
          <img src={(userData && (userData.profileUrl || userData.avatar)) || FALLBACK_AVATAR} alt="user" />
          <h5 style={{ marginTop:12 }}>{userData?.name || 'Guest User'}</h5>
          <div style={{ color:'var(--muted)' }}>{userData?.email || userData?.phone || 'No contact info'}</div>
        </div>

        <hr style={{ margin: '18px 0' }} />

        <div className="profile-actions">
          <button className="btn btn-outline-primary" onClick={() => navigate('/profile')}><PencilSquare style={{ marginRight:8 }} /> Edit Profile</button>
          <button className="btn btn-outline-secondary" onClick={() => navigate('/orders')}>My Orders</button>
          <button className="btn btn-outline-secondary" onClick={() => navigate('/favorites')}>Favorites</button>
          <button className="btn btn-danger" onClick={handleLogout}>Logout</button>
        </div>
      </div>

      {/* Backdrop for profile drawer */}
      {showProfile && <div className="backdrop" onClick={toggleProfileDrawer} />}
    </div>
  );
}
