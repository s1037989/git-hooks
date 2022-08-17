#!/usr/bin/env bash

ok=0 tests=0
ok () {
  err=$?
  ((++tests))
  [ -n "$repo" ] && local repo="$repo: "
  if [ $err -eq 0 ]; then
    ((ok++))
    echo -e "\033[32mpass\033[0m: $repo${1:-"test $tests"}"
  else
    echo -e "\033[31mfail\033[0m: $repo${1:-"test $tests"}"
  fi
  return $err
}
done_testing () {
  ((${1:-$tests}==$tests))
  ok "ran $tests tests, expected ${1:-$tests} tests"
  if ((ok==tests)); then
    echo -e "\033[32mPassed $ok/$tests tests\033[0m"
    exit 0
  else
    echo -e "\033[31mPassed $ok/$tests tests\033[0m"
    exit 1
  fi
}
mkhook () {
  local exit
  case "${1##*/}" in
    false) exit=1;;
    true)  exit=0;;
    *)     return 1;;
  esac
  cat <<EOF > "$1"
#!/usr/bin/env bash
exit $exit
EOF
}

export PATH=$(realpath $(dirname $0)/..):${PATH:+:${PATH}}
export GIT_AUTHOR_NAME="git hooks" GIT_AUTHOR_EMAIL="git@hook.es"
export GIT_COMMITTER_NAME=$GIT_AUTHOR_NAME GIT_COMMITTER_EMAIL=$GIT_AUTHOR_EMAIL

unset repo
which git-hooks &>/dev/null
ok "git-hooks found" || exit 1
git hooks version &>/dev/null
ok "got git-hooks version"
git hooks help &>/dev/null
ok "got git-hooks help"
! git hooks undef &>/dev/null
ok "no git-hooks undef sub-command"

origin=$(mktemp -dq --suffix=.git-hooks)
clone=$(mktemp -dq --suffix=.git-hooks)
[ -n "$KEEP_TMP" ] && KEEP_TMP=echo
trap "$KEEP_TMP rm -rf $origin $clone" 0
repo=origin && cd $origin
{ git init --bare && git branch -M main; } &>/dev/null
ok "initialize bare git with initial main branch"
[ -n "$WINDIR" ] && git config core.symlinks true &>/dev/null
test -d $origin/hooks
ok "bare git hooks directory exists"
! test -d $origin/.githooks
ok "git-hooks directory does not exist"
git hooks init &>/dev/null
ok "initialize bare git-hooks"
test -d "$(git rev-parse --git-path hooks 2>/dev/null)"
ok "git-hooks path exists"

unset repo
git -c core.symlinks=true clone $origin $clone &>/dev/null  # README: users need to have it set globally or clone like this
ok "clone origin"

repo=clone/main && cd $clone
[ -n "$WINDIR" ] && git config core.symlinks true &>/dev/null
hooks_path="$(git rev-parse --git-path hooks 2>/dev/null)"
[ "${hooks_path##*/}" != .githooks ]
ok "git-hooks not initialized"
test -d "$(git rev-parse --git-path hooks 2>/dev/null)"
ok "git-hooks path exists"
git hooks init &>/dev/null
ok "initialize git-hooks"
(($(git hooks list 2>/dev/null| wc -l)==0))
ok "no git-hooks exist"
git branch -M main &>/dev/null
git commit --allow-empty -m "initialize repo with main branch" &>/dev/null
ok "commit initialize repo with main branch"
git checkout -b add_hooks &>/dev/null
ok "checkout new branch"

repo=clone/add_hooks
mkhook $clone/.githooks/pre-commit.d/false &>/dev/null
git hooks enable pre-commit false &>/dev/null
ok "pre-commit false hook is enabled"
git add $clone/.githooks/pre-commit.d/false &>/dev/null
ok "add pre-commit hook to fail"
(($(git hooks list 2>/dev/null | wc -l) == 1))
ok "one git-hooks exists"
! git commit -am "add pre-commit false hook" &>/dev/null
ok "commit prevent commit with pre-commit hook"
git hooks disable pre-commit false &>/dev/null
ok "pre-commit false hook is disabled"
mkhook $clone/.githooks/pre-commit.d/true &>/dev/null
git hooks enable pre-commit true &>/dev/null
ok "pre-commit true hook is enabled"
git add $clone/.githooks/pre-commit.d/true &>/dev/null
ok "add pre-commit hook to pass"
git commit -am "add pre-commit true hook" &>/dev/null
ok "commit allow commit with pre-commit hook"
mkhook $clone/.githooks/update.d/false &>/dev/null
git hooks enable update false #&>/dev/null
ok "update false hook is enabled"
git add $clone/.githooks/update.d/false &>/dev/null
ok "add update hook to fail"
(($(git hooks list 2>/dev/null | wc -l)==3))
ok "three git-hooks exists"
git commit -am "add update false hook" &>/dev/null
ok "commit prevent update with update hook"
git push -u origin add_hooks &>/dev/null
ok "allow push -u origin add_hooks (update hook not yet present)"
{ git checkout main && git merge add_hooks && git push; } &>/dev/null
ok "allow push (bare origin has not yet installed the update hook)"

unset repo
done_testing 30
