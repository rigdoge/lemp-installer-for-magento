import { NextResponse } from 'next/server';
import { cookies } from 'next/headers';
import { compare, hash } from 'bcrypt';
import { sign, verify } from 'jsonwebtoken';
import { readFile, writeFile } from 'fs/promises';
import path from 'path';

const USERS_FILE = path.join(process.cwd(), 'data', 'users.json');
const JWT_SECRET = process.env.JWT_SECRET || 'your-secret-key';
const SALT_ROUNDS = 10;

interface User {
  username: string;
  password: string;
  lastLogin?: string;
}

// 读取用户数据
async function getUsers(): Promise<User[]> {
  try {
    const data = await readFile(USERS_FILE, 'utf8');
    return JSON.parse(data);
  } catch (error) {
    // 如果文件不存在，创建默认管理员账户
    const defaultAdmin = {
      username: 'admin',
      password: await hash('admin', SALT_ROUNDS),
    };
    await writeFile(USERS_FILE, JSON.stringify([defaultAdmin], null, 2));
    return [defaultAdmin];
  }
}

// 保存用户数据
async function saveUsers(users: User[]) {
  await writeFile(USERS_FILE, JSON.stringify(users, null, 2));
}

// 登录
export async function POST(request: Request) {
  try {
    const { username, password, rememberMe } = await request.json();
    const users = await getUsers();
    const user = users.find(u => u.username === username);

    if (!user || !(await compare(password, user.password))) {
      return NextResponse.json(
        { error: '用户名或密码错误' },
        { status: 401 }
      );
    }

    // 更新最后登录时间
    user.lastLogin = new Date().toISOString();
    await saveUsers(users);

    // 生成 JWT token
    const token = sign(
      { username: user.username },
      JWT_SECRET,
      { expiresIn: rememberMe ? '7d' : '24h' }
    );

    // 设置 cookie
    const cookieOptions = {
      httpOnly: true,
      secure: process.env.NODE_ENV === 'production',
      sameSite: 'strict' as const,
      maxAge: rememberMe ? 7 * 24 * 60 * 60 : 24 * 60 * 60, // 7天或1天
    };

    const response = NextResponse.json({ success: true });
    response.cookies.set('auth', token, cookieOptions);
    return response;
  } catch (error) {
    console.error('Login error:', error);
    return NextResponse.json(
      { error: '登录失败' },
      { status: 500 }
    );
  }
}

// 登出
export async function DELETE() {
  const response = NextResponse.json({ success: true });
  response.cookies.delete('auth');
  return response;
}

// 修改密码
export async function PUT(request: Request) {
  try {
    const { currentPassword, newPassword } = await request.json();
    const token = cookies().get('auth')?.value;

    if (!token) {
      return NextResponse.json(
        { error: '未登录' },
        { status: 401 }
      );
    }

    const decoded = verify(token, JWT_SECRET) as { username: string };
    const users = await getUsers();
    const user = users.find(u => u.username === decoded.username);

    if (!user || !(await compare(currentPassword, user.password))) {
      return NextResponse.json(
        { error: '当前密码错误' },
        { status: 401 }
      );
    }

    // 更新密码
    user.password = await hash(newPassword, SALT_ROUNDS);
    await saveUsers(users);

    return NextResponse.json({ success: true });
  } catch (error) {
    console.error('Change password error:', error);
    return NextResponse.json(
      { error: '修改密码失败' },
      { status: 500 }
    );
  }
} 