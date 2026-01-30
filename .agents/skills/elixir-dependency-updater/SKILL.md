---
name: elixir-dependency-updater
description: Update Elixir project dependencies including breaking changes. Use when the user asks to update dependencies in an Elixir project, upgrade packages, run mix hex.outdated, handle dependency version bumps and breaking changes, or asks to update mix.exs dependencies.
---

# Update Elixir Dependencies

Update all Elixir dependencies in a project, including handling breaking changes.

## Workflow Overview

1. Identify outdated dependencies
2. Update each dependency (one at a time)
3. Verify all updates
4. Handle blocked dependencies
5. Generate summary report

## 1. Identify Outdated Dependencies

Run `mix hex.outdated` in the project root. Parse the output to identify dependencies where `Latest` is newer than `Current`.

## 2. Update Each Dependency

For each outdated dependency:

1. Update the version constraint in `mix.exs` to the `Latest` version
2. Run `mix deps.get` to update the lock file
3. Run `mix hex.package diff {dependency_name} {current_version}..{latest_version}` to view changes
4. Analyze the diff for breaking changes (see below)
5. Make any necessary code changes in the project

### Analyzing Diffs for Breaking Changes

Look for these patterns in the diff output:

**API Changes:**
- Renamed functions: `-def old_name` / `+def new_name`
- Changed function signatures: different arities, new required parameters
- Removed public functions (functions no longer in public API)
- Changed return types or data structures

**Configuration Changes:**
- New required config keys
- Renamed or removed config options
- Changed default values

**Behavior Changes:**
- Modified error handling (different exception types)
- Changed validation rules
- Modified callbacks or hooks

## 3. Verification

After updating all dependencies:

1. `mix compile --warnings-as-errors` - Fix any compilation warnings
2. `mix format --check-formatted` - Fix formatting with `mix format` if needed
3. `mix test` - Fix any test failures
4. `mix hex.outdated` - Confirm dependencies are updated

If any step fails, fix the issues before proceeding.

## 4. Handle Blocked Dependencies

For dependencies showing `Update not possible`:

1. Run `mix hex.outdated {dependency_name}` to see why it's blocked
2. **If blocked only by version constraint in `mix.exs`**: Update following the steps above
3. **If blocked by transitive dependency requirements**: Report the blocker—do not force update

When reporting blocked dependencies, include:
- The dependency name
- The latest available version
- Which transitive dependency is blocking the update
- The version constraint causing the conflict

## 5. Summary Report

Generate a summary using this format:

```markdown
## Dependencies Updated

| Package | Previous | Updated | Breaking Changes |
|---------|----------|---------|------------------|
| {name}  | {old}    | {new}   | Yes/No           |

## Code Changes Made

- {description of changes in project files}

## Blocked Dependencies

| Package | Blocked By | Reason |
|---------|------------|--------|
| {name}  | {blocker}  | {why}  |

## Verification Results

- Compilation: ✓/✗
- Formatting: ✓/✗  
- Tests: ✓/✗ ({passed}/{total})
```

## Troubleshooting

**`mix hex.package diff` fails:**
- Package may not be published to Hex—skip diff and review changelog/release notes manually

**Compilation fails after update:**
- Check the diff for API changes
- Review the package changelog for migration guides
- Consider updating one dependency at a time to isolate issues

**Tests fail with unclear errors:**
- Run `mix test --trace` for more detail
- Check if test helpers or fixtures need updates
- Review package changelog for test-related changes
