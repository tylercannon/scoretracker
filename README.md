# ScoreTracker

A real-time score tracking application built with [Phoenix](https://www.phoenixframework.org/) and [LiveView](https://hexdocs.pm/phoenix_live_view/). Keep track of scores for your favorite games with live updates across all connected devices.

## Features

- **Real-time Updates** — Score changes sync instantly across all connected players and spectators using Phoenix LiveView
- **Multiple Game Modes**
  - **Party Mode** — Players manage their own scores
  - **Scorekeeper Mode** — Game host manages every player's score
- **Built-in Game Types**
  - **Ripple** — Family card game with round-specific scoring info
  - **Rummy** — Family card game with round-specific scoring info
  - **Custom** — Create your own game with configurable rounds, players, and scoring rules
- **Spectator Support** — Allow others to track game scores without participating
- **Mobile-Friendly** — Responsive design works on any device

## Requirements

[asdf](https://asdf-vm.com/) is recommended for automatic version management of language versions for:

- [Erlang](https://www.erlang.org/)
- [Elixir](https://elixir-lang.org/)

## Getting Started

### 1. Clone the repository

```bash
git clone https://github.com/tylercannon/scoretracker.git
cd scoretracker
```

### 2. Install language versions

```bash
asdf install
```

### 3. Start Docker services

```bash
docker compose up -d
```

### 4. Set up the project

```bash
mix setup
```

This will:
- Copy `.env.example` to `.env`
- Install dependencies
- Set up frontend assets (Tailwind CSS, esbuild)

### 5. Start the server

```bash
iex -S mix phx.server
```

Open [`localhost:4000`](http://localhost:4000) in your browser
