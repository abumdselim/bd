# bd

A Next.js 16 application with Bangla-primary bilingual support.

## Architecture Decision Records

All project decisions are documented as ADRs in `docs/adr/`. Every phase from 1b onward references these files by path.

| ADR | Title | Status |
|-----|-------|--------|
| [0001](docs/adr/0001-project-constitution.md) | Project Constitution | Accepted |
| [0002](docs/adr/0002-stack-decision.md) | Stack Decision | Accepted |
| [0003](docs/adr/0003-security-threat-model.md) | Security Threat Model | Accepted |
| [template](docs/adr/template.md) | ADR Template | Proposed |

## Local Development Setup

> **Placeholder** — full setup instructions will be added in Phase 1d after the Next.js scaffold is created.

### Prerequisites

- Node.js 20+
- Bun (package manager)
- Git

### Quick Start (Phase 1d and later)

```bash
git clone https://github.com/abumdselim/bd.git
cd bd
bun install
bun run dev
```

### ADR Workflow

1. Copy `docs/adr/template.md` to `docs/adr/NNNN-descriptive-name.md`
2. Set `id`, `title`, `status`, `date`, `supersedes` in frontmatter
3. Replace placeholder sections with actual content
4. Submit as part of the phase PR

## Project Structure

```
bd/
├── .editorconfig          # Editor settings (UTF-8, LF, indent)
├── README.md              # This file
└── docs/
    └── adr/
        ├── template.md               # ADR template
        ├── 0001-project-constitution.md  # Design tokens, performance budget
        ├── 0002-stack-decision.md        # Technology choices
        └── 0003-security-threat-model.md # T1–T10 threat tracking
```

## License

TBD
