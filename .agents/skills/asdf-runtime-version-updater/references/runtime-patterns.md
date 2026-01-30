# Runtime Patterns Reference

Detailed version patterns for common runtimes and file types.

## Node.js

| File | Pattern | Example |
|------|---------|---------|
| `.tool-versions` | `nodejs X.Y.Z` | `nodejs 22.13.1` |
| `.nvmrc` | `X.Y.Z` or `vX.Y.Z` | `22.13.1` |
| `.node-version` | `X.Y.Z` | `22.13.1` |
| `package.json` | `"node": ">=X.Y.Z"` | `"node": ">=22.0.0"` |
| `package.json` | `"@types/node": "^X"` | `"@types/node": "^24"` |
| Dockerfile | `FROM node:X.Y.Z-alpine` | `FROM node:22.13.1-alpine` |
| GitHub Actions | `node-version: 'X.Y.Z'` | `node-version: '22.13.1'` |
| GitHub Actions | `image: node:X.Y.Z-alpine` | `image: node:22.13.1-alpine` |

**Version formats**:
- Full: `22.13.1`
- Major.Minor: `22.13`
- Major only: `22`

## Python

| File | Pattern | Example |
|------|---------|---------|
| `.tool-versions` | `python X.Y.Z` | `python 3.13.2` |
| `.python-version` | `X.Y.Z` | `3.13.2` |
| `pyproject.toml` | `requires-python = ">=X.Y"` | `requires-python = ">=3.13"` |
| Dockerfile | `FROM python:X.Y.Z-slim` | `FROM python:3.13.2-slim` |
| GitHub Actions | `python-version: 'X.Y.Z'` | `python-version: '3.13.2'` |
| GitHub Actions | `image: python:X.Y.Z-slim` | `image: python:3.13.2-slim` |

## Ruby

| File | Pattern | Example |
|------|---------|---------|
| `.tool-versions` | `ruby X.Y.Z` | `ruby 3.4.2` |
| `.ruby-version` | `X.Y.Z` | `3.4.2` |
| `Gemfile` | `ruby 'X.Y.Z'` | `ruby '3.4.2'` |
| Dockerfile | `FROM ruby:X.Y.Z-alpine` | `FROM ruby:3.4.2-alpine` |
| GitHub Actions | `ruby-version: 'X.Y.Z'` | `ruby-version: '3.4.2'` |
| GitHub Actions | `image: ruby:X.Y.Z-alpine` | `image: ruby:3.4.2-alpine` |

## Elixir / Erlang

| File | Pattern | Example |
|------|---------|---------|
| `.tool-versions` | `elixir X.Y.Z-otp-N` | `elixir 1.19.5-otp-28` |
| `.tool-versions` | `erlang X.Y.Z` | `erlang 28.0.1` |
| Dockerfile | `FROM elixir:X.Y.Z-otp-N` | `FROM elixir:1.19.5-otp-28` |
| Dockerfile | `FROM hexpm/elixir:A.B.C-erlang-X.Y.Z-BASE-N` | `FROM hexpm/elixir:1.19.5-erlang-28.3.1-alpine-3.23.3` |
| GitHub Actions | `elixir-version: 'X.Y.Z'` | `elixir-version: '1.19.5'` |
| GitHub Actions | `otp-version: 'X.Y'` | `otp-version: '28.0'` |
| GitHub Actions | `image: elixir:X.Y.Z-otp-N` | `image: elixir:1.19.5-otp-28` |
| GitHub Actions | `image: hexpm/elixir:A.B.C-erlang-X.Y.Z-BASE-N` | `image: hexpm/elixir:1.19.5-erlang-28.3.1-alpine-3.23.3` |

**Elixir version notes**:
- Elixir versions often include OTP suffix: `1.19.5-otp-28`
- OTP version should match Erlang major version
- Use `erlef/setup-beam@v1` for GitHub Actions

## Go

| File | Pattern | Example |
|------|---------|---------|
| `.tool-versions` | `golang X.Y.Z` | `golang 1.23.5` |
| `go.mod` | `go X.Y` | `go 1.23` |
| Dockerfile | `FROM golang:X.Y.Z-alpine` | `FROM golang:1.23.5-alpine` |
| GitHub Actions | `go-version: 'X.Y.Z'` | `go-version: '1.23.5'` |
| GitHub Actions | `image: golang:X.Y.Z-alpine` | `image: golang:1.23.5-alpine` |

## Rust

| File | Pattern | Example |
|------|---------|---------|
| `.tool-versions` | `rust X.Y.Z` | `rust 1.84.1` |
| `rust-toolchain.toml` | `channel = "X.Y.Z"` | `channel = "1.84.1"` |
| GitHub Actions | `toolchain: X.Y.Z` | `toolchain: 1.84.1` |

## Search Commands

```bash
# Find all version references for a specific version
grep -rn "22.13.1" --include="*.yml" --include="*.yaml" --include="Dockerfile*" .

# Find Node.js version patterns
grep -rE "node[_:-]?(version)?['\"]?:?\s*['\"]?[0-9]+" .

# Find Python version patterns  
grep -rE "python[_:-]?(version)?['\"]?:?\s*['\"]?3\.[0-9]+" .

# Find FROM statements in Dockerfiles
grep -rE "^FROM\s+" --include="Dockerfile*" .
```

## Common Pitfalls

1. **Partial version matches** - `3.13` might match `3.13.0`, `3.13.1`, etc. Be specific.
2. **OTP version coupling** - Elixir versions require compatible OTP/Erlang versions
3. **Docker tag variants** - Tags like `-alpine`, `-slim`, `-bookworm` should be preserved
4. **GitHub Actions version files** - Some actions support `*-version-file` to read from `.tool-versions`
