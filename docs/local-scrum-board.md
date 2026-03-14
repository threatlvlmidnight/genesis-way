# Local Scrum Board (No Jira)

Use this board directly in VS Code with a lightweight Kanban extension.

## Recommended extension

1. Kanban by Marcel Joachim Kloubert (`mkloubert.vscode-kanban`)

Optional:

1. Markdown Kanban (`holooooo.markdown-kanban`)
2. Todo Tree (`gruntfuggly.todo-tree`)

## Sync command

Run this from the repo root whenever you want the board to sync with current git/repo state:

```bash
npm run board:sync
```

What it syncs automatically:

1. Marks known completed setup items as Done when required files/settings are detected.
2. Adds a sync line at the top of `KANBAN.md` with timestamp, branch, and dirty state.
3. Removes malformed one-character tasks accidentally left in the board.

## Board columns

1. Backlog
2. Ready
3. In Progress
4. Blocked
5. Review
6. Done

## Sprint 0 (current)

### Backlog

- [ ] Build appears in TestFlight and can be installed
- [ ] External tester group created
- [ ] Beta App Review submitted

### Ready

- [ ] Confirm Apple paid team appears in Xcode
- [ ] Add App Store Connect API key secrets in GitHub

### In Progress

- [ ] Test app on device and list bugs

### Blocked

- [ ] Set signing to paid team in Xcode (blocked until Apple team activation finishes)

### Review

- [ ] Validate iOS TestFlight workflow run output

### Done

- [x] Add Fastlane lanes for TestFlight build and upload
- [x] Add GitHub Actions workflow for iOS TestFlight
- [x] Add setup docs and importable issue list

## Working rules (simple)

1. Keep at most 2 items in In Progress.
2. If blocked for more than 24 hours, move to Blocked with one-line reason.
3. Only move to Done after testing on device or simulator.
4. Use branch names with a short key, for example: `gw-signing-fix`.

## Daily update format

1. Yesterday: what moved to Done
2. Today: what is in In Progress
3. Blockers: anything in Blocked
