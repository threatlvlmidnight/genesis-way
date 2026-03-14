"use client";

import { useState } from "react";

const PLACEHOLDER_PROMPTS = [
  "What's on your mind right now?",
  "Any commitments you haven't scheduled yet?",
  "Things you've been meaning to do?",
  "Conversations you need to have?",
  "Projects you're waiting on others for?",
];

export default function DumpScreen({
  items,
  onAdd,
  onRemove,
  onContinue,
}: {
  items: string[];
  onAdd: (item: string) => void;
  onRemove: (index: number) => void;
  onContinue: () => void;
}) {
  const [input, setInput] = useState("");
  const [promptIdx] = useState(() =>
    Math.floor(Math.random() * PLACEHOLDER_PROMPTS.length)
  );

  const handleAdd = () => {
    const trimmed = input.trim();
    if (trimmed) {
      onAdd(trimmed);
      setInput("");
    }
  };

  const handleKey = (e: React.KeyboardEvent) => {
    if (e.key === "Enter") handleAdd();
  };

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
          Step 1 of 3
        </div>
        <div
          style={{
            fontSize: 26,
            fontWeight: 800,
            color: "#f0e4d0",
            letterSpacing: -1,
          }}
        >
          Dump It
        </div>
        <div
          style={{
            fontSize: 12,
            color: "#5a4830",
            marginTop: 4,
            lineHeight: 1.5,
          }}
        >
          Get everything out of your head. Don&apos;t filter — just capture.
        </div>
      </div>

      {/* Input area */}
      <div
        style={{
          flexShrink: 0,
          padding: "14px 24px",
          position: "relative",
          zIndex: 1,
        }}
      >
        <div
          style={{
            display: "flex",
            gap: 8,
            position: "relative",
          }}
        >
          <input
            value={input}
            onChange={(e) => setInput(e.target.value)}
            onKeyDown={handleKey}
            placeholder={PLACEHOLDER_PROMPTS[promptIdx]}
            style={{
              flex: 1,
              background: "rgba(255,255,255,0.04)",
              border: "1px solid rgba(200,169,110,0.12)",
              borderRadius: 12,
              padding: "12px 14px",
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
              background: "linear-gradient(135deg, #c8a96e 0%, #b08848 100%)",
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
            +
          </button>
        </div>
      </div>

      {/* Items list */}
      <div
        className="scroll-hide"
        style={{
          flex: 1,
          padding: "0 24px",
          position: "relative",
          zIndex: 1,
        }}
      >
        {items.length === 0 ? (
          <div
            style={{
              textAlign: "center",
              paddingTop: 48,
              color: "#3a2e18",
              fontSize: 13,
              lineHeight: 1.8,
            }}
          >
            <div style={{ fontSize: 28, marginBottom: 12 }}>☁</div>
            Your mind is full.
            <br />
            Start emptying it above.
          </div>
        ) : (
          <>
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
              Captured — {items.length}
            </div>
            {items.map((item, i) => (
              <div
                key={i}
                style={{
                  display: "flex",
                  alignItems: "center",
                  gap: 10,
                  padding: "11px 0",
                  borderBottom: "1px solid rgba(200,169,110,0.05)",
                }}
              >
                <div
                  style={{
                    width: 6,
                    height: 6,
                    borderRadius: "50%",
                    background: "rgba(200,169,110,0.3)",
                    flexShrink: 0,
                  }}
                />
                <div
                  style={{ flex: 1, fontSize: 13, color: "#7a6850", lineHeight: 1.4 }}
                >
                  {item}
                </div>
                <button
                  onClick={() => onRemove(i)}
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
            ))}
          </>
        )}
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
            background:
              items.length > 0
                ? "linear-gradient(135deg, #c8a96e 0%, #b08848 100%)"
                : "rgba(200,169,110,0.08)",
            borderRadius: 14,
            fontSize: 14,
            fontWeight: 700,
            color: items.length > 0 ? "#1a1208" : "#3a2e18",
            border: "1px solid rgba(200,169,110,0.15)",
            cursor: "pointer",
            fontFamily: "inherit",
            boxShadow:
              items.length > 0
                ? "0 8px 24px rgba(200,169,110,0.2)"
                : "none",
          }}
        >
          {items.length > 0
            ? `Shape ${items.length} item${items.length !== 1 ? "s" : ""} →`
            : "Continue to Shape →"}
        </button>
      </div>
    </div>
  );
}
