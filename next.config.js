/** @type {import('next').NextConfig} */
const nextConfig = {
  reactStrictMode: true,
  distDir: '.next',
  poweredByHeader: false,
  webpack: (config, { dev, isServer }) => {
    // 只在生产环境修改输出配置
    if (!dev) {
      config.output = {
        ...config.output,
        // 使用标准的 Next.js 输出路径
        filename: isServer ? '[name].js' : 'static/chunks/[name].[contenthash].js',
        chunkFilename: isServer ? '[name].js' : 'static/chunks/[name].[contenthash].js'
      };
    }
    return config;
  }
}

module.exports = nextConfig 