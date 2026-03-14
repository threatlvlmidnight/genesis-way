import type { NextConfig } from "next";

const nextConfig: NextConfig = {
  output: "export",
  // On GitHub Pages, the app lives at /repo-name/ — the Actions workflow
  // sets NEXT_PUBLIC_BASE_PATH automatically from the GitHub repo name.
  // For local dev, it's empty so localhost:3000 works as normal.
  basePath: process.env.NEXT_PUBLIC_BASE_PATH ?? "",
  images: {
    unoptimized: true,
  },
};

export default nextConfig;
