"use client";

export default function SettingsScreen({
  showFeedbackIds,
  onToggleShowFeedbackIds,
  onBack,
  onOpenIntro,
}: {
  showFeedbackIds: boolean;
  onToggleShowFeedbackIds: () => void;
  onBack: () => void;
  onOpenIntro: () => void;
}) {
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

      <div
        style={{
          flexShrink: 0,
          padding: "16px 24px 14px",
          borderBottom: "1px solid rgba(200,169,110,0.06)",
          position: "relative",
          zIndex: 1,
          display: "flex",
          alignItems: "center",
          justifyContent: "space-between",
        }}
      >
        <button
          onClick={onBack}
          style={{
            width: 38,
            height: 38,
            borderRadius: 12,
            border: "1px solid rgba(200,169,110,0.1)",
            background: "rgba(255,255,255,0.03)",
            color: "#7a6850",
            fontSize: 18,
            cursor: "pointer",
            fontFamily: "inherit",
          }}
          aria-label="Back to planner"
        >
          ←
        </button>

        <div style={{ textAlign: "center", flex: 1 }}>
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
            Preferences
          </div>
          <div
            style={{
              fontSize: 24,
              fontWeight: 800,
              color: "#f0e4d0",
              letterSpacing: -0.8,
              lineHeight: 1,
            }}
          >
            Settings
          </div>
        </div>

        <div style={{ width: 38, height: 38 }} />
      </div>

      <div
        className="scroll-hide"
        style={{
          flex: 1,
          padding: "18px 24px 24px",
          position: "relative",
          zIndex: 1,
        }}
      >
        <div
          style={{
            background: "rgba(255,255,255,0.025)",
            border: "1px solid rgba(200,169,110,0.08)",
            borderRadius: 16,
            padding: "14px 14px",
            marginBottom: 12,
          }}
        >
          <div
            style={{
              fontSize: 10,
              fontWeight: 700,
              color: "#5a4830",
              letterSpacing: 1,
              textTransform: "uppercase",
              marginBottom: 10,
            }}
          >
            Feedback
          </div>

          <button
            onClick={onToggleShowFeedbackIds}
            style={{
              width: "100%",
              display: "flex",
              alignItems: "center",
              justifyContent: "space-between",
              gap: 10,
              padding: "10px 12px",
              borderRadius: 12,
              border: "1px solid rgba(200,169,110,0.1)",
              background: "rgba(255,255,255,0.02)",
              color: "#c0b090",
              cursor: "pointer",
              fontFamily: "inherit",
            }}
            aria-pressed={showFeedbackIds}
            aria-label="Toggle feedback identifiers"
          >
            <div style={{ textAlign: "left" }}>
              <div style={{ fontSize: 13, fontWeight: 700, color: "#e0d4c0" }}>
                Show feedback IDs
              </div>
              <div
                style={{
                  fontSize: 11,
                  color: "#6a5840",
                  marginTop: 2,
                  lineHeight: 1.4,
                }}
              >
                Visible tags like GW-P04 appear on every screen.
              </div>
            </div>

            <div
              style={{
                width: 42,
                height: 24,
                borderRadius: 999,
                background: showFeedbackIds
                  ? "rgba(200,169,110,0.35)"
                  : "rgba(200,169,110,0.12)",
                border: "1px solid rgba(200,169,110,0.2)",
                position: "relative",
                flexShrink: 0,
              }}
            >
              <div
                style={{
                  width: 18,
                  height: 18,
                  borderRadius: "50%",
                  background: showFeedbackIds ? "#c8a96e" : "#5a4830",
                  position: "absolute",
                  top: 2,
                  left: showFeedbackIds ? 21 : 2,
                }}
              />
            </div>
          </button>
        </div>

        <div
          style={{
            background: "rgba(255,255,255,0.025)",
            border: "1px solid rgba(200,169,110,0.08)",
            borderRadius: 16,
            padding: "14px 14px",
          }}
        >
          <div
            style={{
              fontSize: 10,
              fontWeight: 700,
              color: "#5a4830",
              letterSpacing: 1,
              textTransform: "uppercase",
              marginBottom: 10,
            }}
          >
            About
          </div>

          <button
            onClick={onOpenIntro}
            style={{
              width: "100%",
              borderRadius: 12,
              border: "1px solid rgba(200,169,110,0.1)",
              background: "rgba(255,255,255,0.02)",
              color: "#c0b090",
              padding: "11px 12px",
              fontSize: 13,
              fontWeight: 600,
              textAlign: "left",
              cursor: "pointer",
              fontFamily: "inherit",
            }}
          >
            View Genesis Way intro
          </button>
        </div>
      </div>
    </div>
  );
}
