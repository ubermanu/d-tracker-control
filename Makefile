INSTALL = /bin/install -c
DESTDIR =
BINDIR = /bin

ifeq ($(PREFIX),)
	PREFIX := /usr/local
endif

install:
	$(INSTALL) -d $(DESTDIR)$(PREFIX)$(BINDIR)
	$(INSTALL) -m755 DTrackerControl.bash $(DESTDIR)$(PREFIX)$(BINDIR)/d-tracker-control
