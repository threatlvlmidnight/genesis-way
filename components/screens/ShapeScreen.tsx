"use client";

import { useState } from "react";

const FILTERS = [
  {
    id: "eliminate",
    label: "Eliminate",
    symbol: "✕",
    desc: "Not worth your time",
    color: "#8a3020",
  },
  {
    id: "automate",
    label: "Automate",
    symbol: "⟳",
    desc: "Set it and forget it",
    color: "#6a5820",
  },
  {
    id: "delegate",
    label: "Delegate",
    symbol: "→",
    desc: "Someone else's job",
    color: "#4a5a30",
  },
  {
    id: "schedule",
    label: "Schedule",
    symbol: "◎",
    desc: "Time-block it",
    color: "#c8a96e",
  },
  {
    id: "park",
    label: "Park",
    symbol: "P",
    desc: "Not now, but someday",
    color: "#5a4070",
  },
];

const DAYS = ["M", "T", "W", "T", "F", "S", "S"];
const TODAY = 4; // Friday

export default function ShapeScreen({
  dumpItems,
  onContinue,
}: {
  dumpItems: string[];
  onContinue: () => void;
}) {
  const [assigned, setAssigned] = useState<Record<number, string>>({});
  const [activeFilter, setActiveFilter] = useState<string | null>(null);
  const [activeItem, setActiveItem] = useState<number | null>(null);

  const assign = (itemIdx: number, filterId: string) => {
    setAssigned((prev) => ({ ...prev, [itemIdx]: filterId }));
    setActiveItem(null);
    setActiveFilter(null);
  };

  const displayItems =
    dumpItems.length > 0
      ? dumpItems
      : [
          "Follow up Howard — John Maxwell",
          "Disruptor Manufacturing update",
          "Send card to son",
          "Date night — Thursday reservation",
          "Review Q1 client onboarding",
          "15-min with Corrine",
        ];

  return (
    <div
      style={{
        height: "100%",
        display: "flex",
        flexDirection: "column",
        background: "#0c0a06",
        position: "relative",
      }}
    >
      <div className="bg-glow" />

      {/* Header */}
      <div
        style={{
          flexShrink: 0,
          padding: "16px 24px 14px",
          borderBottom: "1px solid rgba(200,169,110,0.06)",
          position: "relative",
          zIndex: 1,
        }}
      >
        <div
          style={{
            fontSize: 11,
            fontWeight: 500,
            color: "#4a3820",
            letterSpacing: 0.5,
            textTransform: "uppercase",
            marginBottom: 4,
          }}
        >
          Step 2 of 3
        </div>
        <div
          style={{
            fontSize: 26,
            fontWeight: 800,
            color: "#f0e4d0",
            letterSpacing: -1,
          }}
        >
          Shape It
        </div>
        <div
          style={{ fontSize: 12, color: "#5a4830", marginTop: 4, lineHeight: 1.5 }}
        >
          Run each item through the Five Filters. Give form to what is formless.
        </div>
      </div>

      <div
        className="scroll-hide"
        style={{ flex: 1, position: "relative", zIndex: 1 }}
      >
        {/* Week mini-calendar */}
        <div style={{ padding: "14px 24px 0" }}>
          <div
            style={{
              fontSize: 10,
              fontWeight: 700,
              color: "#4a3820",
              letterSpacing: 2,
              textTransform: "uppercase",
              marginBottom: 10,
            }}
          >
            Week 11 — March
          </div>
          <div style={{ display: "flex", gap: 6 }}>
            {DAYS.map((d, i) => (
              <div
                key={i}
                style={{
                  flex: 1,
                  display: "flex",
                  flexDirection: "column",
                  alignItems: "center",
                  gap: 4,
                }}
              >
                <div
                  style={{
                    fontSize: 9,
                    fontWeight: 600,
                    color: i === TODAY ? "#c8a96e" : "#3a2e18",
                    letterSpacing: 1,
                  }}
                >
                  {d}
                </div>
                <div
                  style={{
                    width: "100%",
                    height: 32,
                    borderRadius: 8,
                    background:
                      i === TODAY
                        ? "rgba(200,169,110,0.12)"
                        : "rgba(255,255,255,0.02)",
                    border:
                      i === TODAY
                        ? "1px solid rgba(200,169,110,0.2)"
                        : "1px solid rgba(200,169,110,0.04)",
                    display: "flex",
                    alignItems: "center",
                    justifyContent: "center",
                    fontSize: 12,
                    fontWeight: i === TODAY ? 700 : 400,
                    color: i === TODAY ? "#c8a96e" : "#3a2e18",
                  }}
                >
                  {10 + i}
                </div>
              </div>
            ))}
          </div>
        </div>

        {/* Five Filters */}
        <div style={{ padding: "18px 24px 0" }}>
          <div
            style={{
              fontSize: 10,
              fontWeight: 700,
              color: "#4a3820",
              letterSpacing: 2,
              textTransform: "uppercase",
              marginBottom: 10,
            }}
          >
            Five Filters
          </div>
          <div style={{ display: "flex", gap: 6, flexWrap: "wrap" }}>
            {FILTERS.map((f) => (
              <button
                key={f.id}
                onClick={() =>
                  setActiveFilter(activeFilter === f.id ? null : f.id)
                }
                style={{
                  display: "flex",
                  alignItems: "center",
                  gap: 5,
                  padding: "6px 12px",
                  borderRadius: 20,
                  fontSize: 11,
                  fontWeight: 600,
                  background:
                    activeFilter === f.id
                      ? `${f.color}22`
                      : "rgba(255,255,255,0.03)",
                  border: `1px solid ${
                    activeFilter === f.id ? f.color + "44" : "rgba(200,169,110,0.08)"
                  }`,
                  color: activeFilter === f.id ? f.color : "#4a3820",
                  cursor: "pointer",
                  fontFamily: "inherit",
                }}
              >
                <span>{f.symbol}</span>
                {f.label}
              </button>
            ))}
          </div>
        </div>

        {/* Items to assign */}
        <div style={{ padding: "18px 24px 0" }}>
          <div
            style={{
              fontSize: 10,
              fontWeight: 700,
              color: "#4a3820",
              letterSpacing: 2,
              textTransform: "uppercase",
              marginBottom: 10,
            }}
          >
            Items to Place
          </div>

          {displayItems.map((item, i) => {
            const filter = FILTERS.find((f) => f.id === assigned[i]);
            return (
              <div
                key={i}
                onClick={() =>
                  setActiveItem(activeItem === i ? null : i)
                }
                style={{
                  display: "flex",
                  alignItems: "center",
                  gap: 10,
                  padding: "10px 12px",
                  marginBottom: 6,
                  borderRadius: 12,
                  background:
                    activeItem === i
                      ? "rgba(200,169,110,0.06)"
                      : "rgba(255,255,255,0.02)",
                  border: `1px solid ${
                    activeItem === i
                      ? "rgba(200,169,110,0.15)"
                      : "rgba(200,169,110,0.04)"
                  }`,
                  cursor: "pointer",
                }}
              >
                <div
                  style={{
                    width: 6,
                    height: 6,
                    borderRadius: "50%",
                    background: filter ? filter.color : "rgba(200,169,110,0.3)",
                    flexShrink: 0,
                  }}
                />
                <div
                  style={{
                    flex: 1,
                    fontSize: 13,
                    color: filter ? "#7a6850" : "#c0b090",
                    textDecoration: filter ? "line-through" : "none",
                  }}
                >
                  {item}
                </div>
                {filter && (
                  <span
                    style={{
                      fontSize: 10,
                      fontWeight: 600,
                      padding: "3px 8px",
                      borderRadius: 10,
                      background: `${filter.color}18`,
                      color: filter.color,
                      border: `1px solid ${filter.color}30`,
                    }}
                  >
                    {filter.label}
                  </span>
                )}
              </div>
            );
          })}

          {/* Filter picker when item selected */}
          {activeItem !== null && (
            <div
              style={{
                marginTop: 8,
                padding: "12px",
                borderRadius: 14,
                background: "rgba(200,169,110,0.05)",
                border: "1px solid rgba(200,169,110,0.1)",
              }}
            >
              <div
                style={{
                  fontSize: 10,
                  fontWeight: 600,
                  color: "#4a3820",
                  letterSpacing: 1,
                  marginBottom: 10,
                  textTransform: "uppercase",
                }}
              >
                Apply filter:
              </div>
              <div style={{ display: "flex", gap: 6, flexWrap: "wrap" }}>
                {FILTERS.map((f) => (
                  <button
                    key={f.id}
                    onClick={() => assign(activeItem, f.id)}
                    style={{
                      padding: "6px 12px",
                      borderRadius: 10,
                      fontSize: 11,
                      fontWeight: 600,
                      background: `${f.color}22`,
                      border: `1px solid ${f.color}44`,
                      color: f.color,
                      cursor: "pointer",
                      fontFamily: "inherit",
                    }}
                  >
                    {f.symbol} {f.label}
                  </button>
                ))}
              </div>
            </div>
          )}
        </div>
      </div>

      {/* CTA */}
      <div
        style={{
          flexShrink: 0,
          padding: "12px 24px 16px",
          position: "relative",
          zIndex: 1,
        }}
      >
        <button
          onClick={onContinue}
          style={{
            width: "100%",
            padding: 15,
            background: "linear-gradient(135deg, #c8a96e 0%, #b08848 100%)",
            borderRadius: 14,
            fontSize: 14,
            fontWeight: 700,
            color: "#1a1208",
            border: "none",
            cursor: "pointer",
            fontFamily: "inherit",
            boxShadow: "0 8px 24px rgba(200,169,110,0.2)",
          }}
        >
          Fill Your Day →
        </button>
      </div>
    </div>
  );
}
