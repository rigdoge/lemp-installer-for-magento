import { AuthProvider } from 'react-admin';

export interface AuthContextType {
  isAuthenticated: boolean;
  username: string | null;
  login: (username: string, password: string, rememberMe?: boolean) => Promise<void>;
  logout: () => Promise<void>;
  changePassword: (currentPassword: string, newPassword: string) => Promise<void>;
}

const authProvider: AuthProvider = {
    // 用户登录
    login: async ({ username, password }) => {
        const response = await fetch('/api/auth', {
            method: 'POST',
            body: JSON.stringify({ username, password }),
            headers: new Headers({ 'Content-Type': 'application/json' }),
        });
        
        if (!response.ok) {
            const error = await response.json();
            throw new Error(error.message || '登录失败');
        }

        // 登录成功，保存用户信息
        const user = await response.json();
        localStorage.setItem('user', JSON.stringify(user));
    },

    // 用户登出
    logout: async () => {
        await fetch('/api/auth', { method: 'DELETE' });
        localStorage.removeItem('user');
        return Promise.resolve();
    },

    // 检查错误，如果是认证错误则登出
    checkError: (error) => {
        const status = error.status;
        if (status === 401 || status === 403) {
            localStorage.removeItem('user');
            return Promise.reject();
        }
        return Promise.resolve();
    },

    // 检查认证状态
    checkAuth: () => {
        const user = localStorage.getItem('user');
        return user ? Promise.resolve() : Promise.reject();
    },

    // 获取用户权限
    getPermissions: () => {
        const user = localStorage.getItem('user');
        if (!user) return Promise.reject();
        
        const { role } = JSON.parse(user);
        return Promise.resolve(role);
    },

    // 获取用户身份
    getIdentity: () => {
        const user = localStorage.getItem('user');
        if (!user) return Promise.reject();

        const { id, username, avatar } = JSON.parse(user);
        return Promise.resolve({ 
            id, 
            fullName: username,
            avatar: avatar || undefined 
        });
    }
};

export default authProvider; 