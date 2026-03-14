"use client";

import { useState, useEffect } from "react";

export interface Big3Item {
  id: string;
  text: string;
  done: boolean;
}

export interface Task {
  id: string;
  text: string;
  code: string;
  filter?: string;
  time?: string;
}

const BADGE_COLORS: Record<string, { bg: string; color: string; border: string }> = {
  scheduled: {
    bg: "rgba(200,169,110,0.12)",
    color: "#c8a96e",
    border: "rgba(200,169,110,0.2)",
  },
  schedule: {
    bg: "rgba(200,169,110,0.12)",
    color: "#c8a96e",
    border: "rgba(200,169,110,0.2)",
  },
  delegate: {
    bg: "rgba(80,120,80,0.12)",
    color: "#80b880",
    border: "rgba(80,180,80,0.2)",
  },
  eliminate: {
    bg: "rgba(150,50,50,0.12)",
    color: "#c07060",
    border: "rgba(200,80,80,0.2)",
  },
  automate: {
    bg: "rgba(80,100,160,0.12)",
    color: "#8090d0",
    border: "rgba(80,120,200,0.2)",
  },
  park: {
    bg: "rgba(100,70,140,0.12)",
    color: "#b090d0",
    border: "rgba(140,90,180,0.2)",
  },
};

function FilterBadge({ label, time }: { label?: string; time?: string }) {
  const display = time ?? label;
  if (!display) return null;
  const key = time ? "scheduled" : (label?.toLowerCase() ?? "");
  const colors = BADGE_COLORS[key] ?? {
    bg: "rgba(200,169,110,0.07)",
    color: "rgba(200,169,110,0.45)",
    border: "rgba(200,169,110,0.1)",
  };
  return (
    <span
      style={{
        fontSize: 10,
        fontWeight: 600,
        padding: "4px 10px",
        borderRadius: 20,
        background: colors.bg,
        color: colors.color,
        border: `1px solid ${colors.border}`,
        whiteSpace: "nowrap",
        flexShrink: 0,
      }}
    >
      {display}
    </span>
  );
}

export default function FillScreen({
  big3,
  workTasks,
  personalTasks,
  onToggleBig3,
  onShowIntro,
}: {
  big3: Big3Item[];
  workTasks: Task[];
  personalTasks: Task[];
  onToggleBig3: (id: string) => void;
  onShowIntro: () => void;
}) {
  const [now, setNow] = useState(new Date());

  useEffect(() => {
    const t = setInterval(() => setNow(new Date()), 60_000);
    return () => clearInterval(t);
  }, []);

  const timeStr = now.toLocaleTimeString("en-US", {
    hour: "numeric",
    minute: "2-digit",
    hour12: true,
  });

  const doneCount = big3.filter((b) => b.done).length;

  const PHASES = [
    { label: "Dump", state: "done" },
    { label: "Shape", state: "done" },
    { label: "Fill", state: "active" },
    { label: "Park", state: "idle" },
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
          padding: "14px 24px 16px",
          borderBottom: "1px solid rgba(200,169,110,0.06)",
          position: "relative",
          zIndex: 1,
        }}
      >
        <div
          style={{
            display: "flex",
            justifyContent: "space-between",
            alignItems: "flex-start",
            marginBottom: 14,
          }}
        >
          <div>
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
              Friday · March 14 · Week 11
            </div>
            <div
              style={{
                fontSize: 26,
                fontWeight: 800,
                color: "#f0e4d0",
                letterSpacing: -1,
              }}
            >
              Good morning.
            </div>
          </div>
          <div style={{ display: "flex", alignItems: "center", gap: 8 }}>
            <button
              onClick={onShowIntro}
              title="About the Genesis Way"
              style={{
                width: 38,
                height: 38,
                borderRadius: 12,
                background: "rgba(200,169,110,0.05)",
                border: "1px solid rgba(200,169,110,0.1)",
                display: "flex",
                alignItems: "center",
                justifyContent: "center",
                fontSize: 16,
                color: "#5a4830",
                cursor: "pointer",
                flexShrink: 0,
              }}
            >
              ☰
            </button>
            <div
              style={{
                width: 38,
                height: 38,
                borderRadius: 12,
                background: "rgba(200,169,110,0.08)",
                border: "1px solid rgba(200,169,110,0.15)",
                display: "flex",
                alignItems: "center",
                justifyContent: "center",
                fontSize: 14,
                fontWeight: 700,
                color: "#c8a96e",
              }}
            >
              D
            </div>
          </div>
        </div>

        {/* Phase pills */}
        <div style={{ display: "flex", gap: 6 }}>
          {PHASES.map((p) => (
            <div
              key={p.label}
              style={{
                display: "flex",
                alignItems: "center",
                gap: 5,
                padding: "5px 10px",
                borderRadius: 20,
                fontSize: 10,
                fontWeight: 600,
                background:
                  p.state === "active"
                    ? "rgba(200,169,110,0.1)"
                    : "rgba(255,255,255,0.03)",
                border: `1px solid ${
                  p.state === "active"
                    ? "rgba(200,169,110,0.2)"
                    : "rgba(200,169,110,0.06)"
                }`,
                color:
                  p.state === "active"
                    ? "#c8a96e"
                    : p.state === "done"
                    ? "#3a2e18"
                    : "#2a2010",
                letterSpacing: 0.5,
                textTransform: "uppercase",
              }}
            >
              <div
                style={{
                  width: 5,
                  height: 5,
                  borderRadius: "50%",
                  background: "currentColor",
                }}
              />
              {p.label}
            </div>
          ))}
        </div>
      </div>

      {/* Scrollable body */}
      <div
        className="scroll-hide"
        style={{
          flex: 1,
          padding: "18px 24px 0",
          position: "relative",
          zIndex: 1,
        }}
      >
        {/* Jam Session */}
        <div
          style={{
            position: "relative",
            background: "rgba(200,169,110,0.05)",
            backdropFilter: "blur(30px)",
            WebkitBackdropFilter: "blur(30px)",
            border: "1px solid rgba(200,169,110,0.12)",
            borderRadius: 16,
            padding: "14px 16px",
            marginBottom: 20,
            display: "flex",
            justifyContent: "space-between",
            alignItems: "center",
            overflow: "hidden",
          }}
        >
          {/* Top shimmer */}
          <div
            style={{
              position: "absolute",
              top: 0,
              left: 0,
              right: 0,
              height: 1,
              background:
                "linear-gradient(to right, transparent, rgba(200,169,110,0.4), transparent)",
            }}
          />
          {/* Left accent bar */}
          <div
            style={{
              position: "absolute",
              left: 0,
              top: 0,
              bottom: 0,
              width: 3,
              background: "linear-gradient(to bottom, #c8a96e, #8a6830)",
              borderRadius: "3px 0 0 3px",
            }}
          />
          <div style={{ paddingLeft: 8 }}>
            <div
              style={{
                fontSize: 10,
                fontWeight: 600,
                color: "#5a4830",
                letterSpacing: 1,
                textTransform: "uppercase",
                marginBottom: 3,
              }}
            >
              Jam Session
            </div>
            <div
              style={{
                fontSize: 14,
                fontWeight: 700,
                color: "#c8b898",
                letterSpacing: -0.3,
              }}
            >
              Genesis Way POC Review
            </div>
          </div>
          <div style={{ textAlign: "right" }}>
            <div
              style={{
                fontSize: 20,
                fontWeight: 800,
                color: "#c8a96e",
                letterSpacing: -1,
              }}
            >
              {timeStr.replace(" AM", "").replace(" PM", "")}
            </div>
            <div style={{ fontSize: 10, fontWeight: 500, color: "#5a4830", marginTop: 1 }}>
              90 min
            </div>
          </div>
        </div>

        {/* Daily Big 3 */}
        <div
          style={{
            display: "flex",
            justifyContent: "space-between",
            alignItems: "center",
            marginBottom: 8,
          }}
        >
          <div
            style={{
              fontSize: 11,
              fontWeight: 700,
              color: "#5a4830",
              letterSpacing: 1,
              textTransform: "uppercase",
            }}
          >
            Daily Big 3
          </div>
          <div style={{ fontSize: 12, fontWeight: 600, color: "#c8a96e" }}>
            {doneCount} of 3
          </div>
        </div>

        {big3.map((item) => (
          <div
            key={item.id}
            onClick={() => onToggleBig3(item.id)}
            style={{
              position: "relative",
              background: "rgba(255,255,255,0.025)",
              border: "1px solid rgba(200,169,110,0.08)",
              borderRadius: 14,
              padding: "13px 14px",
              marginBottom: 7,
              display: "flex",
              alignItems: "center",
              gap: 12,
              backdropFilter: "blur(20px)",
              cursor: "pointer",
              overflow: "hidden",
            }}
          >
            <div
              style={{
                position: "absolute",
                top: 0,
                left: 0,
                right: 0,
                height: 1,
                background: "rgba(200,169,110,0.1)",
              }}
            />
            <div
              style={{
                width: 22,
                height: 22,
                borderRadius: 8,
                border: item.done
                  ? "none"
                  : "1.5px solid rgba(200,169,110,0.25)",
                background: item.done ? "#c8a96e" : "transparent",
                display: "flex",
                alignItems: "center",
                justifyContent: "center",
                flexShrink: 0,
                fontSize: 12,
                fontWeight: 800,
                color: "#1a1208",
              }}
            >
              {item.done ? "✓" : ""}
            </div>
            <div
              style={{
                fontSize: 13,
                fontWeight: 500,
                color: item.done ? "#6a5840" : "#c0b090",
                textDecoration: item.done ? "line-through" : "none",
              }}
            >
              {item.text}
            </div>
          </div>
        ))}

        {/* Divider */}
        <div
          style={{
            height: 1,
            background: "rgba(200,169,110,0.05)",
            margin: "18px 0",
          }}
        />

        {/* Work Tasks */}
        <div
          style={{
            display: "flex",
            justifyContent: "space-between",
            alignItems: "center",
            marginBottom: 6,
          }}
        >
          <div
            style={{
              fontSize: 11,
              fontWeight: 700,
              color: "#5a4830",
              letterSpacing: 1,
              textTransform: "uppercase",
            }}
          >
            Work{" "}
            <span
              style={{ color: "#3a2e18", fontSize: 10, marginLeft: 4 }}
            >
              ↓
            </span>
          </div>
        </div>

        {workTasks.map((task) => (
          <div
            key={task.id}
            style={{
              display: "flex",
              alignItems: "center",
              gap: 10,
              padding: "10px 0",
              borderBottom: "1px solid rgba(200,169,110,0.05)",
            }}
          >
            <div
              style={{
                fontSize: 11,
                fontWeight: 800,
                color: "#c8a96e",
                width: 28,
                flexShrink: 0,
                letterSpacing: 0.3,
              }}
            >
              {task.code}
            </div>
            <div
              style={{ flex: 1, fontSize: 13, fontWeight: 400, color: "#7a6850" }}
            >
              {task.text}
            </div>
            <FilterBadge label={task.filter} time={task.time} />
          </div>
        ))}

        {/* Divider */}
        <div
          style={{
            height: 1,
            background: "rgba(200,169,110,0.05)",
            margin: "18px 0",
          }}
        />

        {/* Personal Tasks */}
        <div
          style={{
            display: "flex",
            justifyContent: "space-between",
            alignItems: "center",
            marginBottom: 6,
          }}
        >
          <div
            style={{
              fontSize: 11,
              fontWeight: 700,
              color: "#5a4830",
              letterSpacing: 1,
              textTransform: "uppercase",
            }}
          >
            Personal{" "}
            <span style={{ color: "#3a2e18", fontSize: 10, marginLeft: 4 }}>
              ↑
            </span>
          </div>
        </div>

        {personalTasks.map((task) => (
          <div
            key={task.id}
            style={{
              display: "flex",
              alignItems: "center",
              gap: 10,
              padding: "10px 0",
              borderBottom: "1px solid rgba(200,169,110,0.05)",
            }}
          >
            <div
              style={{
                fontSize: 11,
                fontWeight: 800,
                color: "#907050",
                width: 28,
                flexShrink: 0,
                letterSpacing: 0.3,
              }}
            >
              {task.code}
            </div>
            <div
              style={{ flex: 1, fontSize: 13, fontWeight: 400, color: "#7a6850" }}
            >
              {task.text}
            </div>
            <FilterBadge label={task.filter} time={task.time} />
          </div>
        ))}

        {/* Bottom padding */}
        <div style={{ height: 24 }} />
      </div>
    </div>
  );
}
