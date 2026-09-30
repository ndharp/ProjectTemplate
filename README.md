# ProjectTemplate

One agile process for repos directed by Nate Harper and built by AI agents. GitHub is the tracker, the board and the enforcement: issues, labels, milestones, a Projects board, Actions checks and releases follow the same rules in every adopting repo.

## Why it exists

Each project grew its own process. One repo has the best board, another the strictest contributing rules, a third the fullest label set. An agent moving between repos relearns the process each time, and a human following along reads a different convention in each. This repo is the one copy: templates for what GitHub can template, scripts for what it cannot, and the rules agents follow written once.

## The process at a glance

* Every piece of work is an issue carrying exactly one `type:` and one `area:` label.
* Issues flow Backlog → Ready → In progress → In review → Done on a Projects board.
* Estimates are Fibonacci points (1, 2, 3, 5, 8, 13) in the board's Estimate field. 13 means split it.
* Milestones are the planning horizon, each with a due date and a target version.
* One branch per issue (`i38-ui-polish`), one pull request per issue, `fix #NN` closes it on merge.
* Commits are `scope: what was done`, subject line only by default, at most 72 characters.
* Questions for the director are `decision` issues. Decisions worth keeping become ADRs.
* A milestone closing cuts a release: tag `vX.Y.Z` and the release workflow drafts it from the CHANGELOG.

The full rules are in [AGENTS.md](AGENTS.md). [CONTRIBUTING.md](CONTRIBUTING.md) is the human summary.

## What's in the box

```
AGENTS.md                     The canonical process. Claude Code and Codex read it
CLAUDE.md                     Pointer to AGENTS.md
CONTRIBUTING.md               One-screen human summary
CHANGELOG.md                  Keep a Changelog stub
.github/ISSUE_TEMPLATE/       Forms: feature, bug, task, spike, decision, epic
.github/pull_request_template.md
.github/workflows/process.yml Blocks a merge on a malformed PR, commit or issue
.github/workflows/add-to-project.yml
.github/workflows/ci.yml      House-pattern placeholder to fill per repo
.github/workflows/release.yml v* tag → build → draft GitHub release
docs/adr/                     Architecture decision records, Nygard format
docs/roadmap.md               Milestone table with target versions
docs/project-readme.md        The board's README, pushed by bootstrap
scripts/new-project.sh        Nothing → repo, board, milestone 1, starting issues
scripts/bootstrap.sh          Labels, board, fields, link. Idempotent
scripts/board.sh              Set an issue's Status, Estimate or Priority
```

## Start a new project

```bash
git clone git@github.com:ndharp/ProjectTemplate
ProjectTemplate/scripts/new-project.sh my-game --areas core,ui,build
```

The script creates the repo from this template, sets up labels, the board and its fields, creates milestone 1 and files the starting issues. It ends by printing a checklist of the settings no API reaches. Then:

1. Work the checklist.
2. Answer the framing decision issue: what is milestone 1's outcome?
3. File the milestone 1 epic and split it into estimated, Ready sub-issues.

## Adopt it in an existing repo

1. Copy in `.github/`, `AGENTS.md`, `CLAUDE.md`, `scripts/` and `docs/adr/`. Merge rather than overwrite: keep the repo's own issue forms next to these, and keep its project knowledge in the "This project" section of AGENTS.md.
2. Run `scripts/bootstrap.sh owner/repo --areas <existing areas>`. It renames spaced label variants in place, creates the canonical set, and leaves extra local labels alone. `--project N` upgrades an existing board instead of creating one.
3. Map size labels onto Estimates: xs is 1, s is 2, m is 3, l is 5, xl is 13. Delete the `size:` labels after.
4. For each convention the repo does differently, adopt the template's or record the exception in "This project".

Adoption is done when `grep -rn "TEMPLATE[:]" .` finds nothing. The bracket keeps the command from matching itself.

## What stays per-repo

Fill-in points are the lines `grep -rn "TEMPLATE[:]" .` finds.

* The `area:` labels.
* Build steps in `ci.yml` and packaging in `release.yml`.
* The Verification checklist in the pull request template.
* The "This project" section of AGENTS.md.
* README, docs and changelog content.

## License

MIT. See [LICENSE](LICENSE).
