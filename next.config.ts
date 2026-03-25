import type { NextConfig } from "next";

const nextConfig: NextConfig = {
  // output: "export" removed — Vercel handles deployment natively and
  // static export mode blocks API routes. GitHub Pages deployment (if needed)
  // would require a separate config or build step.
  basePath: process.env.NEXT_PUBLIC_BASE_PATH ?? "",
  images: {
    unoptimized: true,
  },
};

export default nextConfig;
