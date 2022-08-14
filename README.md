## NAME

git-hooks - include hooks with git repo

## SYNOPSIS

```bash
$ cd repo
$ git hooks init
$ git hooks edit pre-commit hook-name
$ git hooks enable pre-commit hook-name
$ git hooks list
```

## DESCRIPTION

Include hooks with repo so that all contributors can be bound by the same hooks.  Hooks are stored in HOOKS_DIR, which defaults to .githooks.

## TEST

```
$ make test
```

Run tests in t/.

## INSTALL

```
$ sudo make install
```

Install git-hooks to /usr/bin

## SUB-COMMANDS

### disable

```
$ git hooks disable <type> <name>
```

Permanently disable the specified hook in HOOKS_DIR.

```
$ git hooks disable pre-commit commit-message-requirements
```

### edit

```
$ git hooks edit <type> <name>
```

Edit the specified hook in HOOKS_DIR using the editor specified by the core.editor git configuration, the value of the EDITOR environment variable, or vi.

```
$ git hooks edit pre-commit commit-message-requirements
```

### enable

```
$ git hooks enable <type> <name>
```

Permanently enable the specified hook in HOOKS_DIR.

```
$ git hooks enable pre-commit commit-message-requirements
```

### help

```
$ git hooks help
```

Show help and exit.

### init

```
$ git hooks init
```

This is a safe operation. It will initialize the git repo (also a safe operation). It will backup the .git/hooks dir and create a symlink to HOOKS_DIR. It will create all of the hooks in HOOKS_DIR. If there are any changes to HOOKS_DIR, they will be committed to the current branch.

### list

```
$ git hooks list
```

List each hook found in HOOKS_DIR and whether or not it's enabled.

### version

```
$ git hooks version
```

Show version and exit.

## HOOKS

Supported hooks are:
applypatch-msg pre-applypatch post-applypatch pre-commit prepare-commit-msg
commit-msg post-commit pre-rebase post-checkout post-merge pre-receive update
post-receive post-update pre-auto-gc post-rewrite pre-push

The following environment variables affect how hooks are handled:
- DISABLE_ALL_HOOKS - set this to disable processing all hooks
- DISABLE_HOOKS[] - set this array to disable processing specified hooks
- EXTRA_HOOKS[] - set this array to initialize and process extra hooks
- EXTRA_STDIN_HOOKS[] - set this array to pass stdin (from git) to extra hooks
