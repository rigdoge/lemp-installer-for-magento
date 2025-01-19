import { AuthProvider } from 'react-admin';

export const authProvider: AuthProvider = {
  login: async ({ username, password }) => {
    const response = await fetch('/api/auth/login', {
      method: 'POST',
      body: JSON.stringify({ username, password }),
      headers: { 'Content-Type': 'application/json' },
    });
    
    if (response.ok) {
      const { token } = await response.json();
      localStorage.setItem('token', token);
      return Promise.resolve();
    }
    return Promise.reject();
  },
  
  logout: () => {
    localStorage.removeItem('token');
    return Promise.resolve();
  },
  
  checkError: ({ status }) => {
    if (status === 401 || status === 403) {
      localStorage.removeItem('token');
      return Promise.reject();
    }
    return Promise.resolve();
  },
  
  checkAuth: () => {
    return localStorage.getItem('token')
      ? Promise.resolve()
      : Promise.reject();
  },
  
  getPermissions: () => {
    const role = localStorage.getItem('role');
    return role ? Promise.resolve(role) : Promise.reject();
  },
  
  getIdentity: async () => {
    const token = localStorage.getItem('token');
    if (!token) return Promise.reject();
    
    const response = await fetch('/api/auth/me', {
      headers: { Authorization: `Bearer ${token}` },
    });
    
    if (response.ok) {
      const identity = await response.json();
      return Promise.resolve(identity);
    }
    return Promise.reject();
  },
}; 