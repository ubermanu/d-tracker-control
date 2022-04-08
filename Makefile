INSTALL = /bin/install -c
DESTDIR =
PREFIX = /usr/local
BINDIR = /bin

all:

install: all
	$(INSTALL) -d $(DESTDIR)$(PREFIX)$(BINDIR)
	$(INSTALL) -m755 d-tracker-control.bash $(DESTDIR)$(PREFIX)$(BINDIR)/d-tracker-control
