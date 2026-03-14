type Tab = "dump" | "shape" | "fill" | "park";

const TABS: { id: Tab; label: string; icon: string }[] = [
  { id: "dump", label: "Dump", icon: "↓" },
  { id: "shape", label: "Shape", icon: "⬡" },
  { id: "fill", label: "Fill", icon: "◎" },
  { id: "park", label: "Park", icon: "P" },
];

export default function BottomNav({
  active,
  onChange,
}: {
  active: Tab;
  onChange: (tab: Tab) => void;
}) {
  return (
    <div
      style={{
        flexShrink: 0,
        borderTop: "1px solid rgba(200,169,110,0.06)",
        background: "rgba(18,12,6,0.92)",
        backdropFilter: "blur(30px)",
        WebkitBackdropFilter: "blur(30px)",
        padding: "10px 8px 4px",
        display: "flex",
        zIndex: 20,
      }}
    >
      {TABS.map((tab) => {
        const isActive = tab.id === active;
        return (
          <button
            key={tab.id}
            onClick={() => onChange(tab.id)}
            style={{
              flex: 1,
              display: "flex",
              flexDirection: "column",
              alignItems: "center",
              gap: 3,
              fontSize: 10,
              fontWeight: 600,
              color: isActive ? "#c8a96e" : "#2e2418",
              letterSpacing: 0.3,
              padding: "4px 0",
              background: "none",
              border: "none",
              cursor: "pointer",
              fontFamily: "inherit",
            }}
          >
            <div
              style={{
                width: 30,
                height: 30,
                borderRadius: 10,
                display: "flex",
                alignItems: "center",
                justifyContent: "center",
                fontSize: 15,
                marginBottom: 1,
                background: isActive ? "rgba(200,169,110,0.1)" : "transparent",
              }}
            >
              {tab.icon}
            </div>
            {tab.label}
          </button>
        );
      })}
    </div>
  );
}
