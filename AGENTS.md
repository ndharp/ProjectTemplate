# Agent process

This project is directed by Nate Harper and built by agents. Claude Code and Codex both read this file. GitHub is the tracker: issues hold the work, the project board holds the state, and this file holds the rules. The [README](README.md) covers what the project is.

## Roles

* Nate sets direction, orders the backlog, answers decision issues and has final say.
* The agent builds, tests, writes first drafts and keeps the board current.

## Where work lives

* Every change traces to an issue. File one before starting work that has none.
* Labels classify: exactly one `type:` and one `area:` label per issue.
* Priority: `prio:p0` main is broken, `prio:p1` this milestone, `prio:p2` next milestone, `prio:p3` someday.
* `status:blocked`, `status:deferred` and `status:needs-design` say why an issue is parked.
* Milestones are the planning horizon. Each has a due date and a target version, listed in `docs/roadmap.md`.
* The project board tracks Status, Estimate, Priority, Start date and Target date. TEMPLATE: link the board here.
* The Development sidebar links branches and pull requests to the issue. `fix #NN` in the pull request creates the link and closes the issue on merge.

## The issue lifecycle

Status moves Backlog → Ready → In progress → In review → Done.

An issue is Ready when:

* It carries one `type:` and one `area:` label.
* It has a milestone.
* Its Estimate is 1 to 8.
* Its acceptance criteria can be checked by someone else.
* It carries no `status:` label.

An issue is Done when:

* The acceptance criteria are met.
* The checks are green.
* The pull request merged with `fix #NN`.
* The docs and CHANGELOG are current.

## Estimation

Estimates are Fibonacci points in the board's Estimate field:

* 1: under an hour
* 2: a couple of hours
* 3: half a day
* 5: a day or two
* 8: several days
* 13: too big. Split it before it can be Ready.

Estimate at triage. Re-estimate freely until work starts, never after.

## Picking work

* Current milestone first. Within it, `prio:p0` before `prio:p1`, down to `prio:p3`.
* One issue in progress per agent.
* Claiming is three actions: assign yourself, move the card to In progress, and comment which agent is working. Both agents act as ndharp, so the comment is the disambiguator.

## Branches, commits and pull requests

* One branch per issue, named `i<issue>-<slug>`: `i38-ui-polish`.
* Milestone work branches from the open milestone branch (`m4-game-completion`) when one exists, otherwise from `main`. The milestone branch rolls up to `main` in one pull request.
* Never commit to `main` directly.
* Commits: `scope: what was done (fix #NN)`. Subject line only by default. A body, when needed, is a bullet list of `- path: what changed`.
* One pull request per issue, one issue closed per pull request, `fix #NN` in the body.
* Fill every section of the pull request template. Verification lists what was actually run.

## Epics and sub-issues

An outcome that needs more than one pull request is an epic.

* File it with the epic form. It carries `epic`, the dominant `type:` of its children and one `area:`.
* Attach each child as a sub-issue. The API takes the database id, not the issue number:

  ```bash
  child_id=$(gh api "repos/$REPO/issues/$CHILD" --jq .id)
  gh api "repos/$REPO/issues/$PARENT/sub_issues" -X POST -F sub_issue_id="$child_id"
  ```

* The board shows sub-issue progress on the parent. An epic closes when its children are done.

## Decisions and ADRs

* A question only Nate can answer is a decision issue: label `decision`, assigned to Nate, with the milestone that is blocked without an answer. It needs no `type:` label. An answer comment closes it, not a pull request.
* An issue waiting on one carries `status:needs-design` and links the decision issue.
* A decision that shapes the project long-term becomes an ADR in `docs/adr/`, in the format its README gives. Accepted ADRs are immutable; a change gets a superseding ADR. The index updates in the same pull request.

## The iteration loop

An iteration answers one question.

1. **Frame it.** Set the question with Nate, and what would answer it. "Integrate the attachments" is not a question.
2. **Baseline.** The checks pass, or the existing failures are written down.
3. **Build the smallest slice that answers it.**
4. **Check it in the running project.** Tests are not enough: run it and look.
5. **Review.** Commit, then have the other agent review the commit. From Claude Code that is `/codex:review`. Apply the fixes it finds.
6. **Nate reviews it.** Nate approves it, sends it back or drops it.
7. **Record it.** A keeper decision becomes an ADR. The last commit or handoff note says where the next iteration starts.

## Docs and changelog

* A change that makes a doc wrong updates it in the same pull request.
* Every user-visible change gets a CHANGELOG bullet under `[Unreleased]`, ending `(#NN)`.

## Releases

A release makes sense when a milestone closes, or when a `prio:p0` fix is worth shipping alone.

* Versions are semver, `0.x` until Nate declares 1.0.
* A milestone closing bumps the minor version. A fix shipped alone bumps the patch.
* `docs/roadmap.md` lists each milestone with its target version.

Cutting one:

1. File a release issue: `release: cut X.Y.Z`, labels `type:chore` and `area:build`. The release pull request closes it, moves `[Unreleased]` to `[X.Y.Z] - YYYY-MM-DD` in the CHANGELOG and bumps the project's own version. TEMPLATE: say where the version lives in this project.
2. After it merges, tag main: `git tag vX.Y.Z && git push origin vX.Y.Z`.
3. The release workflow builds the artifacts and drafts a GitHub release with the CHANGELOG section as notes.
4. Nate reviews the draft and publishes it.

## Board hygiene

* The agent moves cards from Backlog through In review by hand. `scripts/board.sh <issue> status "In progress"` does it from the terminal, and sets Estimate and Priority the same way.
* Merging and closing move cards to Done through the board's built-in workflows. Never hand-move a card to Done.
* Priority lives in the label and in the field. Set both at triage. The label wins on conflict.

## Starting a project

Day zero for a new repo:

1. From a ProjectTemplate checkout, run `scripts/new-project.sh <name> --areas <a,b,c>`. It creates the repo from the template, bootstraps labels, the board and its fields, creates milestone 1 and files the starting issues.
2. Work the checklist the script prints. Most of it is board settings no API reaches.
3. Get the framing decision issue answered: what is milestone 1's outcome?
4. File the milestone 1 epic with the answer as its outcome. Split it into slices, attach them as sub-issues, estimate them, mark them Ready.
5. Enter the loop.

Adopting the process in an existing repo is covered in the [README](README.md).

## Two agents

* Only one agent writes in a checkout at a time.
* Parallel work goes in its own git worktree.

## This project

TEMPLATE: replace this section in the adopting repo. It holds:

* What the project is, in two sentences.
* Build, test and run commands. The checks a pull request must pass.
* The `area:` labels and what each covers.
* Gotchas: the facts an agent would otherwise rediscover the hard way.
