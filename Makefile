CROSS_COMPILE ?=
BUILDROOT ?=
HOST_DIR ?=
SYSROOT ?=

PKG_CONFIG ?= pkg-config
SDL_CONFIG ?= sdl-config
RM 	?= rm -f
INSTALL ?= install

DEBUG ?= 0
DEBUG_CFLAGS ?= -g

DESTDIR 	?=
PREFIX 	?= /usr/local
BINDIR 	?= $(PREFIX)/bin
SYSCONFDIR ?= $(PREFIX)/etc
MANDIR 	?= /usr/share/man

CPPFLAGS ?=
CFLAGS	?=
LDFLAGS ?=
LDLIBS 	?=
CFLAGS	+= -Wall

ifeq ($(DEBUG),1)
CFLAGS += $(DEBUG_CFLAGS)
CFLAGS += -O0
else
CFLAGS += -Os
endif

ifneq ($(BUILDROOT),)
ifeq ($(HOST_DIR),)
ifneq ($(wildcard $(BUILDROOT)/host),)
HOST_DIR := $(BUILDROOT)/host
ifeq ($(SYSROOT),)
SYSROOT := $(BUILDROOT)/staging
endif
else ifneq ($(wildcard $(BUILDROOT)/output/host),)
HOST_DIR := $(BUILDROOT)/output/host
ifeq ($(SYSROOT),)
SYSROOT := $(BUILDROOT)/output/staging
endif
endif
endif
endif

ifeq ($(CROSS_COMPILE),)
ifneq ($(HOST_DIR),)
first_cross := $(firstword $(wildcard $(HOST_DIR)/bin/*-gcc))
ifneq ($(first_cross),)
CROSS_COMPILE := $(patsubst %gcc,%,$(first_cross))
endif
endif
endif

ifneq ($(HOST_DIR),)
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

ifeq ($(origin CC), default)
CC := $(if $(CROSS_COMPILE),$(CROSS_COMPILE)gcc,cc)
endif

ifeq ($(origin AR), default)
AR := $(if $(CROSS_COMPILE),$(CROSS_COMPILE)ar,ar)
endif

ifeq ($(origin STRIP), default)
STRIP := $(if $(CROSS_COMPILE),$(CROSS_COMPILE)strip,strip)
endif

POPPLER_CFLAGS	:= $(shell $(PKG_CONFIG) --cflags poppler-glib 2>/dev/null)
POPPLER_LIBS	:= $(shell $(PKG_CONFIG) --libs poppler-glib 2>/dev/null)

SDL_WITH_PKGCONFIG := $(shell $(PKG_CONFIG) --exists sdl && echo yes)
ifeq ($(SDL_WITH_PKGCONFIG),yes)
SDL_CFLAGS	:= $(shell $(PKG_CONFIG) --cflags sdl 2>/dev/null)
SDL_LIBS	:= $(shell $(PKG_CONFIG) --libs sdl 2>/dev/null)
else
SDL_CFLAGS	:= $(shell $(SDL_CONFIG) --cflags 2>/dev/null)
SDL_LIBS	:= $(shell $(SDL_CONFIG) --libs 2>/dev/null)
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
