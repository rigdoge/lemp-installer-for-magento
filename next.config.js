/** @type {import('next').NextConfig} */
const nextConfig = {
  reactStrictMode: true,
  webpack: (config) => {
    // 防止 webpack 创建不必要的目录
    config.output.assetModuleFilename = `static/[hash][ext]`;
    config.output.filename = `static/[hash].js`;
    config.output.chunkFilename = `static/[hash].js`;
    return config;
  }
}

module.exports = nextConfig 