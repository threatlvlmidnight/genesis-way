const PHASES = [
  {
    num: 1,
    name: "Dump It",
    desc: "Empty your mind onto paper. The brain is for thinking — not for storing every task, idea, and obligation you're carrying.",
    quote: '"Get it all out of your head. That\'s the problem."',
  },
  {
    num: 2,
    name: "Shape It",
    desc: "Three tools. Wall calendar for rhythm. Digital calendar for appointments. Paper planner for daily execution.",
    quote: '"Give yourself time to shape your week."',
  },
  {
    num: 3,
    name: "Fill It",
    desc: "Every task earns a time slot before your day begins. Anticipate. Assign. Execute with undivided attention.",
    quote: '"Have every item assigned before you start your day."',
  },
];

export default function OnboardingScreen({
  onBegin,
  onSkip,
}: {
  onBegin: () => void;
  onSkip: () => void;
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
          flex: 1,
          padding: "16px 24px 0",
          position: "relative",
          zIndex: 1,
          display: "flex",
          flexDirection: "column",
          overflowY: "auto",
          WebkitOverflowScrolling: "touch",
        }}
      >
        {/* Status row */}
        <div
          style={{
            display: "flex",
            justifyContent: "space-between",
            alignItems: "center",
            marginBottom: 32,
          }}
        >
          <span
            style={{ fontSize: 15, fontWeight: 700, color: "#b89050", letterSpacing: -0.5 }}
          >
            9:41
          </span>
          <span style={{ fontSize: 12, color: "#3a2e18" }}>●●● 5G ▪▪▪</span>
        </div>

        {/* Wordmark */}
        <div style={{ marginBottom: 32 }}>
          <div
            style={{
              fontSize: 10,
              fontWeight: 600,
              color: "#4a3820",
              letterSpacing: 3,
              textTransform: "uppercase",
              marginBottom: 10,
            }}
          >
            Dan Holland · Coachplus
          </div>
          <div
            style={{
              fontSize: 44,
              fontWeight: 800,
              color: "#f2e8d8",
              lineHeight: 1.0,
              letterSpacing: -2,
            }}
          >
            The
            <br />
            Genesis
            <br />
            Way
          </div>
          <div
            style={{
              fontSize: 14,
              fontWeight: 400,
              color: "#5a4830",
              lineHeight: 1.55,
              marginTop: 12,
            }}
          >
            A 3-step creation process for designing your 168 hours — not just
            managing them.
          </div>
        </div>

        {/* Phase progress strip */}
        <div style={{ display: "flex", gap: 6, marginBottom: 24 }}>
          {[0, 1, 2].map((i) => (
            <div
              key={i}
              style={{
                flex: 1,
                height: 3,
                borderRadius: 2,
                background: i === 0 ? "#c8a96e" : "rgba(200,169,110,0.15)",
              }}
            />
          ))}
        </div>

        {/* Phase cards */}
        {PHASES.map((phase) => (
          <div
            key={phase.num}
            className="glass-card"
            style={{ marginBottom: 10 }}
          >
            <div
              style={{
                padding: "18px 20px",
                display: "flex",
                gap: 16,
                alignItems: "flex-start",
              }}
            >
              <div
                style={{
                  width: 36,
                  height: 36,
                  borderRadius: 10,
                  background: "rgba(200,169,110,0.08)",
                  border: "1px solid rgba(200,169,110,0.15)",
                  display: "flex",
                  alignItems: "center",
                  justifyContent: "center",
                  fontSize: 17,
                  fontWeight: 800,
                  color: "#c8a96e",
                  flexShrink: 0,
                }}
              >
                {phase.num}
              </div>
              <div style={{ flex: 1 }}>
                <div
                  style={{
                    fontSize: 16,
                    fontWeight: 700,
                    color: "#f0e4d0",
                    letterSpacing: -0.3,
                    marginBottom: 5,
                  }}
                >
                  {phase.name}
                </div>
                <div
                  style={{
                    fontSize: 12,
                    fontWeight: 400,
                    color: "#6a5840",
                    lineHeight: 1.55,
                  }}
                >
                  {phase.desc}
                </div>
                <div
                  style={{
                    marginTop: 8,
                    fontSize: 11,
                    fontWeight: 400,
                    fontStyle: "italic",
                    color: "rgba(200,169,110,0.45)",
                    paddingLeft: 10,
                    borderLeft: "1.5px solid rgba(200,169,110,0.18)",
                    lineHeight: 1.45,
                  }}
                >
                  {phase.quote}
                </div>
              </div>
            </div>
          </div>
        ))}

        {/* CTA */}
        <div style={{ paddingTop: 24, paddingBottom: 24 }}>
          <button
            onClick={onBegin}
            style={{
              width: "100%",
              padding: 17,
              background: "linear-gradient(135deg, #c8a96e 0%, #b08848 100%)",
              borderRadius: 16,
              fontSize: 15,
              fontWeight: 700,
              color: "#1a1208",
              textAlign: "center",
              letterSpacing: -0.2,
              marginBottom: 16,
              boxShadow:
                "0 12px 32px rgba(200,169,110,0.3), inset 0 1px 0 rgba(255,255,255,0.2)",
              border: "none",
              cursor: "pointer",
              fontFamily: "inherit",
            }}
          >
            Begin Morning Preparation
          </button>
          <button
            onClick={onSkip}
            style={{
              display: "block",
              width: "100%",
              fontSize: 13,
              fontWeight: 500,
              color: "#3a2e18",
              textAlign: "center",
              background: "none",
              border: "none",
              cursor: "pointer",
              fontFamily: "inherit",
            }}
          >
            Already familiar? Skip intro →
          </button>
        </div>
      </div>
    </div>
  );
}
