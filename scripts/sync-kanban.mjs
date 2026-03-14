import { existsSync, readFileSync, writeFileSync } from "node:fs";
import { execSync } from "node:child_process";
import path from "node:path";

const root = process.cwd();
const boardPath = path.join(root, "KANBAN.md");

if (!existsSync(boardPath)) {
  console.error("KANBAN.md not found at repo root.");
  process.exit(1);
}

const SECTION_ORDER = [
  "Backlog",
  "Ready",
  "In Progress",
  "Blocked",
  "Review",
  "Done",
];

const now = new Date().toISOString();
const branch = safeGit("git rev-parse --abbrev-ref HEAD") ?? "unknown";
const dirty = safeGit("git status --porcelain")?.trim().length ? "yes" : "no";

const file = readFileSync(boardPath, "utf8");
const sections = parseBoard(file);

for (const section of SECTION_ORDER) {
  if (!sections[section]) sections[section] = [];
}

// Remove malformed one-character tasks (ex: stray "F").
for (const section of SECTION_ORDER) {
  sections[section] = sections[section].filter((task) => task.text.trim().length >= 3);
}

const doneChecks = [
  {
    task: "Fastlane beta lane added",
    done: fileContains("ios/fastlane/Fastfile", "lane :beta"),
  },
  {
    task: "GitHub Actions iOS TestFlight workflow added",
    done: fileContains(".github/workflows/ios-testflight.yml", "name: iOS TestFlight"),
  },
  {
    task: "Local board workflow docs added",
    done: existsSync(path.join(root, "docs/local-scrum-board.md")),
  },
  {
    task: "Add App Store Connect API key secrets in GitHub",
    done:
      Boolean(process.env.APP_STORE_CONNECT_KEY_ID) &&
      Boolean(process.env.APP_STORE_CONNECT_ISSUER_ID) &&
      Boolean(process.env.APP_STORE_CONNECT_PRIVATE_KEY),
  },
];

for (const check of doneChecks) {
  if (!check.done) continue;
  moveTaskToDone(sections, check.task);
}

const output = renderBoard(sections, {
  now,
  branch,
  dirty,
});

writeFileSync(boardPath, output, "utf8");
console.log("KANBAN.md synced.");

function safeGit(command) {
  try {
    return execSync(command, { encoding: "utf8", stdio: ["ignore", "pipe", "ignore"] });
  } catch {
    return null;
  }
}

function fileContains(relPath, text) {
  const fullPath = path.join(root, relPath);
  if (!existsSync(fullPath)) return false;
  return readFileSync(fullPath, "utf8").includes(text);
}

function parseBoard(content) {
  const lines = content.replace(/\r\n/g, "\n").split("\n");
  const sections = {};
  let current = null;

  for (const line of lines) {
    const sectionMatch = line.match(/^##\s+(.+)$/);
    if (sectionMatch) {
      current = sectionMatch[1].trim();
      if (!sections[current]) sections[current] = [];
      continue;
    }

    const taskMatch = line.match(/^-\s+\[( |x)\]\s+(.+)$/);
    if (taskMatch && current) {
      sections[current].push({
        checked: taskMatch[1] === "x",
        text: taskMatch[2].trim(),
      });
    }
  }

  return sections;
}

function moveTaskToDone(sections, taskText) {
  for (const sectionName of Object.keys(sections)) {
    const idx = sections[sectionName].findIndex((item) => item.text === taskText);
    if (idx === -1) continue;

    const [item] = sections[sectionName].splice(idx, 1);
    item.checked = true;

    if (!sections.Done.some((existing) => existing.text === taskText)) {
      sections.Done.push(item);
    }
    return;
  }

  if (!sections.Done.some((existing) => existing.text === taskText)) {
    sections.Done.push({ checked: true, text: taskText });
  }
}

function renderBoard(sections, meta) {
  const lines = [
    "# Genesis Way Board",
    `> Synced: ${meta.now} | Branch: ${meta.branch} | Dirty: ${meta.dirty}`,
    "",
  ];

  for (const section of SECTION_ORDER) {
    lines.push(`## ${section}`, "");

    if (sections[section].length === 0) {
      lines.push("- [ ] (empty)", "");
      continue;
    }

    for (const task of sections[section]) {
      lines.push(`- [${task.checked ? "x" : " "}] ${task.text}`);
    }
    lines.push("");
  }

  return lines.join("\n");
}
