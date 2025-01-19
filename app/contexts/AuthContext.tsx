'use client';

import { createContext, useContext, useState, useEffect } from 'react';
import { useRouter } from 'next/navigation';

interface User {
  username: string;
  role: 'admin' | 'user';
}

export interface AuthContextType {
  user: User | null;
  isAuthenticated: boolean;
  login: (username: string, password: string, rememberMe?: boolean) => Promise<void>;
  logout: () => Promise<void>;
  changePassword: (currentPassword: string, newPassword: string) => Promise<void>;
}

const AuthContext = createContext<AuthContextType>({
  user: null,
  isAuthenticated: false,
  login: async () => {},
  logout: async () => {},
  changePassword: async () => {},
});

export function AuthProvider({ children }: { children: React.ReactNode }) {
  const [user, setUser] = useState<User | null>(null);
  const [isAuthenticated, setIsAuthenticated] = useState(false);
  const router = useRouter();

  useEffect(() => {
    // 检查认证状态
    const checkAuth = async () => {
      try {
        const response = await fetch('/api/auth');
        if (response.ok) {
          const data = await response.json();
          setUser(data.user);
          setIsAuthenticated(true);
        }
      } catch (error) {
        console.error('认证检查失败:', error);
      }
    };

    checkAuth();
  }, []);

  const login = async (username: string, password: string, rememberMe = false) => {
    const response = await fetch('/api/auth', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ username, password, rememberMe }),
    });

    if (!response.ok) {
      const data = await response.json();
      throw new Error(data.error || '登录失败');
    }

    const data = await response.json();
    setUser(data.user);
    setIsAuthenticated(true);
  };

  const logout = async () => {
    const response = await fetch('/api/auth', {
      method: 'DELETE',
    });

    if (!response.ok) {
      throw new Error('登出失败');
    }

    setUser(null);
    setIsAuthenticated(false);
    router.push('/');
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
        user,
        isAuthenticated,
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