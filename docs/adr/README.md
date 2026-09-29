# Architecture decision records

One file per decision, in [Nygard format](https://cognitect.com/blog/2011/11/15/documenting-architecture-decisions). Records are immutable once accepted. A changed decision gets a new ADR that supersedes the old one, so the reasoning at the time survives.

CI checks that every file in this directory appears in the table below.

| # | Title | Status | Date |
|---|---|---|---|
| [0001](0001-adopt-the-template-process.md) | Adopt the ProjectTemplate process | accepted | 2026-09-29 |

## Template

```markdown
# ADR-NNNN: Short imperative title

* Status: proposed | accepted | superseded by ADR-NNNN
* Date: YYYY-MM-DD

## Context

What forces are at play. What is true today that makes this a decision rather than an obvious choice.

## Decision

What was decided, in the active voice.

## Consequences

### Positive
### Negative
### Neutral

## Alternatives considered

What else was on the table and why it lost.
```
