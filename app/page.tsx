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
import SettingsScreen from "@/components/screens/SettingsScreen";
import { mapEventsToTasks, parseIcsEvents } from "@/lib/calendar";
import {
  beginGoogleOAuth,
  consumeGoogleOAuthFromHash,
  fetchGoogleEvents,
} from "@/lib/googleCalendar";

type Screen = "onboarding" | "dump" | "shape" | "fill" | "park" | "settings";

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
  const [showFeedbackIds, setShowFeedbackIds] = useState(true);
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
        if (typeof saved.showFeedbackIds === "boolean") {
          setShowFeedbackIds(saved.showFeedbackIds);
        }
      }
    } catch {}

    void (async () => {
      try {
        const token = await consumeGoogleOAuthFromHash();
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
      } finally {
        setHydrated(true);
      }
    })();
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
        showFeedbackIds,
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
    showFeedbackIds,
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
    void beginGoogleOAuth(process.env.NEXT_PUBLIC_GOOGLE_CLIENT_ID ?? "");
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

  const navTab = screen === "onboarding" || screen === "settings" ? undefined : screen;

  const SCREEN_IDS: Record<Screen, { code: string; label: string }> = {
    onboarding: { code: "GW-P01", label: "Onboarding" },
    dump: { code: "GW-P02", label: "Dump" },
    shape: { code: "GW-P03", label: "Shape" },
    fill: { code: "GW-P04", label: "Fill" },
    park: { code: "GW-P05", label: "Park" },
    settings: { code: "GW-S01", label: "Settings" },
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
        {showFeedbackIds && (
          <div
            style={{
              position: "absolute",
              top: 10,
              left: "50%",
              transform: "translateX(-50%)",
              zIndex: 200,
              background: "rgba(200,169,110,0.95)",
              border: "1px solid rgba(255,255,255,0.45)",
              borderRadius: 999,
              padding: "5px 12px",
              fontSize: 11,
              fontWeight: 800,
              color: "#1a1208",
              letterSpacing: 0.5,
              boxShadow: "0 8px 22px rgba(0,0,0,0.35)",
              pointerEvents: "none",
              userSelect: "none" as const,
            }}
            aria-label={`Page identifier ${SCREEN_IDS[screen].code}`}
          >
            {SCREEN_IDS[screen].code} · {SCREEN_IDS[screen].label}
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
            onOpenSettings={() => setScreen("settings")}
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
        {screen === "settings" && (
          <SettingsScreen
            showFeedbackIds={showFeedbackIds}
            onToggleShowFeedbackIds={() =>
              setShowFeedbackIds((previous) => !previous)
            }
            onBack={() => setScreen("fill")}
            onOpenIntro={() => setScreen("onboarding")}
          />
        )}
      </div>

      {/* Bottom nav — hidden on onboarding/settings */}
      {screen !== "onboarding" && screen !== "settings" && (
        <BottomNav
          active={navTab as "dump" | "shape" | "fill" | "park"}
          onChange={(tab) => setScreen(tab)}
        />
      )}
    </div>
  );

  return <PhoneWrapper>{appContent}</PhoneWrapper>;
}
