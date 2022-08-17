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

origin=$(mktemp -d)
clone=$(mktemp -d)
trap "rm -rf $origin $clone" 0
repo=origin/master && cd $origin
git -c core.symlinks=true init &>/dev/null
ok "initialize git"
test -d $origin/.git/hooks
ok "git hooks directory exists"
! test -d $origin/.githooks
ok "git-hooks directory does not exist"
git hooks init &>/dev/null
ok "initialize git-hooks"
test -L $origin/.git/hooks
ok "git hooks is a symlink"
test -d $origin/.githooks
ok "git-hooks directory exists"
git branch -M main &>/dev/null
ok "use main"
repo=origin/main
git commit --allow-empty -m "initialize repo with main branch" &>/dev/null
ok "commit initialize repo with main branch"

unset repo
git -c core.symlinks=true clone $origin $clone &>/dev/null
ok "clone origin"

repo=clone/main && cd $clone
test -L $origin/.git/hooks
ok "git hooks is a symlink"
test -d $origin/.githooks
ok "git-hooks directory exists"
! git hooks init &>/dev/null
ok "re-initialize git-hooks does nothing"
test -L $origin/.git/hooks
ok "git hooks is a symlink"
test -d $origin/.githooks
ok "git-hooks directory exists"
(($(git hooks list | wc -l)==0))
ok "no git-hooks exist"
git checkout -b add_hooks &>/dev/null
ok "checkout new branch"

repo=clone/add_hooks
ln -nsf `which false` $clone/.githooks/pre-commit.d
git add $clone/.githooks/pre-commit.d/false &>/dev/null
ok "add pre-commit hook to fail"
(($(git hooks list | wc -l)==1))
ok "one git-hook exists"
! git commit -am "add pre-commit false hook" &>/dev/null
ok "commit prevent commit with pre-commit hook"
rm -f $clone/.githooks/pre-commit.d/false
ln -nsf `which true` $clone/.githooks/pre-commit.d
git add $clone/.githooks/pre-commit.d/true &>/dev/null
ok "add pre-commit hook to pass"
git commit -am "add pre-commit true hook" &>/dev/null
ok "commit allow commit with pre-commit hook"
ln -nsf `which false` $clone/.githooks/pre-receive.d
git add $clone/.githooks/pre-receive.d/false &>/dev/null
ok "add pre-receive hook to fail"
(($(git hooks list | wc -l)==2))
ok "two git-hooks exists"
git commit -am "add pre-receive false hook" &>/dev/null
ok "commit prevent receive with pre-receive hook"
git push -u origin add_hooks &>/dev/null
ok "allow push -u origin add_hooks (pre-receive hook not yet present)"

repo=origin/main
cd $origin
git merge add_hooks &>/dev/null
ok "merge add_hooks"

repo=clone/add_hooks
cd $clone
git commit --allow-empty -m "add empty commit" &>/dev/null
ok "commit add empty commit"
! git push &>/dev/null
ok "prevent push (pre-receive hook now present)"

unset repo
done_testing 32
