---
name: resolve-obsidian
description: Resolve git merge conflicts in an Obsidian vault that's synced via git (e.g. across multiple devices, or with iCloud/Drive on top). Defaults to keeping the most recent block in daily notes.
---

# Resolve Obsidian Git Conflicts

Resolve git merge conflicts in an Obsidian vault that's synced across devices via git.

## Prerequisites

- Obsidian vault is a git repo (e.g. via the [obsidian-git plugin](https://github.com/Vinzent03/obsidian-git))
- The vault path is known — set it in your CLAUDE.md, or ask the user once and remember per project
- Default vault path on Windows lives somewhere like `<DriveLetter>:\<sync-folder>\<vault-name>` (Google Drive, OneDrive, iCloud, Syncthing)

## Steps

1. `cd` into the vault path (project-specific — pick it up from CLAUDE.md or ask)
2. Run `git status` to identify conflicted files
3. For each conflicted file:
   - Read the file and identify conflict markers (`<<<<<<<`, `=======`, `>>>>>>>`)
   - **Daily notes** (e.g. `daily notes/YYYY-MM-DD.md`): keep the **most recent** content block (usually the incoming/remote changes — the device that wrote later)
   - **Project / non-daily files**: show both versions and ask the user which to keep — these often have intentional local edits
4. Stage resolved files: `git add <files>`
5. Commit with a clear message: `git commit -m "resolve: daily note merge conflicts"`
6. Push: `git push`
7. Confirm with `git status` (should be clean)

## Heuristics

- **Daily notes**: timestamp-based conflicts → most recent wins
- **MOC / index files**: usually want the union — concatenate both sides and dedupe entries
- **Templates**: never auto-resolve, always ask

## If a rebase is needed

`git pull --rebase` first, then walk through each conflicted commit. Same heuristic per file type.

## Edge case: too many conflicts

If `git status` shows >20 conflicted files, stop and ask the user. It's usually a sign that two devices wrote independently for hours — the user may want to abort the merge and reconcile manually instead of resolving file-by-file.
