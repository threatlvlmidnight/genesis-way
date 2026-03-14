"use client";

import { useState } from "react";

const CATEGORIES = [
  { id: "week", label: "This Week", color: "#c8a96e" },
  { id: "month", label: "Next Month", color: "#8090d0" },
  { id: "someday", label: "Someday", color: "#6a5840" },
];

export default function ParkScreen({
  items,
  onAdd,
  onRemove,
}: {
  items: string[];
  onAdd: (item: string) => void;
  onRemove: (index: number) => void;
}) {
  const [input, setInput] = useState("");
  const [selectedCat, setSelectedCat] = useState("week");

  const handleAdd = () => {
    const trimmed = input.trim();
    if (trimmed) {
      onAdd(trimmed);
      setInput("");
    }
  };

  // Distribute sample/existing items across categories for demo
  const categorized: Record<string, string[]> = {
    week: [],
    month: [],
    someday: [],
  };

  items.forEach((item, i) => {
    const cat = ["week", "month", "someday"][i % 3];
    categorized[cat].push(item);
  });

  const activeColor =
    CATEGORIES.find((c) => c.id === selectedCat)?.color ?? "#c8a96e";

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
          Long-Term Parking
        </div>
        <div
          style={{
            fontSize: 26,
            fontWeight: 800,
            color: "#f0e4d0",
            letterSpacing: -1,
          }}
        >
          The Park
        </div>
        <div
          style={{ fontSize: 12, color: "#5a4830", marginTop: 4, lineHeight: 1.5 }}
        >
          Not now. Not never. Just not today. Park it here and move on.
        </div>
      </div>

      {/* Category tabs */}
      <div
        style={{
          flexShrink: 0,
          padding: "12px 24px",
          display: "flex",
          gap: 8,
          position: "relative",
          zIndex: 1,
        }}
      >
        {CATEGORIES.map((cat) => (
          <button
            key={cat.id}
            onClick={() => setSelectedCat(cat.id)}
            style={{
              flex: 1,
              padding: "8px 0",
              borderRadius: 10,
              fontSize: 11,
              fontWeight: 600,
              background:
                selectedCat === cat.id ? `${cat.color}18` : "rgba(255,255,255,0.02)",
              border: `1px solid ${
                selectedCat === cat.id ? `${cat.color}40` : "rgba(200,169,110,0.05)"
              }`,
              color: selectedCat === cat.id ? cat.color : "#3a2e18",
              cursor: "pointer",
              fontFamily: "inherit",
            }}
          >
            {cat.label}
          </button>
        ))}
      </div>

      {/* Add input */}
      <div
        style={{
          flexShrink: 0,
          padding: "0 24px 14px",
          position: "relative",
          zIndex: 1,
        }}
      >
        <div style={{ display: "flex", gap: 8 }}>
          <input
            value={input}
            onChange={(e) => setInput(e.target.value)}
            onKeyDown={(e) => e.key === "Enter" && handleAdd()}
            placeholder={`Park something for ${
              CATEGORIES.find((c) => c.id === selectedCat)?.label.toLowerCase() ??
              "later"
            }…`}
            style={{
              flex: 1,
              background: "rgba(255,255,255,0.04)",
              border: "1px solid rgba(200,169,110,0.12)",
              borderRadius: 12,
              padding: "11px 14px",
              fontSize: 13,
              color: "#c0b090",
              fontFamily: "inherit",
              outline: "none",
            }}
          />
          <button
            onClick={handleAdd}
            style={{
              width: 44,
              height: 44,
              borderRadius: 12,
              background: `linear-gradient(135deg, ${activeColor} 0%, #8a6830 100%)`,
              border: "none",
              cursor: "pointer",
              fontSize: 20,
              color: "#1a1208",
              display: "flex",
              alignItems: "center",
              justifyContent: "center",
              flexShrink: 0,
            }}
          >
            P
          </button>
        </div>
      </div>

      {/* Parked items */}
      <div
        className="scroll-hide"
        style={{
          flex: 1,
          padding: "0 24px",
          position: "relative",
          zIndex: 1,
        }}
      >
        {CATEGORIES.map((cat) => {
          const catItems = categorized[cat.id];
          if (selectedCat !== cat.id) return null;
          if (catItems.length === 0) {
            return (
              <div
                key={cat.id}
                style={{
                  textAlign: "center",
                  paddingTop: 40,
                  color: "#3a2e18",
                  fontSize: 13,
                  lineHeight: 1.8,
                }}
              >
                <div style={{ fontSize: 24, marginBottom: 10 }}>🅿</div>
                Nothing parked here yet.
                <br />
                Add something above.
              </div>
            );
          }

          return (
            <div key={cat.id}>
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
                {cat.label} — {catItems.length}
              </div>
              {catItems.map((item, localIdx) => {
                const globalIdx = items.indexOf(item);
                return (
                  <div
                    key={localIdx}
                    style={{
                      display: "flex",
                      alignItems: "center",
                      gap: 10,
                      padding: "11px 12px",
                      marginBottom: 6,
                      borderRadius: 12,
                      background: "rgba(255,255,255,0.02)",
                      border: "1px solid rgba(200,169,110,0.04)",
                    }}
                  >
                    <div
                      style={{
                        width: 8,
                        height: 8,
                        borderRadius: "50%",
                        background: `${cat.color}60`,
                        flexShrink: 0,
                      }}
                    />
                    <div
                      style={{
                        flex: 1,
                        fontSize: 13,
                        color: "#7a6850",
                        lineHeight: 1.4,
                      }}
                    >
                      {item}
                    </div>
                    <button
                      onClick={() => onRemove(globalIdx)}
                      style={{
                        background: "none",
                        border: "none",
                        cursor: "pointer",
                        color: "#3a2e18",
                        fontSize: 16,
                        padding: "0 4px",
                        lineHeight: 1,
                      }}
                    >
                      ×
                    </button>
                  </div>
                );
              })}
            </div>
          );
        })}
      </div>
    </div>
  );
}
