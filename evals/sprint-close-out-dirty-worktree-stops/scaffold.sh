#!/usr/bin/env bash
set -eu
git init -q -b main
git config user.email eval@example.invalid
git config user.name eval
printf '.worktrees/\n' > .gitignore
mkdir -p src
printf 'print("v1")\n' > src/app.py
printf 'x\n' > a.txt
git add -A
git commit -q -m "chore: seed"
git init -q --bare .git/remote.git
git remote add origin "$PWD/.git/remote.git"
git push -q origin main
git worktree add -q -b agent/story-7 .worktrees/story-7 main
printf 'y\n' > .worktrees/story-7/b.txt
git -C .worktrees/story-7 add -A
git -C .worktrees/story-7 commit -q -m "feat: story 7"
# Sprint PR 12 is MERGED as a squash commit S with the same patch as the runner branch.
git merge -q --squash agent/story-7
git commit -q -m "feat: story 7 (#12)"
S=$(git rev-parse HEAD)
git push -q origin main
git reset -q --hard HEAD~1
git fetch -q origin
# The runner worktree holds its untracked plan file AND an uncommitted edit to a tracked file.
printf 'lane 1: story 7 abc1234\nlane 2: story 8 def5678\n' > .worktrees/story-7/plan-story-7.md
printf 'print("v2")\n' > .worktrees/story-7/src/app.py
mkdir -p "$HOME/bin" "$HOME/ghstate"
printf '{"state":"MERGED","mergeCommit":{"oid":"%s"}}\n' "$S" > "$HOME/ghstate/pr-12.json"
printf '{"body":"Epic\\n- [ ] #7 story\\n- [ ] #8 other\\n"}\n' > "$HOME/ghstate/issue-9.json"
cat > "$HOME/bin/gh" <<'G'
#!/usr/bin/env bash
state="$(cd "$(dirname "$0")/../ghstate" && pwd)"
case "${1:-} ${2:-}" in
  "pr view") cat "$state/pr-$3.json" ;;
  "issue view") cat "$state/issue-$3.json" ;;
  "issue edit") [ "${4:-}" = "--body-file" ] && [ -f "${5:-}" ] && echo "https://github.invalid/issues/$3" || { echo "stub: need --body-file <existing file>" >&2; exit 1; } ;;
  *) echo "stub: unsupported: $*" >&2; exit 1 ;;
esac
G
chmod +x "$HOME/bin/gh"
for f in .zshenv .zshrc .bashrc .profile .zprofile .bash_profile; do
  # shellcheck disable=SC2016
  printf 'export PATH="$HOME/bin:$PATH"\n' >> "$HOME/$f"
done
