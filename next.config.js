/** @type {import('next').NextConfig} */
const nextConfig = {
  reactStrictMode: true,
  webpack: (config) => {
    // 使用更具体的文件名模式来避免冲突
    config.output.assetModuleFilename = `static/media/[name].[hash][ext]`;
    config.output.filename = `static/js/[name].[contenthash].js`;
    config.output.chunkFilename = `static/js/[name].[contenthash].js`;
    return config;
  }
}

module.exports = nextConfig 