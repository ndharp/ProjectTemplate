# Contributing

This project is directed by Nate Harper and built with agents. The full process lives in [AGENTS.md](AGENTS.md); this is the short version.

## Where work lives

* Issues hold every piece of work. File one with the forms. Each carries one `type:` and one `area:` label.
* Milestones group issues toward a target version, listed in `docs/roadmap.md`.
* The project board shows each issue's Status, Estimate and Priority. TEMPLATE: link the board here.
* A question only the director can answer is a `decision` issue.

## A change, start to finish

1. Pick a Ready issue from the current milestone, or file one.
2. Branch `i<issue>-<slug>` from the open milestone branch, or from `main` when there is none.
3. Make the change. Update any doc it makes wrong, and add a CHANGELOG bullet if it is user-visible.
4. Run the checks listed in AGENTS.md under "This project".
5. Open a pull request with the template. `fix #NN` in the body closes the issue on merge.

## Commits

Subject line only, by default:

```
scope: what was done (fix #NN)
```

A body, when needed, is a bullet list of `- path: what changed`.

## Writing

Sentence-case headings. No em-dashes. Bullet lists instead of comma-joined enumerations. One idea per sentence.
