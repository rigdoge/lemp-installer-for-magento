'use client';

import { createContext, useContext, useState, useEffect } from 'react';
import { useRouter } from 'next/navigation';

interface AuthContextType {
  isAuthenticated: boolean;
  username: string | null;
  login: (username: string, password: string) => Promise<void>;
  logout: () => Promise<void>;
  changePassword: (currentPassword: string, newPassword: string) => Promise<void>;
}

const AuthContext = createContext<AuthContextType>({
  isAuthenticated: false,
  username: null,
  login: async () => {},
  logout: async () => {},
  changePassword: async () => {},
});

export function AuthProvider({ children }: { children: React.ReactNode }) {
  const [isAuthenticated, setIsAuthenticated] = useState(false);
  const [username, setUsername] = useState<string | null>(null);
  const router = useRouter();

  useEffect(() => {
    // 检查认证状态
    const checkAuth = async () => {
      try {
        const response = await fetch('/api/auth/check');
        if (response.ok) {
          const data = await response.json();
          setIsAuthenticated(true);
          setUsername(data.username);
        }
      } catch (error) {
        console.error('Auth check failed:', error);
      }
    };

    checkAuth();
  }, []);

  const login = async (username: string, password: string) => {
    setUsername(username);
    setIsAuthenticated(true);
  };

  const logout = async () => {
    try {
      await fetch('/api/auth', {
        method: 'DELETE',
      });
      setIsAuthenticated(false);
      setUsername(null);
      router.push('/');
    } catch (error) {
      console.error('Logout failed:', error);
    }
  };

  const changePassword = async (currentPassword: string, newPassword: string) => {
    const response = await fetch('/api/auth', {
      method: 'PUT',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ currentPassword, newPassword }),
    });

    if (!response.ok) {
      const data = await response.json();
      throw new Error(data.error || '修改密码失败');
    }
  };

  return (
    <AuthContext.Provider
      value={{
        isAuthenticated,
        username,
        login,
        logout,
        changePassword,
      }}
    >
      {children}
    </AuthContext.Provider>
  );
}

export const useAuth = () => useContext(AuthContext); 