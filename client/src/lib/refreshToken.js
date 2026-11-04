import axios from "axios";

const API_URL = import.meta.env.VITE_API_URL || "/api";

let refreshRequest = null;

export function refreshAccessToken() {
  if (!refreshRequest) {
    refreshRequest = axios
      .post(`${API_URL}/auth/refresh`, {}, { withCredentials: true })
      .then((res) => {
        console.log("Refresh token response:", res.data);
        const newToken = res.data.token;
        if (typeof newToken !== "string" || !newToken) {
          throw new Error("Refresh response did not include an access token.");
        }
        localStorage.setItem("token", newToken);
        return newToken;
      })
      .finally(() => {
        refreshRequest = null;
      });
  }

  return refreshRequest;
}
