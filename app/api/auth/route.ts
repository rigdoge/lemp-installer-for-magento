import { NextResponse } from 'next/server';
import { cookies } from 'next/headers';
import { hash, compare } from 'bcrypt';
import { sign, verify } from 'jsonwebtoken';
import { readFile, writeFile } from 'fs/promises';
import path from 'path';

const USERS_FILE = path.join(process.cwd(), 'data', 'users.json');
const JWT_SECRET = process.env.JWT_SECRET || 'your-secret-key';
const SALT_ROUNDS = 10;

interface User {
  username: string;
  password: string;
  role: 'admin' | 'user';
  lastLogin?: string;
  createdAt: string;
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
      role: 'admin' as const,
      createdAt: new Date().toISOString(),
    };
    await writeFile(USERS_FILE, JSON.stringify([defaultAdmin], null, 2));
    return [defaultAdmin];
  }
}

// 保存用户数据
async function saveUsers(users: User[]) {
  await writeFile(USERS_FILE, JSON.stringify(users, null, 2));
}

// 获取当前用户
export async function GET() {
  try {
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

    if (!user) {
      return NextResponse.json(
        { error: '用户不存在' },
        { status: 401 }
      );
    }

    // 不返回密码字段
    const { password, ...safeUser } = user;
    return NextResponse.json({ user: safeUser });
  } catch (error) {
    return NextResponse.json(
      { error: '认证失败' },
      { status: 401 }
    );
  }
}

// 登录
export async function POST(request: Request) {
  try {
    const { username, password, rememberMe } = await request.json();
    console.log('Login attempt:', { username, rememberMe });

    const users = await getUsers();
    console.log('Current users:', users);

    const user = users.find(u => u.username === username);
    if (!user) {
      console.log('User not found:', username);
      return NextResponse.json(
        { error: '用户名或密码错误' },
        { status: 401 }
      );
    }

    const isValid = await compare(password, user.password);
    console.log('Password validation:', { username, isValid });
    
    if (!isValid) {
      return NextResponse.json(
        { error: '用户名或密码错误' },
        { status: 401 }
      );
    }

    // 更新最后登录时间
    user.lastLogin = new Date().toISOString();
    await saveUsers(users);

    // 生成 JWT token
    const token = sign({ username: user.username }, JWT_SECRET, {
      expiresIn: rememberMe ? '30d' : '24h',
    });
    console.log('Generated token for user:', username);

    // 设置 cookie
    const cookieOptions = {
      httpOnly: true,
      secure: false, // 开发环境设置为 false
      sameSite: 'lax' as const, // 开发环境设置为 lax
      path: '/',
      expires: rememberMe ? new Date(Date.now() + 30 * 24 * 60 * 60 * 1000) : undefined,
    };

    // 不返回密码字段
    const { password: _, ...safeUser } = user;

    const response = NextResponse.json({ user: safeUser });
    response.cookies.set('auth', token, cookieOptions);
    console.log('Login successful:', username);
    return response;
  } catch (error) {
    console.error('Login error:', error);
    return NextResponse.json(
      { error: error instanceof Error ? error.message : '登录失败' },
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
    const token = cookies().get('auth')?.value;
    if (!token) {
      return NextResponse.json(
        { error: '未登录' },
        { status: 401 }
      );
    }

    const decoded = verify(token, JWT_SECRET) as { username: string };
    const { currentPassword, newPassword } = await request.json();
    const users = await getUsers();
    const user = users.find(u => u.username === decoded.username);

    if (!user) {
      return NextResponse.json(
        { error: '用户不存在' },
        { status: 401 }
      );
    }

    const isValid = await compare(currentPassword, user.password);
    if (!isValid) {
      return NextResponse.json(
        { error: '当前密码错误' },
        { status: 401 }
      );
    }

    user.password = await hash(newPassword, SALT_ROUNDS);
    await saveUsers(users);

    return NextResponse.json({ success: true });
  } catch (error) {
    return NextResponse.json(
      { error: '修改密码失败' },
      { status: 500 }
    );
  }
} 