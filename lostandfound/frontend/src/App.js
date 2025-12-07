import React, { useEffect, useState } from "react";
import {
  BrowserRouter as Router,
  Routes,
  Route,
  Navigate,
  Link,
} from "react-router-dom";
import "./App.css";

import LoginPage from "./pages/LoginPage";
import ItemsPage from "./pages/ItemsPage";
import ProfilePage from "./pages/ProfilePage";
import ContactPage from "./pages/ContactPage";
import ReportFormPage from "./pages/ReportFormPage";
import ReportDetailPage from "./pages/ReportDetailPage";
import AdminApprovePage from "./pages/AdminApprovePage";
import AdminStatsPage from "./pages/AdminStatsPage";
import AdminManageReportsPage from "./pages/AdminManageReportsPage";

import { subscribeToAuthChanges } from "./firebaseClient";
import { getCurrentUser, logout as apiLogout } from "./apiClient";
///app setup
export const AuthContext = React.createContext(null);

function AppLayout({ children }) {
  const { user } = React.useContext(AuthContext);

  return (
    <div className="app">
      <header className="app-header">
        <div className="app-header-left">
          <span className="app-title">WIT Lost and Found</span>
        </div>
        <nav className="app-nav">
          {user && (
            <>
              <Link to="/items">Items</Link>
              <Link to="/profile">Profile</Link>
              <Link to="/contact">Contact</Link>
            </>
          )}
        </nav>
        <div className="app-header-right">
          {user && (
            <>
              <span className="app-user">{user.email}</span>
              <button className="btn" onClick={apiLogout}>
                Log out
              </button>
            </>
          )}
        </div>
      </header>
      <main className="app-main">{children}</main>
      <footer className="app-footer">
        Wentworth Lost &amp; Found. Items held up to 30 days.
      </footer>
    </div>
  );
}

function PrivateRoute({ element }) {
  const { user } = React.useContext(AuthContext);
  if (!user) return <Navigate to="/" replace />;
  return element;
}

function AdminRoute({ element }) {
  const { user, me } = React.useContext(AuthContext);
  if (!user) return <Navigate to="/" replace />;
  if (!me?.isAdmin) return <Navigate to="/items" replace />;
  return element;
}

function App() {
  const [authState, setAuthState] = useState({
    user: null,
    me: null,
    loading: true,
  });

  useEffect(() => {
    const unsubscribe = subscribeToAuthChanges(async (firebaseUser) => {
      if (!firebaseUser) {
        setAuthState({ user: null, me: null, loading: false });
        return;
      }
      try {
        const me = await getCurrentUser();
        setAuthState({ user: firebaseUser, me, loading: false });
      } catch (err) {
        console.error(err);
        setAuthState({ user: null, me: null, loading: false });
      }
    });

    return () => unsubscribe();
  }, []);

  if (authState.loading) {
    return <div className="loading">Loading...</div>;
  }

  return (
    <AuthContext.Provider value={authState}>
        <AppLayout>
          <Routes>
            <Route
              path="/"
              element={
                authState.user ? <Navigate to="/items" replace /> : <LoginPage />
              }
            />
            <Route
              path="/items"
              element={<PrivateRoute element={<ItemsPage />} />}
            />
            <Route
              path="/reports/new/:type"
              element={<PrivateRoute element={<ReportFormPage />} />}
            />
            <Route
              path="/reports/:id"
              element={<PrivateRoute element={<ReportDetailPage />} />}
            />
            <Route
              path="/profile"
              element={<PrivateRoute element={<ProfilePage />} />}
            />
            <Route
              path="/contact"
              element={<PrivateRoute element={<ContactPage />} />}
            />
            <Route
              path="/admin/approve"
              element={<AdminRoute element={<AdminApprovePage />} />}
            />
            <Route
              path="/admin/stats"
              element={<AdminRoute element={<AdminStatsPage />} />}
            />
            <Route
              path="/admin/manage"
              element={<AdminRoute element={<AdminManageReportsPage />} />}
            />
          </Routes>
        </AppLayout>
    </AuthContext.Provider>
  );
}

export default App;
