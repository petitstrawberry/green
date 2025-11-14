CROSS_COMPILE ?=
BUILDROOT ?=
HOST_DIR ?=
SYSROOT ?=

PKG_CONFIG ?= pkg-config
SDL_CONFIG ?= sdl-config
RM 	?= rm -f
INSTALL ?= install

DESTDIR 	?=
PREFIX 	?= /usr/local
BINDIR 	?= $(PREFIX)/bin
SYSCONFDIR ?= $(PREFIX)/etc
MANDIR 	?= /usr/share/man

CPPFLAGS ?=
CFLAGS	?=
LDFLAGS ?=
LDLIBS 	?=

CPPFLAGS += -D GREEN_SYSCONFIG_FILE="$(SYSCONFDIR)/green.conf" -D GREEN_USERCONFIG_FILE=".green.conf"
CFLAGS	+= -Os -Wall

ifneq ($(BUILDROOT),)
ifneq ($(wildcard $(BUILDROOT)/host),)
HOST_DIR ?= $(BUILDROOT)/host
SYSROOT ?= $(BUILDROOT)/staging
else
ifneq ($(wildcard $(BUILDROOT)/output/host),)
HOST_DIR ?= $(BUILDROOT)/output/host
SYSROOT ?= $(BUILDROOT)/output/staging
endif
endif
endif

ifneq ($(HOST_DIR),)
ifneq ($(wildcard $(HOST_DIR)/bin/*-gcc),)
CROSS_COMPILE ?= $(patsubst %gcc,%,$(firstword $(wildcard $(HOST_DIR)/bin/*-gcc)))
endif
ifneq ($(wildcard $(HOST_DIR)/bin/pkg-config),)
PKG_CONFIG := $(HOST_DIR)/bin/pkg-config
endif
ifneq ($(wildcard $(HOST_DIR)/bin/pkgconf),)
PKG_CONFIG := $(HOST_DIR)/bin/pkgconf
endif
ifneq ($(wildcard $(HOST_DIR)/bin/sdl-config),)
SDL_CONFIG := $(HOST_DIR)/bin/sdl-config
endif
ifneq ($(wildcard $(HOST_DIR)/bin/sdl2-config),)
SDL_CONFIG := $(HOST_DIR)/bin/sdl2-config
endif
endif

ifneq ($(SYSROOT),)
export PKG_CONFIG_SYSROOT_DIR ?= $(SYSROOT)
export PKG_CONFIG_LIBDIR ?= $(SYSROOT)/usr/lib/pkgconfig:$(SYSROOT)/usr/share/pkgconfig
export PKG_CONFIG_DIR :=
endif

CC	?= $(CROSS_COMPILE)gcc
AR	?= $(CROSS_COMPILE)ar
STRIP	?= $(CROSS_COMPILE)strip

POPPLER_CFLAGS	:= $$($(PKG_CONFIG) poppler-glib --cflags)
POPPLER_LIBS	:= $$($(PKG_CONFIG) poppler-glib --libs)

SDL_WITH_PKGCONFIG := $(shell $(PKG_CONFIG) --exists sdl && echo yes)
ifeq ($(SDL_WITH_PKGCONFIG),yes)
SDL_CFLAGS	:= $$($(PKG_CONFIG) sdl --cflags)
SDL_LIBS	:= $$($(PKG_CONFIG) sdl --libs)
else
SDL_CFLAGS	:= $$($(SDL_CONFIG) --cflags)
SDL_LIBS	:= $$($(SDL_CONFIG) --libs)
endif

LDLIBS 	+= $(POPPLER_LIBS) $(SDL_LIBS)


all: green

clean:
	$(RM) green main.o green.o sdl.o

install: green
	$(INSTALL) -d $(DESTDIR)$(BINDIR)
	$(INSTALL) -d $(DESTDIR)$(MANDIR)/man1
	$(INSTALL) green $(DESTDIR)$(BINDIR)/
	$(INSTALL) green.1 $(DESTDIR)$(MANDIR)/man1/

green: main.o green.o sdl.o
	$(CC) $(LDFLAGS) $^ $(LDLIBS) -o $@

main.o: main.c green.h
	$(CC) $(CPPFLAGS) $(CFLAGS) $(POPPLER_CFLAGS) -c $< -o $@

green.o: green.c green.h
	$(CC) $(CPPFLAGS) $(CFLAGS) $(POPPLER_CFLAGS) -c $< -o $@

sdl.o: sdl.c green.h
	$(CC) $(CPPFLAGS) $(CFLAGS) $(POPPLER_CFLAGS) $(SDL_CFLAGS) -c $< -o $@
