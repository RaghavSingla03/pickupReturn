import { useState, useEffect } from 'react';
import axios from 'axios';

const API_URL = import.meta.env.VITE_API_URL || '/api';

// /uploads files now require auth. <img>/<a> tags can't send headers, so the
// server issues a short-lived file token appended as ?t= to upload URLs.
// Cached per auth key so admin and user tokens don't mix.
const cache = {};

export async function fetchFileToken(tokenKey = 'token') {
  const cached = cache[tokenKey];
  if (cached && Date.now() < cached.expiresAt - 60_000) return cached.token;
  const auth = localStorage.getItem(tokenKey);
  if (!auth) return null;
  const res = await axios.get(`${API_URL}/documents/token`, {
    headers: { Authorization: `Bearer ${auth}` },
  });
  cache[tokenKey] = {
    token: res.data.token,
    expiresAt: Date.now() + (res.data.expires_in || 900) * 1000,
  };
  return cache[tokenKey].token;
}

// tokenKey: 'token' for driver/shipper pages, 'adminToken' for the admin panel
export function useFileToken(tokenKey = 'token') {
  const [fileToken, setFileToken] = useState(null);
  useEffect(() => {
    let alive = true;
    fetchFileToken(tokenKey)
      .then(t => { if (alive) setFileToken(t); })
      .catch(() => {});
    return () => { alive = false; };
  }, [tokenKey]);
  return fileToken;
}
