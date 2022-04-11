INSTALL = /bin/install -c
DESTDIR =
PREFIX = /usr/local
BINDIR = /bin

.PHONY: build dev

all: build install

install:
	$(INSTALL) -d $(DESTDIR)$(PREFIX)$(BINDIR)
	$(INSTALL) -m755 build/DTrackerControl $(DESTDIR)$(PREFIX)$(BINDIR)/d-tracker-control

build:
	haxe build.hxml

# run `make dev action=toggle` for example
dev:
	haxe -L captain --run DTrackerControl $(action)
