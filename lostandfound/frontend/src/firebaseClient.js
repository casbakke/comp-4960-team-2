// firebaseClient.js
import { initializeApp } from "firebase/app";
import {
  getAuth,
  signInWithPopup,
  OAuthProvider,
  signOut,
  onAuthStateChanged,
} from "firebase/auth";

import { getFirestore } from "firebase/firestore";
import { getStorage, ref, uploadBytes, getDownloadURL } from "firebase/storage";

// firebase config
const firebaseConfig = {
  apiKey: process.env.REACT_APP_FIREBASE_API_KEY,
  authDomain: "wit-campus-lost-and-found.firebaseapp.com",
  projectId: "wit-campus-lost-and-found",
  storageBucket: "wit-campus-lost-and-found.firebasestorage.app",
  messagingSenderId: "559621942645",
  appId: "1:559621942645:web:c5356189c852438926773c",
};

const app = initializeApp(firebaseConfig);

export const auth = getAuth(app);
export const db = getFirestore(app);
export const storage = getStorage(app);

// login provider
const msProvider = new OAuthProvider("microsoft.com");
msProvider.setCustomParameters({ prompt: "select_account" });

//auth functions
export async function loginWithMicrosoft() {
  const result = await signInWithPopup(auth, msProvider);
  const user = result.user;

  if (!user.email.endsWith("@wit.edu")) {
    await auth.signOut();
    throw new Error("You must use a @wit.edu account");
  }

  return user;
}

export async function logout() {
  await signOut(auth);
}

export function subscribeToAuthChanges(callback) {
  return onAuthStateChanged(auth, callback);
}

export async function getIdToken() {
  const user = auth.currentUser;
  return user ? await user.getIdToken() : null;
}

///image   
export async function uploadReportImage(file, key) {
  const storageRef = ref(storage, `report-images/${key}`);
  await uploadBytes(storageRef, file);
  return await getDownloadURL(storageRef);
}
