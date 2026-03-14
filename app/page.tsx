"use client";

import { useState, useEffect } from "react";
import PhoneWrapper from "@/components/PhoneWrapper";
import BottomNav from "@/components/BottomNav";
import OnboardingScreen from "@/components/screens/OnboardingScreen";
import DumpScreen from "@/components/screens/DumpScreen";
import ShapeScreen from "@/components/screens/ShapeScreen";
import FillScreen from "@/components/screens/FillScreen";
import type { Big3Item, Task } from "@/components/screens/FillScreen";
import ParkScreen from "@/components/screens/ParkScreen";

type Screen = "onboarding" | "dump" | "shape" | "fill" | "park";

const DEFAULT_BIG3: Big3Item[] = [
  { id: "b1", text: "Present Genesis Way POC to Dan", done: true },
  { id: "b2", text: "Weekly review with Corrine", done: false },
  { id: "b3", text: "Review Q1 client onboarding", done: false },
];

const DEFAULT_WORK: Task[] = [
  {
    id: "w1",
    text: "Follow up Howard — John Maxwell",
    code: "W1",
    filter: "schedule",
    time: "9am",
  },
  {
    id: "w2",
    text: "Disruptor Manufacturing update",
    code: "W2",
    filter: "schedule",
  },
  { id: "w3", text: "15-min with Corrine", code: "W3", filter: "delegate" },
];

const DEFAULT_PERSONAL: Task[] = [
  {
    id: "p1",
    text: "Send card to son",
    code: "P1",
    filter: "schedule",
    time: "5pm",
  },
  { id: "p2", text: "Thursday date night", code: "P2", filter: "park" },
];

const DEFAULT_PARKED = [
  "Call John Maxwell's assistant",
  "Research Q2 keynote topics",
  "Update website bio",
];

export default function Home() {
  const [screen, setScreen] = useState<Screen>("onboarding");
  const [big3, setBig3] = useState<Big3Item[]>(DEFAULT_BIG3);
  const [workTasks] = useState<Task[]>(DEFAULT_WORK);
  const [personalTasks] = useState<Task[]>(DEFAULT_PERSONAL);
  const [dumpItems, setDumpItems] = useState<string[]>([]);
  const [parkedItems, setParkedItems] = useState<string[]>(DEFAULT_PARKED);
  const [hydrated, setHydrated] = useState(false);

  // Hydrate from localStorage
  useEffect(() => {
    try {
      const raw = localStorage.getItem("genesis-way-v1");
      if (raw) {
        const saved = JSON.parse(raw);
        if (saved.screen && saved.screen !== "onboarding")
          setScreen(saved.screen);
        if (saved.big3) setBig3(saved.big3);
        if (saved.dumpItems) setDumpItems(saved.dumpItems);
        if (saved.parkedItems) setParkedItems(saved.parkedItems);
      }
    } catch {}
    setHydrated(true);
  }, []);

  // Persist to localStorage
  useEffect(() => {
    if (!hydrated) return;
    localStorage.setItem(
      "genesis-way-v1",
      JSON.stringify({ screen, big3, dumpItems, parkedItems })
    );
  }, [screen, big3, dumpItems, parkedItems, hydrated]);

  const toggleBig3 = (id: string) => {
    setBig3((prev) =>
      prev.map((item) =>
        item.id === id ? { ...item, done: !item.done } : item
      )
    );
  };

  if (!hydrated) return null;

  const navTab = screen === "onboarding" ? undefined : screen;

  const appContent = (
    <div
      style={{
        height: "100%",
        display: "flex",
        flexDirection: "column",
        overflow: "hidden",
      }}
    >
      {/* Screen area */}
      <div style={{ flex: 1, overflow: "hidden", minHeight: 0 }}>
        {screen === "onboarding" && (
          <OnboardingScreen
            onBegin={() => setScreen("dump")}
            onSkip={() => setScreen("fill")}
          />
        )}
        {screen === "dump" && (
          <DumpScreen
            items={dumpItems}
            onAdd={(item) => setDumpItems((p) => [...p, item])}
            onRemove={(i) =>
              setDumpItems((p) => p.filter((_, idx) => idx !== i))
            }
            onContinue={() => setScreen("shape")}
          />
        )}
        {screen === "shape" && (
          <ShapeScreen
            dumpItems={dumpItems}
            onContinue={() => setScreen("fill")}
          />
        )}
        {screen === "fill" && (
          <FillScreen
            big3={big3}
            workTasks={workTasks}
            personalTasks={personalTasks}
            onToggleBig3={toggleBig3}
            onShowIntro={() => setScreen("onboarding")}
          />
        )}
        {screen === "park" && (
          <ParkScreen
            items={parkedItems}
            onAdd={(item) => setParkedItems((p) => [...p, item])}
            onRemove={(i) =>
              setParkedItems((p) => p.filter((_, idx) => idx !== i))
            }
          />
        )}
      </div>

      {/* Bottom nav — hidden on onboarding */}
      {screen !== "onboarding" && (
        <BottomNav
          active={navTab as "dump" | "shape" | "fill" | "park"}
          onChange={(tab) => setScreen(tab)}
        />
      )}
    </div>
  );

  return <PhoneWrapper>{appContent}</PhoneWrapper>;
}
