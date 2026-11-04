import { useState, useCallback } from 'react';
import axios from 'axios';
import { refreshAccessToken } from '../lib/refreshToken.js';

const API_URL = import.meta.env.VITE_API_URL || '/api';

export function useApi() {
  const [loading, setLoading] = useState(false);
  const [error, setError]     = useState(null);

  const getHeaders = useCallback((overrideToken) => {
    const token = overrideToken || localStorage.getItem('token');
    return token ? { Authorization: `Bearer ${token}` } : {};
  }, []);

  const request = useCallback(async (method, url, data = null, config = {}, _isRetry = false) => {
    setLoading(true);
    setError(null);
    try {
      const res = await axios({
        method,
        url: `${API_URL}${url}`,
        data,
        headers: { ...getHeaders(), ...config.headers },
        withCredentials: true,
        ...config,
      });
      return res.data;
    } catch (err) {
      // On 401 attempt a silent token refresh, then retry once
      if (err.response?.status === 401 && !_isRetry) {
        try {
          const newToken = await refreshAccessToken();
          const retryRes = await axios({
            method,
            url: `${API_URL}${url}`,
            data,
            headers: { ...getHeaders(newToken), ...config.headers },
            withCredentials: true,
            ...config,
          });
          return retryRes.data;
        } catch {
          localStorage.removeItem('token');
          window.location.href = '/login';
          return;
        }
      }
      const message = err.response?.data?.error || err.message;
      setError(message);
      throw new Error(message);
    } finally {
      setLoading(false);
    }
  }, [getHeaders]);

  const get  = useCallback((url, config)       => request('GET',    url, null, config), [request]);
  const post = useCallback((url, data, config) => request('POST',   url, data, config), [request]);
  const put  = useCallback((url, data, config) => request('PUT',    url, data, config), [request]);
  const del  = useCallback((url, config)       => request('DELETE', url, null, config), [request]);

  return { get, post, put, del, loading, error };
}
