# Jira Board Setup (Genesis Way)

This guide is optimized for your current iOS TestFlight push.

## 1) Install VS Code Jira integration

1. Open Extensions in VS Code.
2. Install: Atlassian: Jira, Rovo Dev, Bitbucket.
3. Open Command Palette.
4. Run: Atlassian: Open Settings.
5. Sign in to Atlassian Cloud and choose your Jira site.

Tip: this repo includes an extension recommendation file at .vscode/extensions.json.

## 2) Create a board in Jira (web)

1. Open your Jira site.
2. Go to Projects -> Create project.
3. Choose Kanban.
4. Name it: Genesis Way iOS.
5. Key suggestion: GW.

Jira will create a board automatically from the new project.

## 3) Set board columns

Use these columns in order:

1. Backlog
2. Ready
3. In Progress
4. Blocked
5. Review
6. Done

## 4) Import starter backlog

1. In Jira, go to Settings -> System -> External System Import -> CSV.
2. Upload docs/jira-import-genesis-way.csv.
3. Map fields:
   - Summary -> Summary
   - Issue Type -> Issue Type
   - Description -> Description
   - Priority -> Priority
   - Labels -> Labels
4. Import into project GW.

## 5) Working agreement

1. Every branch starts with Jira key. Example: GW-12-testflight-first-upload.
2. Every PR title starts with Jira key. Example: GW-12: automate TestFlight upload.
3. Move cards:
   - Start work -> In Progress
   - Waiting on Apple or external dependency -> Blocked
   - Open PR -> Review
   - Merged + verified -> Done

## 6) Suggested epics

1. EPIC: iOS Release Pipeline
2. EPIC: Genesis Way Core UX
3. EPIC: Calendar Integration
4. EPIC: QA and Beta Feedback

## 7) Optional automation (next)

After your team is active in Apple Developer, add Jira automation rules:

1. When branch contains issue key, transition card to In Progress.
2. When PR opens, transition card to Review.
3. When PR merges to main, transition card to Done.
