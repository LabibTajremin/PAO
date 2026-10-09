# PAO

PAO is a mobile marketplace for Bangladesh. It connects customers with verified local
service providers (electricians, plumbers, AC technicians, home salon, drivers) at fixed,
platform-set prices.

This repository currently holds the **build kit**: the product requirements and a phased
instruction set that an AI coding agent follows to build the full product — Go backend,
Flutter customer and partner apps, and a Flutter Web admin panel. P00 replaces this README
with the developer README.

| What | Where |
|---|---|
| Product requirements | [`docs/prd/PAO-PRD.pdf`](docs/prd/PAO-PRD.pdf) (text copy: `PAO-PRD.txt`) |
| UI designs | [Figma](https://www.figma.com/design/ytbbSEIF1I6cZN0iWJVQsC) |
| Agent rules | [`CLAUDE.md`](CLAUDE.md) |
| Build instructions | [`docs/build/00-START-HERE.md`](docs/build/00-START-HERE.md) |
| Build progress | [`docs/build/PROGRESS.md`](docs/build/PROGRESS.md) |

## Starting the build

Open a Claude Code session on this repository and send:

> Build PAO. Follow `CLAUDE.md` and `docs/build/00-START-HERE.md`. Work through every phase
> in order without stopping: for each phase create the branch, complete every task with
> tests, keep `./pao ci` green, update `docs/build/PROGRESS.md`, push, open the PR, fix CI
> until it is green, merge, and continue with the next phase.

Then schedule the resume prompt from `00-START-HERE.md` §5 so the build continues by
itself after usage limits reset.
