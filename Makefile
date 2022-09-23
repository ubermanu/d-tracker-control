INSTALL = /bin/install -c
DESTDIR =
PREFIX = /usr/local
BINDIR = /bin

all: install

install:
	$(INSTALL) -d $(DESTDIR)$(PREFIX)$(BINDIR)
	$(INSTALL) -m755 DTrackerControl.bash $(DESTDIR)$(PREFIX)$(BINDIR)/d-tracker-control
