export CURDIR

all:
	bash -n git-hooks

test: all
	for test in t/*; do $$test; done

install: test
	install -m 0755 git-hooks $(DESTDIR)/usr/bin

uninstall:
	rm -f $(DESTDIR)/usr/bin/git-hooks