import type { Task } from "@/components/screens/FillScreen";

export interface CalendarEvent {
  id: string;
  title: string;
  start?: Date;
  allDay: boolean;
}

function unfoldIcsLines(raw: string): string[] {
  const baseLines = raw.replace(/\r\n/g, "\n").split("\n");
  const unfolded: string[] = [];

  for (const line of baseLines) {
    if ((line.startsWith(" ") || line.startsWith("\t")) && unfolded.length > 0) {
      unfolded[unfolded.length - 1] += line.slice(1);
    } else {
      unfolded.push(line);
    }
  }

  return unfolded;
}

function parseIcsDate(value: string): { date?: Date; allDay: boolean } {
  if (!value) return { date: undefined, allDay: false };

  // Example all-day: 20260314
  if (/^\d{8}$/.test(value)) {
    const year = Number(value.slice(0, 4));
    const month = Number(value.slice(4, 6)) - 1;
    const day = Number(value.slice(6, 8));
    return { date: new Date(year, month, day), allDay: true };
  }

  // Example timed: 20260314T133000Z or 20260314T133000
  const cleaned = value.endsWith("Z") ? value.slice(0, -1) : value;
  const match = cleaned.match(/^(\d{4})(\d{2})(\d{2})T(\d{2})(\d{2})(\d{2})$/);
  if (!match) return { date: undefined, allDay: false };

  const [, y, m, d, hh, mm, ss] = match;
  const isUtc = value.endsWith("Z");
  if (isUtc) {
    return {
      date: new Date(Date.UTC(Number(y), Number(m) - 1, Number(d), Number(hh), Number(mm), Number(ss))),
      allDay: false,
    };
  }

  return {
    date: new Date(Number(y), Number(m) - 1, Number(d), Number(hh), Number(mm), Number(ss)),
    allDay: false,
  };
}

function parseValueFromIcsLine(line: string): string {
  const idx = line.indexOf(":");
  return idx >= 0 ? line.slice(idx + 1).trim() : "";
}

function toTimeLabel(date?: Date, allDay?: boolean): string | undefined {
  if (!date) return undefined;
  if (allDay) return "All day";
  return date.toLocaleTimeString("en-US", {
    hour: "numeric",
    minute: "2-digit",
    hour12: true,
  });
}

function isLikelyWorkEvent(title: string): boolean {
  return /(meeting|client|project|proposal|review|team|standup|sync|work|sales|update|deadline)/i.test(
    title
  );
}

export function parseIcsEvents(raw: string): CalendarEvent[] {
  const lines = unfoldIcsLines(raw);
  const events: CalendarEvent[] = [];

  let inEvent = false;
  let summary = "";
  let dtStartRaw = "";

  for (const line of lines) {
    if (line === "BEGIN:VEVENT") {
      inEvent = true;
      summary = "";
      dtStartRaw = "";
      continue;
    }
    if (line === "END:VEVENT") {
      if (inEvent && summary.trim()) {
        const { date, allDay } = parseIcsDate(dtStartRaw);
        events.push({
          id: `${summary}-${date?.getTime() ?? "na"}-${events.length}`,
          title: summary.trim(),
          start: date,
          allDay,
        });
      }
      inEvent = false;
      continue;
    }
    if (!inEvent) continue;

    if (line.startsWith("SUMMARY")) {
      summary = parseValueFromIcsLine(line);
    } else if (line.startsWith("DTSTART")) {
      dtStartRaw = parseValueFromIcsLine(line);
    }
  }

  return events;
}

export function mapEventsToTasks(
  events: CalendarEvent[],
  existingWork: Task[],
  existingPersonal: Task[]
): { work: Task[]; personal: Task[] } {
  const work: Task[] = [];
  const personal: Task[] = [];

  let workCounter = existingWork.length;
  let personalCounter = existingPersonal.length;

  const existingKeySet = new Set(
    [...existingWork, ...existingPersonal].map((t) => `${t.text.toLowerCase()}|${t.time ?? ""}`)
  );

  for (const ev of events) {
    const text = ev.title.trim();
    if (!text) continue;

    const time = toTimeLabel(ev.start, ev.allDay);
    const key = `${text.toLowerCase()}|${time ?? ""}`;
    if (existingKeySet.has(key)) continue;

    const taskBase = {
      id: `cal-${Date.now()}-${Math.random().toString(36).slice(2, 8)}`,
      text,
      filter: "schedule",
      time,
    } satisfies Omit<Task, "code">;

    if (isLikelyWorkEvent(text)) {
      workCounter += 1;
      work.push({ ...taskBase, code: `W${workCounter}` });
    } else {
      personalCounter += 1;
      personal.push({ ...taskBase, code: `P${personalCounter}` });
    }

    existingKeySet.add(key);
  }

  return { work, personal };
}
