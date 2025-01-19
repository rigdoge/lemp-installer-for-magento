import { NextResponse } from 'next/server';
import type { NextRequest } from 'next/server';
import { verify } from 'jsonwebtoken';

const JWT_SECRET = process.env.JWT_SECRET || 'your-secret-key';

// 不需要认证的路径
const publicPaths = ['/login'];

export function middleware(request: NextRequest) {
  // 检查是否是公开路径
  const isPublicPath = publicPaths.some(path => request.nextUrl.pathname.startsWith(path));

  // 获取认证 token
  const token = request.cookies.get('auth')?.value;

  // 如果是登录页面且已经有有效的 token，重定向到首页
  if (isPublicPath && token) {
    try {
      verify(token, JWT_SECRET);
      return NextResponse.redirect(new URL('/', request.url));
    } catch {
      // token 无效，继续访问登录页
    }
  }

  // 如果不是公开路径且没有 token，重定向到登录页
  if (!isPublicPath && !token) {
    const loginUrl = new URL('/login', request.url);
    loginUrl.searchParams.set('from', request.nextUrl.pathname);
    return NextResponse.redirect(loginUrl);
  }

  // 如果不是公开路径且有 token，验证 token
  if (!isPublicPath && token) {
    try {
      verify(token, JWT_SECRET);
    } catch {
      // token 无效，重定向到登录页
      const loginUrl = new URL('/login', request.url);
      loginUrl.searchParams.set('from', request.nextUrl.pathname);
      return NextResponse.redirect(loginUrl);
    }
  }

  return NextResponse.next();
}

// 配置需要进行中间件处理的路径
export const config = {
  matcher: [
    /*
     * 匹配所有路径除了:
     * /api/auth/* (认证 API)
     * /_next/static (静态文件)
     * /_next/image (图片)
     * /favicon.ico (网站图标)
     */
    '/((?!api/auth|_next/static|_next/image|favicon.ico).*)',
  ],
}; 