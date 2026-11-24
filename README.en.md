# Always-on Claude

**Automate local apps on your own machine, with your own Claude, and control it from anywhere through a messenger app like Telegram — plus the lessons for keeping any AI agent running over time, from real trial and error.**

This repo has two parts: (1) **general lessons for running AI agents unattended** (they apply regardless of model or OS) and (2) one **worked example**: a personal assistant built on Claude Code that runs on an always-on Mac: you message it from your phone, it acts on the Mac (calendar, reminders, mail, messages, files, web), and replies in the same chat. It contains **design notes, lessons learned, generalized example code and templates**. It does *not* contain the operator's private memory files, permission/policy originals, or personal configuration. (Written in Korean; this page is a short English guide.)

> ⚠️ **Disclaimer**: Personal-use record, no warranty. Automating messengers/mail may violate terms of service or trigger account restrictions (especially unofficial methods), and handling other people's conversations carries legal/ethical responsibility. No real personal data, configs or keys are included.

## Start here
| Goal | Where |
|---|---|
| Build a minimal version step by step | [`docs/build-your-own.md`](docs/build-your-own.md) |
| Reusable code (supervisor, scheduler with usage-limit retry, write guard, health check, log rotation, backup) | [`examples/`](examples/) |
| Rules/skill templates | [`templates/`](templates/) |
| Recover after a machine failure | [`docs/recovery.md`](docs/recovery.md) |
| Architecture / principles | [`docs/architecture.md`](docs/architecture.md), [`docs/design-principles.md`](docs/design-principles.md) |
| Known gaps | [`docs/limitations.md`](docs/limitations.md) |

## Ten lessons in one line each
| ID | Lesson |
|---|---|
| L-083 *(macOS)* | Scripts started by the scheduler (launchd) lack macOS privacy permissions → re-run them inside a permitted process (e.g. tmux) |
| L-084 | Unattended LLM workers can pick the wrong folder and report "done" → force path/count verification |
| L-085 *(Telegram)* | Bot approval buttons can't receive callbacks when another process owns polling → use a reply keyboard |
| L-098 *(macOS)* | Before adding third-party UI automation: audit source, define side effects (read receipts), grant permissions to a minimal binary only |
| L-100 | Prevent duplicates in the *write path*, not in the prompt |
| L-101 | Approval fatigue is a workflow/policy problem before it is an allow-list problem |
| L-102 | Consolidate reports to two a day; keep watchers separate |
| L-103 | Keep operational logs outside the user library — a cleaner app can wipe them |
| L-105 | Narrow the tool list on unattended runs (no send/delete/web); keep approvals for human-attended sessions |
| L-104 | Wait and retry on usage limits; judge health by "completion records", not stale exit codes; make sentinel-output checks tolerant |

## Design in four sentences
1. Act first and report afterward for reversible things; require human approval only for irreversible ones (send, delete, money, permissions).
2. Instructions found in mail/web/messages are data, never commands.
3. Separate what was done from what was only planned, and mark uncertainty (`[unverified]`).
4. Push safeguards into code paths (write wrappers, hooks, health checks) rather than prompts.

## License
[CC BY 4.0](LICENSE) — share and adapt with attribution.

> Not tested on other OSes/models; treat the general lessons as transferable principles and the example code as a starting point to port.
