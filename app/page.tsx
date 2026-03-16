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
import { mapEventsToTasks, parseIcsEvents } from "@/lib/calendar";
import {
  beginGoogleOAuth,
  consumeGoogleOAuthFromHash,
  fetchGoogleEvents,
} from "@/lib/googleCalendar";
import { DEBUG } from "@/lib/debug";

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
  const [workTasks, setWorkTasks] = useState<Task[]>(DEFAULT_WORK);
  const [personalTasks, setPersonalTasks] = useState<Task[]>(DEFAULT_PERSONAL);
  const [dumpItems, setDumpItems] = useState<string[]>([]);
  const [parkedItems, setParkedItems] = useState<string[]>(DEFAULT_PARKED);
  const [googleConnected, setGoogleConnected] = useState(false);
  const [googleAccessToken, setGoogleAccessToken] = useState<string | null>(null);
  const [googleTokenExpiresAt, setGoogleTokenExpiresAt] = useState<number | null>(null);
  const [lastCalendarSync, setLastCalendarSync] = useState<string | null>(null);
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
        if (saved.workTasks) setWorkTasks(saved.workTasks);
        if (saved.personalTasks) setPersonalTasks(saved.personalTasks);
        if (saved.dumpItems) setDumpItems(saved.dumpItems);
        if (saved.parkedItems) setParkedItems(saved.parkedItems);
        if (typeof saved.googleConnected === "boolean")
          setGoogleConnected(saved.googleConnected);
        if (saved.googleAccessToken) setGoogleAccessToken(saved.googleAccessToken);
        if (typeof saved.googleTokenExpiresAt === "number") {
          setGoogleTokenExpiresAt(saved.googleTokenExpiresAt);
        }
        if (saved.lastCalendarSync) setLastCalendarSync(saved.lastCalendarSync);
      }
    } catch {}

    try {
      const token = consumeGoogleOAuthFromHash();
      if (token) {
        setGoogleAccessToken(token.accessToken);
        setGoogleTokenExpiresAt(token.expiresAt);
        setGoogleConnected(true);
        setLastCalendarSync(new Date().toISOString());
      }
    } catch {
      setGoogleConnected(false);
      setGoogleAccessToken(null);
      setGoogleTokenExpiresAt(null);
    }

    setHydrated(true);
  }, []);

  // Persist to localStorage
  useEffect(() => {
    if (!hydrated) return;
    localStorage.setItem(
      "genesis-way-v1",
      JSON.stringify({
        screen,
        big3,
        workTasks,
        personalTasks,
        dumpItems,
        parkedItems,
        googleConnected,
        googleAccessToken,
        googleTokenExpiresAt,
        lastCalendarSync,
      })
    );
  }, [
    screen,
    big3,
    workTasks,
    personalTasks,
    dumpItems,
    parkedItems,
    googleConnected,
    googleAccessToken,
    googleTokenExpiresAt,
    lastCalendarSync,
    hydrated,
  ]);

  const toggleBig3 = (id: string) => {
    setBig3((prev) =>
      prev.map((item) =>
        item.id === id ? { ...item, done: !item.done } : item
      )
    );
  };

  const connectGoogleCalendar = () => {
    beginGoogleOAuth(process.env.NEXT_PUBLIC_GOOGLE_CLIENT_ID ?? "");
  };

  const disconnectGoogleCalendar = () => {
    setGoogleConnected(false);
    setGoogleAccessToken(null);
    setGoogleTokenExpiresAt(null);
  };

  const syncGoogleCalendar = async (): Promise<number> => {
    if (!googleAccessToken || (googleTokenExpiresAt && googleTokenExpiresAt < Date.now() + 60_000)) {
      connectGoogleCalendar();
      return 0;
    }

    const events = await fetchGoogleEvents(googleAccessToken);
    const mapped = mapEventsToTasks(events, workTasks, personalTasks);
    const total = mapped.work.length + mapped.personal.length;

    if (total > 0) {
      setWorkTasks((prev) => [...prev, ...mapped.work]);
      setPersonalTasks((prev) => [...prev, ...mapped.personal]);
    }

    setGoogleConnected(true);
    setLastCalendarSync(new Date().toISOString());
    return total;
  };

  const importIcs = (rawIcs: string): number => {
    const events = parseIcsEvents(rawIcs);
    const mapped = mapEventsToTasks(events, workTasks, personalTasks);
    if (mapped.work.length === 0 && mapped.personal.length === 0) return 0;

    setWorkTasks((prev) => [...prev, ...mapped.work]);
    setPersonalTasks((prev) => [...prev, ...mapped.personal]);
    setLastCalendarSync(new Date().toISOString());
    return mapped.work.length + mapped.personal.length;
  };

  const importIcsFromUrl = async (url: string): Promise<number> => {
    const response = await fetch("/api/calendar/import", {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({ url }),
    });

    if (!response.ok) {
      throw new Error("Calendar URL import failed.");
    }

    const payload = (await response.json()) as { raw?: string };
    if (!payload.raw) return 0;
    return importIcs(payload.raw);
  };

  if (!hydrated) return null;

  const navTab = screen === "onboarding" ? undefined : screen;

  const SCREEN_NUMBERS: Record<Screen, number> = {
    onboarding: 1,
    dump: 2,
    shape: 3,
    fill: 4,
    park: 5,
  };

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
      <div style={{ flex: 1, overflow: "hidden", minHeight: 0, position: "relative" }}>
        {/* Screen number badge — debug only */}
        {DEBUG && (
          <div
            style={{
              position: "absolute",
              bottom: 10,
              right: 10,
              zIndex: 100,
              background: "rgba(0,0,0,0.45)",
              border: "1px solid rgba(255,255,255,0.12)",
              borderRadius: 6,
              padding: "2px 7px",
              fontSize: 11,
              fontWeight: 700,
              color: "rgba(255,255,255,0.45)",
              letterSpacing: 0.5,
              pointerEvents: "none",
              userSelect: "none" as const,
            }}
          >
            {SCREEN_NUMBERS[screen]}
          </div>
        )}
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
            googleConnected={googleConnected}
            lastCalendarSync={lastCalendarSync}
            onConnectGoogle={connectGoogleCalendar}
            onDisconnectGoogle={disconnectGoogleCalendar}
            onSyncGoogle={syncGoogleCalendar}
            onImportIcs={importIcs}
            onImportIcsUrl={importIcsFromUrl}
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
