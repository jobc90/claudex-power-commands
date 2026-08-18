# Claude Code Reverse Engineering — Architecture Visualization

> Anthropic Claude Code CLI의 소스맵 분석을 통해 추출한 구현 수준의 리버스 엔지니어링 설계 문서. 8파트, 19,380줄, 8회 검증 완료.

## 주요 수치

| 항목 | 수치 |
|------|------|
| Source Files | ~1,900 |
| Lines of Code | 512K+ |
| Design Docs | 8 |
| Doc Lines | 19,380 |

---

## System Overview — Architecture Layers

**Claude Code CLI — TypeScript Strict · Bun · ESM-only**

### Terminal UI

- React 19 component tree
- Ink (custom fork) 96 files
- Yoga WASM flexbox layout
- Commander.js CLI parser
- 346 .tsx components
- 85+ custom hooks

### Core Engine

- 45+ Tools — `buildTool()` factory
- Query Engine — streaming executor
- Concurrency — safe/unsafe flags
- Recovery — 8-stage chain
- Cost Tracker — per-session USD

### Extensions

- MCP — 8 config types
- Plugins — marketplace + builtin
- Skills — 17 bundled + custom
- Hooks — 27 events
- LSP — code intelligence
- Bridge — IDE comms

### Services

- API Client — 4 backends
- Auth/OAuth — PKCE + Keychain
- Analytics — DD + OTel
- Settings — 5-layer merge
- Migrations — 11 sync + 1 async

### Security

- 7 Permission Modes — default to bubble
- 23 Bash Checks — cross-platform
- Path Validator — 6-step pipeline
- Auto-Mode — YOLO classifier

---

## Boot Sequence — Startup Pipeline

| Phase | 이름 | 설명 |
|-------|------|------|
| Phase 0 | Side Effects | MDM, Keychain prefetch |
| Phase 1 | main() entry | Basic initialization |
| Phase 2 | preAction | init() → migrations |
| Phase 3 | action() | setup → auth/perms |
| Phase 4 | REPL render | Deferred prefetches |

---

## Core Engine — Tool Execution Flow

```
IN: User Input
  prompt → QueryEngine
        ↓
AI: LLM API (streaming)
  Anthropic / Bedrock / Vertex / Foundry
        ↓ tool_use block
FN: Tool Execution
  Bash, FileEdit, Agent, MCP … 45+
        ↓
R: ToolResult
  data, newMessages, contextModifier, mcpMeta
        ↺ next LLM turn
```

---

## Documentation — 8 Design Documents

### 01 - Architecture Overview

- 5-phase startup, ESM-only module system, Bun bundler, 7-layer config, 89 feature flags, 110 global state fields
- **1,101 lines**
- Topics: startup, config, feature-flags

### 02 - Core Engine

- 60+ field tool interface, `buildTool()` factory, concurrency safety flags, 8-stage recovery chain, per-session cost tracking
- **1,352 lines**
- Topics: tools, streaming, recovery

### 03 - Permission & Security

- 7 permission modes, 4-step decision pipeline, 23 bash check IDs, 6-step path validation, YOLO auto-classifier
- **1,178 lines**
- Topics: permissions, bash-security, TOCTOU

### 04 - Multi-Agent & Memory

- 3 swarm backends (fork/spawn/in-proc), 7 task types, file-based mailbox, 5-layer memory hierarchy, ETag-based sync
- **1,416 lines**
- Topics: agents, memory, teams

### 05 - Extension Systems

- 6 extension points, MCP 8 transport types, 27 hook events, plugin marketplace, parallel loading, reconnection strategy
- **1,709 lines**
- Topics: MCP, plugins, hooks

### 06 - UI Layer

- Custom React reconciler (React 19), Ink fork (96 files), Yoga WASM layout, ANSI diff rendering, 346 .tsx components
- **1,784 lines**
- Topics: React, Ink, Yoga

### 07 - Services & Infrastructure

- 4 API backends, OAuth PKCE with Keychain, Datadog + OTel analytics, 5-source settings merge, 11+1 migrations
- **1,845 lines**
- Topics: API, OAuth, analytics

### 08 - Types, Schemas & API

- Branded IDs, Zod schemas, ~100 field SettingsJson, DeepImmutable AppState, 60+ env vars, 89 feature flags, 44 DD events
- **2,194 lines**
- Topics: TypeScript, Zod, schemas

---

## Security — Permission Decision Pipeline

```
0: Config deny rules
   → immediate deny
        ↓
1: Tool.checkPermissions()
   → allow / deny / ask / passthrough
        ↓
2: Permanent allow rules
   → skip prompt
        ↓
3: passthrough → ask conversion
        ↓
4: Post-processing
   → dontAsk · auto (YOLO) · headless
```

---

## Multi-Agent — Agent & Memory Hierarchy

### Agent Swarm Backends

- **Coordinator** (orchestrator)
- **fork** — shared context
- **spawn** — independent
- **in-process** — teammate

### Memory Hierarchy (5 layers)

| Layer | 이름 | 설명 |
|-------|------|------|
| 1 | Session Memory | in-context summaries |
| 2 | Project Memory | `.claude/memory/` |
| 3 | User Memory | `~/.claude/memory/` |
| 4 | Team Memory | server-synced shared |
| 5 | External | MCP, LSP, git |

---

## Infrastructure — Deployment Options

### Platform별 비용

| Platform | 구성 | 월 비용 |
|----------|------|---------|
| Local Dev | Ollama/vLLM, Docker Stack, RTX 4090 | $0–50 |
| AWS | ECS Fargate, Bedrock, Lambda, Cognito | $45–180 |
| Azure | Container Apps, Azure OpenAI, AD B2C | $50–190 |
| Supabase | Edge Functions, Realtime, PostgreSQL, Auth | $0–25 |

### Scale별 비용 (월)

| Scale | Supabase + API | AWS Full | Hybrid (Local GPU) |
|-------|---------------|----------|-------------------|
| Solo (1 dev) | $9–103 | $240–280 | $50 |
| Team (10 devs) | $46–116/dev | $65–110/dev | $35–60/dev |
| Enterprise (100 devs) | N/A | $45–111/dev | $25/dev |

> **Note:** LLM token costs represent 60–95% of total spend at every scale.

---

## Quality — 8 Verification Passes

| Pass | 내용 | 수정 건수 |
|------|------|----------|
| Pass 1 | Type/value accuracy | 16 corrections |
| Pass 2 | Blocking implementation gaps | 4 fixes |
| Pass 3 | Line-by-line precision | 7 corrections |
| Pass 4 | Missing schemas/flows | 3 fixes |
| Pass 5 | Bridge, MDM, Keychain, Plugin additions | 7 additions |
| Pass 6 | Structural problem warnings | 42 caveats |
| Pass 7 | Convergence check | 2 micro-fixes |
| Pass 8 | CONVERGED — 24/24 spot-checks verified | 0 |

**Total:** 39 corrections + 42 implementation caveats

---

## Repository — File Structure

```
claude-code-reverse-engineering/
├── README.md
├── docs/
│   ├── 01-architecture-overview.md      (1,101 lines)
│   ├── 02-core-engine.md                (1,352 lines)
│   ├── 03-permission-security.md        (1,178 lines)
│   ├── 04-multi-agent-memory.md         (1,416 lines)
│   ├── 05-extension-systems.md          (1,709 lines)
│   ├── 06-ui-layer.md                   (1,784 lines)
│   ├── 07-services-infrastructure.md    (1,845 lines)
│   └── 08-types-schemas-api.md          (2,194 lines)
├── infrastructure/
│   ├── 01-local-development.md
│   ├── 02-aws-architecture.md
│   ├── 03-azure-architecture.md
│   ├── 04-supabase-backend.md
│   ├── 05-cost-analysis.md
│   └── 06-architecture-diagram.md
└── terraform/
    └── (10 .tf files — production-ready IaC)
```

---

## Disclaimer

교육 및 보안 연구 목적의 리버스 엔지니어링입니다. 원본 Claude Code 소프트웨어의 모든 권리는 [Anthropic](https://www.anthropic.com/)에 귀속됩니다. 문서에 대해서만 MIT 라이선스가 적용됩니다.

---

**Author:** Hugh Kim · Built with Claude Code

**Repository:** [github.com/jung-wan-kim/claude-code-reverse-engineering](https://github.com/jung-wan-kim/claude-code-reverse-engineering)
