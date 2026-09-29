# ADR-0001: Adopt the ProjectTemplate process

* Status: accepted
* Date: 2026-09-29

## Context

Work is done by AI agents under a human director, across several repositories. Each repository that defines its own process makes agents relearn the rules on every switch, and makes the projects harder for a human to follow side by side. The pieces of a good process already existed, spread across repos: a board with estimates, strict branch and pull request rules, a full label taxonomy, an agent instruction file.

## Decision

This repository follows the process defined by [ProjectTemplate](https://github.com/ndharp/ProjectTemplate): its labels, issue forms, board fields, branch and commit conventions, checks and release flow, as written in `AGENTS.md`.

## Consequences

### Positive

* Agents carry one set of rules between repositories.
* A human can read any repo's board and history the same way.
* Process fixes land in the template once and reach every adopter.

### Negative

* Per-repo deviations need a written exception in the "This project" section of `AGENTS.md`, which is more ceremony than silently diverging.

### Neutral

* Labels, board and fields are created by `scripts/bootstrap.sh` rather than inherited, so re-running it after template changes is part of maintenance.

## Alternatives considered

* Per-repo processes, as before. Rejected: the relearning cost lands on every agent session.
* An organization-level `.github` repository. Rejected: these repositories live under a personal account, where organization-only features (issue types, shared secrets, project templates) do not apply.
