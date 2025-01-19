import { NextResponse } from 'next/server';
import type { NextRequest } from 'next/server';

export function middleware(request: NextRequest) {
  // 检查是否已登录
  const isAuthenticated = request.cookies.has('auth');
  
  // 如果访问的是登录页，且已经登录，则重定向到仪表盘
  if (request.nextUrl.pathname === '/' && isAuthenticated) {
    return NextResponse.redirect(new URL('/dashboard', request.url));
  }
  
  // 如果访问的不是登录页，且未登录，则重定向到登录页
  if (request.nextUrl.pathname !== '/' && !isAuthenticated) {
    return NextResponse.redirect(new URL('/', request.url));
  }
  
  return NextResponse.next();
}

// 配置需要进行认证检查的路由
export const config = {
  matcher: [
    '/',
    '/dashboard',
    '/deployment',
    '/logs',
    '/monitoring',
    '/notifications',
  ],
}; 