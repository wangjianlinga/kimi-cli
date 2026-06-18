# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Quick commands

All commands use `uv`. After cloning, run `make prepare` first (syncs deps + installs prek git hooks).

| Task | Command |
|------|---------|
| Sync all deps + git hooks | `make prepare` |
| Format all packages | `make format` |
| Lint + type check all | `make check` |
| Run all tests | `make test` |
| Run only kimi-cli tests | `uv run pytest tests -vv` |
| Run a single test | `uv run pytest tests/path/test_file.py::test_name -vv` |
| Run e2e tests | `uv run pytest tests_e2e -vv` |
| Run AI test suite | `make ai-test` |
| Run a single package's tests | `uv run --project packages/kosong pytest --doctest-modules -vv` |
| Build sdist + wheel | `make build` |
| Build standalone binary | `make build-bin` |
| Start web backend (dev) | `make web-back` |
| Start web frontend (dev) | `make web-front` |

## Monorepo structure

This is a Python monorepo managed by `uv` workspaces:

```
kimi-cli/                  # Root — the main CLI agent package
packages/
  kosong/                  # LLM abstraction layer (providers: Anthropic, OpenAI, Google)
  kaos/                    # OS abstraction layer (local + SSH backends)
  kimi-code/               # Lightweight package that depends on kimi-cli
sdks/
  kimi-sdk/                # Python SDK for building custom agents
web/                       # React web UI (TypeScript, Vite, shadcn/ui)
vis/                       # Tracing visualizer UI (TypeScript, Vite)
docs/                      # User documentation (VitePress)
examples/                  # Example agents, custom tools, custom souls
tests/                     # Unit + integration tests
tests_e2e/                 # End-to-end tests
tests_ai/                  # AI-driven tests
klips/                     # Kimi Code CLI Improvement Proposals (design docs)
```

## Workspace packages

The root `pyproject.toml` defines workspace members in `[tool.uv.workspace]`. Root package `kimi-cli` depends on workspace packages `kosong` and `pykaos`. When running checks or builds for a specific sub-package, use `--project` and `--directory` flags:

```sh
uv run --project packages/kosong --directory packages/kosong ruff check
uv build --package kosong --no-sources --out-dir dist/kosong
```

## Architecture

See `AGENTS.md` for detailed architecture documentation (loaded into agent prompts at runtime via `KIMI_AGENTS_MD`). The key flow:

1. **CLI entry**: `src/kimi_cli/__main__.py` → `src/kimi_cli/cli/__init__.py` (Typer) parses flags and routes to `KimiCLI` in `app.py`.
2. **App setup**: `KimiCLI.create()` loads config, chooses a model/provider, builds a `Runtime`, loads an agent spec, constructs `KimiSoul`.
3. **Core loop**: `KimiSoul.run()` in `soul/kimisoul.py` — accepts user input, handles slash commands, calls LLM via kosong, runs tools, compacts context.
4. **UI decoupling**: `soul/run_soul` connects `KimiSoul` to a `Wire`, so UI loops (shell TUI, print, ACP) consume streaming events independently.

## Key module map

| Module | Purpose |
|--------|---------|
| `src/kimi_cli/app.py` | `KimiCLI.create()` and `.run()` — main programmatic entrypoint |
| `src/kimi_cli/config.py` | Config loading (`~/.kimi/config.toml`) |
| `src/kimi_cli/llm.py` | Model/provider selection |
| `src/kimi_cli/soul/agent.py` | `Runtime`, `Agent`, `LaborMarket` (subagent registry) |
| `src/kimi_cli/soul/kimisoul.py` | `KimiSoul.run()` — main agent loop |
| `src/kimi_cli/soul/context.py` | Conversation history + checkpointing |
| `src/kimi_cli/soul/compaction.py` | Context compaction when approaching token limits |
| `src/kimi_cli/soul/toolset.py` | Tool loading, dependency injection, tool execution |
| `src/kimi_cli/soul/approval.py` | Tool-facing approval facade |
| `src/kimi_cli/approval_runtime/` | Session-level pending approvals state |
| `src/kimi_cli/tools/` | Built-in tools: agent, shell, file, web, todo, background, dmail, think, plan, ask_user |
| `src/kimi_cli/agents/` | YAML agent specs + system prompts |
| `src/kimi_cli/agentspec.py` | Agent spec loading (supports `extend`, tool imports, subagents) |
| `src/kimi_cli/wire/` | Event types and transport between soul and UI |
| `src/kimi_cli/ui/shell/` | Interactive TUI (prompt_toolkit), shell command mode, autocomplete |
| `src/kimi_cli/ui/print/` | Headless/script output mode |
| `src/kimi_cli/ui/acp/` | Agent Client Protocol server for IDE integration |
| `src/kimi_cli/skill/` | Skill discovery and loading (`SKILL.md` files) |
| `src/kimi_cli/skill/flow/` | Agent Flow parser (Mermaid/D2 flowchart → executable flow) |
| `src/kimi_cli/acp/` | ACP protocol implementation |
| `src/kimi_cli/web/` | Web UI backend (FastAPI + Scalar docs) |
| `src/kimi_cli/vis/` | Tracing visualizer backend |
| `src/kimi_cli/hooks/` | Hook engine for lifecycle events |
| `src/kimi_cli/plugin/` | Plugin system |
| `src/kimi_cli/background/` | Background task runner (async agents) |
| `src/kimi_cli/session.py` | Session management (create, restore, fork) |
| `src/kimi_cli/subagents/` | Subagent instance persistence |

## Quality gates

- **Python**: 3.12+ (pyright/ty target 3.14)
- **Lint/format**: Ruff (line length 100, rules: E, F, UP, B, SIM, I)
- **Type checking**: pyright (`standard` mode, `strict` for `src/kimi_cli/`), ty (`uv run ty check`)
- **Tests**: pytest + pytest-asyncio (asyncio_mode = auto), inline-snapshot for snapshot testing
- **Git hooks**: prek runs `make format-kimi-cli` + `make check-kimi-cli` on commit
- **CI**: PR title checker, typos checker, release workflows per package

Run the full quality suite before pushing:
```sh
make format && make check && make test
```

## Conventional commits

Format: `<type>(<scope>): <subject>`

Types: `feat`, `fix`, `test`, `refactor`, `chore`, `style`, `docs`, `perf`, `build`, `ci`, `revert`.

## Versioning (minor-bump-only)

Patch is always `0`. Only bump minor for any change. Major only by explicit manual decision.

Examples: `1.46.0` → `1.47.0`. This applies to all packages (`packages/*`, `sdks/*`).

## Release process

See `.agents/skills/release/SKILL.md` for full procedure. Summary:
1. Create a release branch (e.g. `bump-1.48`)
2. Update `CHANGELOG.md` (add dated section below `## Unreleased`)
3. Update version in `pyproject.toml`
4. Run `uv sync` to align `uv.lock`
5. Open PR, merge, then tag + push: `git tag 1.48 && git push --tags`
6. GitHub Actions handles the release

## Nix environment

A `flake.nix` is available for Nix-based development. See `flake.nix` for the shell definition.
