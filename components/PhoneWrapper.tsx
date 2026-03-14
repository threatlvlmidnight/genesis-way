"use client";

import { useEffect, useState } from "react";

const PHONE_W = 390;
const PHONE_H = 844;

const ISLAND = (
  <div
    style={{
      flexShrink: 0,
      width: 120,
      height: 34,
      background: "#050401",
      borderRadius: "0 0 20px 20px",
      margin: "0 auto",
      display: "flex",
      alignItems: "center",
      justifyContent: "center",
    }}
  >
    <div
      style={{
        width: 90,
        height: 24,
        background: "#000",
        borderRadius: 12,
      }}
    />
  </div>
);

const HOME_BAR = (
  <div
    style={{
      flexShrink: 0,
      width: 130,
      height: 5,
      background: "rgba(200,169,110,0.12)",
      borderRadius: 3,
      margin: "8px auto 10px",
    }}
  />
);

export default function PhoneWrapper({
  children,
}: {
  children: React.ReactNode;
}) {
  const [isMobile, setIsMobile] = useState(false);

  useEffect(() => {
    const check = () => setIsMobile(window.innerWidth < 480);
    check();
    window.addEventListener("resize", check);
    return () => window.removeEventListener("resize", check);
  }, []);

  if (isMobile) {
    return (
      <div
        style={{
          width: "100%",
          height: "100svh",
          display: "flex",
          flexDirection: "column",
          background: "#0c0a06",
          overflow: "hidden",
          position: "relative",
        }}
      >
        {ISLAND}
        <div
          style={{ flex: 1, overflow: "hidden", position: "relative", zIndex: 1 }}
        >
          {children}
        </div>
        {HOME_BAR}
      </div>
    );
  }

  return (
    <div
      style={{
        minHeight: "100vh",
        background: "#0c0a06",
        display: "flex",
        alignItems: "flex-start",
        justifyContent: "center",
        padding: "40px 20px 60px",
      }}
    >
      <div
        style={{
          display: "flex",
          flexDirection: "column",
          alignItems: "center",
          gap: 14,
        }}
      >
        <div
          style={{
            fontSize: 10,
            letterSpacing: 3,
            textTransform: "uppercase",
            color: "#3a3020",
            fontFamily: "inherit",
          }}
        >
          The Genesis Way
        </div>
        <div
          style={{
            width: PHONE_W,
            height: PHONE_H,
            borderRadius: 50,
            background: "#151008",
            boxShadow:
              "0 0 0 1px #201808, 0 0 0 11px #100c06, 0 0 0 12px #201808, 0 60px 120px rgba(0,0,0,0.9), 0 0 80px rgba(160,110,40,0.06), inset 0 1px 0 rgba(200,169,110,0.08)",
            overflow: "hidden",
            position: "relative",
            display: "flex",
            flexDirection: "column",
          }}
        >
          {ISLAND}
          <div
            style={{ flex: 1, overflow: "hidden", position: "relative", zIndex: 1 }}
          >
            {children}
          </div>
          {HOME_BAR}
        </div>
      </div>
    </div>
  );
}
