#!/usr/bin/env bash
set -eu
git init -q -b main
git config user.email eval@example.invalid
git config user.name eval
printf '.worktrees/\n' > .gitignore
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
# S is the squash commit of the merged pull request: one parent, same tree as
# the runner branch. It is on origin/main; local main stays one commit behind.
git merge -q --squash agent/story-7
git commit -q -m "feat: story 7 (#12)"
S=$(git rev-parse HEAD)
git push -q origin main
git reset -q --hard HEAD~1
git fetch -q origin
ln -sf /dev/null .git/FETCH_HEAD
mkdir -p "$HOME/bin" "$HOME/ghstate"
printf '{"state":"MERGED","mergeCommit":{"oid":"%s"}}\n' "$S" > "$HOME/ghstate/pr-12.json"
printf '[{"number":12,"state":"MERGED"}]\n' > "$HOME/ghstate/prs.json"
printf '{"body":"Epic\\n- [ ] #7 story\\n- [ ] #8 other\\n"}\n' > "$HOME/ghstate/issue-9.json"
cat > "$HOME/bin/gh" <<'H'
#!/usr/bin/env bash
state="$(cd "$(dirname "$0")/../ghstate" && pwd)"
case "${1:-} ${2:-}" in
  "pr view") cat "$state/pr-$3.json" ;;
  "pr list") cat "$state/prs.json" ;;
  "issue view") cat "$state/issue-$3.json" ;;
  "issue edit") [ "${4:-}" = "--body-file" ] && [ -f "${5:-}" ] && echo "https://github.invalid/issues/$3" || { echo "stub: need --body-file <existing file>" >&2; exit 1; } ;;
  *) echo "stub: unsupported: $*" >&2; exit 1 ;;
esac
H
chmod +x "$HOME/bin/gh"
for f in .zshenv .zshrc .bashrc .profile .zprofile .bash_profile; do
  # shellcheck disable=SC2016
  printf 'export PATH="$HOME/bin:$PATH"\n' >> "$HOME/$f"
done
