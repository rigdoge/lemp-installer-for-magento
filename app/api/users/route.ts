import { NextResponse } from 'next/server';
import { cookies } from 'next/headers';
import { hash, compare } from 'bcrypt';
import { verify } from 'jsonwebtoken';
import { readFile, writeFile } from 'fs/promises';
import path from 'path';

const USERS_FILE = path.join(process.cwd(), 'data', 'users.json');
const JWT_SECRET = process.env.JWT_SECRET || 'your-secret-key';
const SALT_ROUNDS = 10;

interface User {
  username: string;
  password: string;
  lastLogin?: string;
  role: 'admin' | 'user';
  createdAt: string;
}

// 验证是否是管理员
async function verifyAdmin() {
  const token = cookies().get('auth')?.value;
  if (!token) {
    throw new Error('未登录');
  }

  const decoded = verify(token, JWT_SECRET) as { username: string };
  const users = await getUsers();
  const user = users.find(u => u.username === decoded.username);

  if (!user || user.role !== 'admin') {
    throw new Error('无权限');
  }
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

// 获取用户列表
export async function GET() {
  try {
    await verifyAdmin();
    const users = await getUsers();
    // 不返回密码字段
    const safeUsers = users.map(({ password, ...user }) => user);
    return NextResponse.json(safeUsers);
  } catch (error) {
    return NextResponse.json(
      { error: error instanceof Error ? error.message : '获取用户列表失败' },
      { status: 401 }
    );
  }
}

// 创建新用户
export async function POST(request: Request) {
  try {
    await verifyAdmin();
    const { username, password, role = 'user' } = await request.json();

    // 验证输入
    if (!username || !password) {
      return NextResponse.json(
        { error: '用户名和密码不能为空' },
        { status: 400 }
      );
    }

    const users = await getUsers();
    
    // 检查用户名是否已存在
    if (users.some(u => u.username === username)) {
      return NextResponse.json(
        { error: '用户名已存在' },
        { status: 400 }
      );
    }

    // 创建新用户
    const newUser: User = {
      username,
      password: await hash(password, SALT_ROUNDS),
      role: role as 'admin' | 'user',
      createdAt: new Date().toISOString(),
    };

    users.push(newUser);
    await saveUsers(users);

    // 不返回密码字段
    const { password: _, ...safeUser } = newUser;
    return NextResponse.json(safeUser);
  } catch (error) {
    return NextResponse.json(
      { error: error instanceof Error ? error.message : '创建用户失败' },
      { status: 401 }
    );
  }
}

// 删除用户
export async function DELETE(request: Request) {
  try {
    await verifyAdmin();
    const { username } = await request.json();

    if (username === 'admin') {
      return NextResponse.json(
        { error: '不能删除管理员账户' },
        { status: 400 }
      );
    }

    const users = await getUsers();
    const newUsers = users.filter(u => u.username !== username);

    if (newUsers.length === users.length) {
      return NextResponse.json(
        { error: '用户不存在' },
        { status: 404 }
      );
    }

    await saveUsers(newUsers);
    return NextResponse.json({ success: true });
  } catch (error) {
    return NextResponse.json(
      { error: error instanceof Error ? error.message : '删除用户失败' },
      { status: 401 }
    );
  }
}

// 重置用户密码
export async function PUT(request: Request) {
  try {
    await verifyAdmin();
    const { username, newPassword } = await request.json();

    const users = await getUsers();
    const user = users.find(u => u.username === username);

    if (!user) {
      return NextResponse.json(
        { error: '用户不存在' },
        { status: 404 }
      );
    }

    user.password = await hash(newPassword, SALT_ROUNDS);
    await saveUsers(users);

    return NextResponse.json({ success: true });
  } catch (error) {
    return NextResponse.json(
      { error: error instanceof Error ? error.message : '重置密码失败' },
      { status: 401 }
    );
  }
} 