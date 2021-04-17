###########################################################################
#
#   makefile
#
#   Core makefile for building MAME and derivatives
#
#   Copyright (c) Nicola Salmoria and the MAME Team.
#   Visit http://mamedev.org for licensing and usage restrictions.
#
#   Apple Env tweaks 07-2020 Mrjs
#
###########################################################################

OSD = droid-ios

NOWERROR = 1

########## iOS/tvOS specific settings

# set minimum tvOS and iOS version for the SDK to use
OSVERSION = 12.4

iOS = 1

iOSOSX = 1

iOSARM64 = 1

ifndef ARCH
ifdef iOSSIMULATOR
ARCH = $(shell uname -m)	# arm64 or x86_64
else ifdef macCatalyst
ARCH = $(shell uname -m)	# arm64 or x86_64
else
ARCH = arm64
endif
endif

OPTIMIZE = fast

################

CROSS_BUILD = 1

PTR64 = 1

# uncomment to force the universal DRC to always use the C backend
# you may need to do this if your target architecture does not have
# a native backend
FORCE_DRC_C_BACKEND = 1

# setup the varios Apple SDK locations
IOSSDK := $(shell xcodebuild -version -sdk iphoneos Path)
TVOSSDK := $(shell xcodebuild -version -sdk appletvos Path)
MACOSSDK := $(shell xcodebuild -version -sdk macosx Path)
SIMSDK := $(shell xcodebuild -version -sdk iphonesimulator Path)

###########################################################################
#################   BEGIN USER-CONFIGURABLE OPTIONS   #####################
###########################################################################

#-------------------------------------------------
# specify core target: mame, mess, etc.
# specify subtarget: mame, mess, tiny, etc.
# build rules will be included from
# src/$(TARGET)/$(SUBTARGET).mak
#-------------------------------------------------

TARGET = mame

SUBTARGET = $(TARGET)

#-------------------------------------------------
# specify OSD layer: windows, sdl, etc.
# build rules will be included from
# src/osd/$(OSD)/$(OSD).mak
#-------------------------------------------------

ifndef OSD
ifeq ($(OS),Windows_NT)
OSD = windows
TARGETOS = win32
else
OSD = sdl
endif
endif

ifndef CROSS_BUILD_OSD
CROSS_BUILD_OSD = $(OSD)
endif

#-------------------------------------------------
# specify OS target, which further differentiates
# the underlying OS; supported values are:
# win32, unix, macosx, os2
#-------------------------------------------------

TARGETOS = macosx

#-------------------------------------------------
# configure name of final executable
#-------------------------------------------------

# uncomment and specify prefix to be added to the name
# PREFIX =

# uncomment and specify suffix to be added to the name
# SUFFIX =

#-------------------------------------------------
# specify architecture-specific optimizations
#-------------------------------------------------

# uncomment and specify architecture-specific optimizations here
# some examples:
#   optimize for I686:   ARCHOPTS = -march=pentiumpro
#   optimize for Core 2: ARCHOPTS = -march=core2
#   optimize for G4:     ARCHOPTS = -mcpu=G4
# note that we leave this commented by default so that you can
# configure this in your environment and never have to think about it
# ARCHOPTS =

#-------------------------------------------------
# specify program options; see each option below
# for details
#-------------------------------------------------

# uncomment next line to build a debug version
# DEBUG = 1

# uncomment next line to include the internal profiler
# PROFILER = 1

# uncomment the force the universal DRC to always use the C backend
# you may need to do this if your target architecture does not have
# a native backend
# FORCE_DRC_C_BACKEND = 1

# uncomment next line to build using unix-style libsdl on Mac OS X
# (vs. the native framework port).  Normal users should not enable this.
# MACOSX_USE_LIBSDL = 1

#-------------------------------------------------
# specify build options; see each option below
# for details
#-------------------------------------------------

# uncomment next line if you are building for a 64-bit target
# PTR64 = 1

# uncomment next line if you are building for a big-endian target
# BIGENDIAN = 1

# uncomment next line to build expat as part of MAME build
BUILD_EXPAT = 1

# uncomment next line to build zlib as part of MAME build
BUILD_ZLIB = 1

# uncomment next line to include the symbols
# SYMBOLS = 1

# specify symbols level or leave commented to use the default
# (default is SYMLEVEL = 2 normally; use 1 if you only need backtrace)
# SYMLEVEL = 2

# uncomment next line to dump the symbols to a .sym file
# DUMPSYM = 1

# uncomment next line to include profiling information from the compiler
# PROFILE = 1

# uncomment next line to generate a link map for exception handling in windows
# MAP = 1

# uncomment next line to generate verbose build information
# VERBOSE = 1

# specify optimization level or leave commented to use the default
# (default is OPTIMIZE = 3 normally, or OPTIMIZE = 0 with symbols)
# OPTIMIZE = 3

###########################################################################
##################   END USER-CONFIGURABLE OPTIONS   ######################
###########################################################################

#-------------------------------------------------
# sanity check the configuration
#-------------------------------------------------

# specify a default optimization level if none explicitly stated
ifndef OPTIMIZE
ifndef SYMBOLS
OPTIMIZE = 3
else
OPTIMIZE = 0
endif
endif

# profiler defaults to on for DEBUG builds
ifdef DEBUG
ifndef PROFILER
PROFILER = 1
endif
endif

# allow gprof profiling as well, which overrides the internal PROFILER
# also enable symbols as it is useless without them
ifdef PROFILE
PROFILER =
SYMBOLS = 1
ifndef SYMLEVEL
SYMLEVEL = 1
endif
endif

# set the symbols level
ifdef SYMBOLS
ifndef SYMLEVEL
SYMLEVEL = 2
endif
endif

#-------------------------------------------------
# platform-specific definitions
#-------------------------------------------------

# extension for executables
EXE =

ifeq ($(TARGETOS),win32)
EXE = .exe
endif
ifeq ($(TARGETOS),os2)
EXE = .exe
endif

ifndef BUILD_EXE
BUILD_EXE = $(EXE)
endif

AR = @ar
CC = @cc
LD = @c++

#endif

MD = -mkdir$(EXE)
RM = @rm -f
OBJDUMP = @objdump

#-------------------------------------------------
# form the name of the executable
#-------------------------------------------------

# reset all internal prefixes/suffixes
PREFIXSDL =
SUFFIX64 =
SUFFIXDEBUG =
SUFFIXPROFILE =

# Windows SDL builds get an SDL prefix
ifeq ($(OSD),sdl)
ifeq ($(TARGETOS),win32)
PREFIXSDL = sdl
endif
endif

# 64-bit builds get a '64' suffix
ifeq ($(PTR64),1)
SUFFIX64 = 64
endif

# debug builds just get the 'd' suffix and nothing more
ifdef DEBUG
SUFFIXDEBUG = d
endif

# gprof builds get an addition 'p' suffix
ifdef PROFILE
SUFFIXPROFILE = p
endif

# the name is just 'target' if no subtarget; otherwise it is
# the concatenation of the two (e.g., mametiny)
ifeq ($(TARGET),$(SUBTARGET))
NAME = $(TARGET)
else
NAME = $(TARGET)$(SUBTARGET)
endif

# fullname is prefix+name+suffix+suffix64+suffixdebug
FULLNAME = $(PREFIX)$(PREFIXSDL)$(NAME)$(SUFFIX)$(SUFFIX64)$(SUFFIXDEBUG)$(SUFFIXPROFILE)

# get the final emulator name

ifdef tvOS
EMULATOR = libmame-tvos.a
else ifdef macCatalyst
EMULATOR = libmame-mac-$(ARCH).a
else
EMULATOR = libmame-ios.a
endif

#-------------------------------------------------
# source and object locations
#-------------------------------------------------

# all sources are under the src/ directory
SRC = src

# build the targets in different object dirs, so they can co-exist
OBJ = obj/$(OSD)/$(FULLNAME)

#-------------------------------------------------
# compile-time definitions
#-------------------------------------------------

# CR/LF setup: use both on win32/os2, CR only on everything else
DEFS = -DCRLF=2 -DDISABLE_MIDI=1

# map the INLINE to something digestible by GCC
DEFS += -DINLINE="static inline"

# define LSB_FIRST if we are a little-endian target
ifndef BIGENDIAN
DEFS += -DLSB_FIRST
endif

# define PTR64 if we are a 64-bit target
ifeq ($(PTR64),1)
DEFS += -DPTR64
endif

# define MAME_DEBUG if we are a debugging build
ifdef DEBUG
DEFS += -DMAME_DEBUG
else
DEFS += -DNDEBUG
endif

# define MAME_PROFILER if we are a profiling build
ifdef PROFILER
DEFS += -DMAME_PROFILER
endif

#-------------------------------------------------
# compile flags
# CCOMFLAGS are common flags
# CONLYFLAGS are flags only used when compiling for C
# CPPONLYFLAGS are flags only used when compiling for C++
# COBJFLAGS are flags only used when compiling for Objective-C(++)
#-------------------------------------------------

# start with empties for everything
CCOMFLAGS =
CONLYFLAGS =
COBJFLAGS =
CPPONLYFLAGS =

# add in support for GIT version that was built against: slowsdown make -n eval
#GIT_VERSION ?= " $(shell git rev-parse --short HEAD || echo unknown)"
#ifneq ($(GIT_VERSION)," unknown")
#	CCOMFLAGS += -DGIT_VERSION=\"$(GIT_VERSION)\"
#endif

# CFLAGS is defined based on C or C++ targets
# (remember, expansion only happens when used, so doing it here is ok)
CFLAGS = $(CCOMFLAGS) $(CPPONLYFLAGS)

# we compile C-only to C89 standard with GNU extensions
# we compile C++ code to C++98 standard with GNU extensions
CONLYFLAGS += -std=gnu89
CPPONLYFLAGS += -x c++ -stdlib=libc++
COBJFLAGS += -x objective-c

# this speeds it up a bit by piping between the preprocessor/compiler/assembler
CCOMFLAGS += -pipe

# add -g if we need symbols, and ensure we have frame pointers
ifdef SYMBOLS
CCOMFLAGS += -g$(SYMLEVEL) -fno-omit-frame-pointer
endif

# add -v if we need verbose build information
ifdef VERBOSE
CCOMFLAGS += -v
ARFLAGS += -v
endif

# add profiling information for the compiler
ifdef PROFILE
CCOMFLAGS += -pg
endif

# add the optimization flag
CCOMFLAGS += -O$(OPTIMIZE)

# if we are optimizing, include optimization options
# and make all errors into warnings
ifneq ($(OPTIMIZE),0)
ifneq ($(TARGETOS),os2)
ifndef NOWERROR
CCOMFLAGS += -Werror -fno-strict-aliasing
else
CCOMFLAGS += -fno-strict-aliasing
endif
else
CCOMFLAGS += -fno-strict-aliasing
endif
endif

#-------------------------------------------------
# include paths
#-------------------------------------------------

# add core include paths
CCOMFLAGS +=\
	-I$(SRC)/$(TARGET) \
	-I$(OBJ)/$(TARGET)/layout \
	-I$(SRC)/emu \
	-I$(OBJ)/emu \
	-I$(OBJ)/emu/layout \
	-I$(SRC)/lib/util \
	-I$(SRC)/osd \
	-I$(SRC)/osd/$(OSD) \

ifdef iOS
CCOMFLAGS += \
	-iquote$(SRC)/../iOS/btstack \
	-iquote$(SRC)/../iOS

endif

#-------------------------------------------------
# archiving flags
#-------------------------------------------------
# Default to something reasonable for all platforms
ARFLAGS = -cr
# Deal with macosx brain damage if COMMAND_MODE is in
# the luser's environment:
ifeq ($(TARGETOS),macosx)
ifeq ($(COMMAND_MODE),"legacy")
ARFLAGS = -crs
endif
endif

#-------------------------------------------------
# linking flags
#-------------------------------------------------

# LDFLAGS are used generally; LDFLAGSEMULATOR are additional
# flags only used when linking the core emulator
LDFLAGS =
ifneq ($(TARGETOS),macosx)
ifneq ($(TARGETOS),os2)
ifneq ($(TARGETOS),solaris)
LDFLAGS = -Wl,--warn-common
endif
endif
endif
LDFLAGSEMULATOR =

# add profiling information for the linker
ifdef PROFILE
LDFLAGS += -pg
endif

# strip symbols and other metadata in non-symbols and non profiling builds
ifndef SYMBOLS
ifneq ($(TARGETOS),macosx)
LDFLAGS += -s
endif
endif

# output a map file (emulator only)
ifdef MAP
LDFLAGSEMULATOR += -Wl,-Map,$(FULLNAME).map
endif

#-------------------------------------------------
# define the standard object directory; other
# projects can add their object directories to
# this variable
#-------------------------------------------------

OBJDIRS = $(OBJ)

#-------------------------------------------------
# define standard libarires for CPU and sounds
#-------------------------------------------------

VERSIONOBJ = $(OBJ)/version.o

#-------------------------------------------------
# either build or link against the included
# libraries
#-------------------------------------------------

# start with an empty set of libs
LIBS =

# add expat XML library
ifeq ($(BUILD_EXPAT),1)
CCOMFLAGS += -I$(SRC)/lib/expat
EXPAT = $(OBJ)/libexpat.a
else
LIBS += -lexpat
EXPAT =
endif

# add ZLIB compression library
ifeq ($(BUILD_ZLIB),1)
CCOMFLAGS += -I$(SRC)/lib/zlib
ZLIB = $(OBJ)/libz.a
else
LIBS += -lz
ZLIB =
endif

# add SoftFloat floating point emulation library
SOFTFLOAT = $(OBJ)/libsoftfloat.a

ifdef iOS
CCOMFLAGS += -DIOS -DSDLMAME_NO64BITIO

ifndef iOSOSX
CCOMFLAGS += -DIOS3
CCOMFLAGS += -F/home/david/Projects/iphone/toolchain/sdks/iPhoneOS3.1.2.sdk/System/Library/PrivateFrameworks
else #OSX

ifdef iOSSIMULATOR
CFLAGS += -isysroot $(SIMSDK)
endif

CCOMFLAGS += -arch $(ARCH)
LDFLAGS += -arch $(ARCH)

ifndef iOSSIMULATOR

ifdef tvOS
#tvOS build command goes here
CCOMFLAGS += -isysroot $(TVOSSDK) -mtvos-version-min=$(OSVERSION) -fPIC
LDFLAGS += -lz -isysroot $(TVOSSDK) -mtvos-version-min=$(OSVERSION) -fPIC -dynamiclib
else ifdef macCatalyst
#macCatalyst goes here
CCOMFLAGS += -isysroot $(MACOSSDK) -miphoneos-version-min=$(OSVERSION) -fPIC -target x86_64-apple-ios13.1-macabi
LDFLAGS += -lz -isysroot $(MACOSSDK) -miphoneos-version-min=$(OSVERSION) -fPIC -stdlib=libc++ -dynamiclib
else
#iOS goes here
CCOMFLAGS += -isysroot $(IOSSDK) -miphoneos-version-min=$(OSVERSION) -fPIC
LDFLAGS += -lz -isysroot $(IOSSDK) -miphoneos-version-min=$(OSVERSION) -fPIC -stdlib=libc++ -dynamiclib
endif

else

#simulator build goes here

CCOMFLAGS += -D__IPHONE_OS_VERSION_MIN_REQUIRED=120000

ifndef tvOS
CCOMFLAGS += -mios-simulator-version-min=$(OSVERSION)
else
CCOMFLAGS += -mtvos-simulator-version-min=$(OSVERSION) 
endif

endif

endif

CCOMFLAGS +=

endif

#-------------------------------------------------
# 'default' target needs to go here, before the
# include files which define additional targets
#-------------------------------------------------

default: maketree buildtools emulator

#all: default tools
all: default

#-------------------------------------------------
# defines needed by multiple make files
#-------------------------------------------------

BUILDSRC = $(SRC)/build
BUILDOBJ = $(OBJ)/build
BUILDOUT = $(BUILDOBJ)

#-------------------------------------------------
# include the various .mak files
#-------------------------------------------------

# include OSD-specific rules first
include $(SRC)/osd/$(OSD)/$(OSD).mak

# then the various core pieces
include $(SRC)/$(TARGET)/$(SUBTARGET).mak
include $(SRC)/emu/emu.mak
include $(SRC)/lib/lib.mak
include $(SRC)/build/build.mak
-include $(SRC)/osd/$(CROSS_BUILD_OSD)/build.mak
include $(SRC)/tools/tools.mak

# combine the various definitions to one
CDEFS = $(DEFS)

#-------------------------------------------------
# primary targets
#-------------------------------------------------

emulator: maketree $(BUILD) $(EMULATOR)

buildtools: maketree $(BUILD)

tools: maketree $(TOOLS)

maketree: $(sort $(OBJDIRS))

clean: $(OSDCLEAN)
	@echo Deleting object tree $(OBJ)...
	$(RM) -r $(OBJ)
	@echo Deleting $(EMULATOR)...
	$(RM) $(EMULATOR)
	@echo Deleting $(TOOLS)...
	$(RM) $(TOOLS)
ifdef MAP
	@echo Deleting $(FULLNAME).map...
	$(RM) $(FULLNAME).map
endif

checkautodetect:
	@echo TARGETOS=$(TARGETOS)
	@echo PTR64=$(PTR64)
	@echo BIGENDIAN=$(BIGENDIAN)
	@echo UNAME="$(UNAME)"

#-------------------------------------------------
# directory targets
#-------------------------------------------------

$(sort $(OBJDIRS)):
	$(MD) -p $@

$(OBJ)/build/file2str$(CCEXE):
	mkdir -p $(OBJ)/build
	cp -R prec-build/file2str$(CCEXE) $(OBJ)/build

$(OBJ)/build/m68kmake$(CCEXE):
	cp -R prec-build/m68kmake$(CCEXE) $(OBJ)/build

$(OBJ)/build/png2bdc$(CCEXE):
	cp -R prec-build/png2bdc$(CCEXE) $(OBJ)/build

$(OBJ)/build/tmsmake$(CCEXE):
	cp -R prec-build/tmsmake$(CCEXE) $(OBJ)/build

$(OBJ)/build/verinfo$(CCEXE):
	cp -R prec-build/verinfo$(CCEXE) $(OBJ)/build

#-------------------------------------------------
# executable targets and dependencies
#-------------------------------------------------

ifndef EXECUTABLE_DEFINED

# always recompile the version string
$(VERSIONOBJ): $(DRVLIBS) $(OSDOBJS) $(CPUOBJS) $(LIBEMUOBJS) $(SOUNDOBJS) $(UTILOBJS) $(EXPATOBJS) $(ZLIBOBJS) $(SOFTFLOATOBJS) $(OSDCOREOBJS) $(RESFILE)

$(EMULATOR): $(VERSIONOBJ) $(DRVLIBS) $(OSDOBJS) $(CPUOBJS) $(LIBEMUOBJS) $(DASMOBJS) $(SOUNDOBJS) $(UTILOBJS) $(EXPATOBJS) $(SOFTFLOATOBJS) $(ZLIBOBJS) $(OSDCOREOBJS) $(RESFILE)
	@echo Archiving $@...
	$(AR) $(ARFLAGS) $@ $^

ifeq ($(TARGETOS),win32)
ifdef SYMBOLS
	$(OBJDUMP) --section=.text --line-numbers --syms --demangle $@ >$(FULLNAME).sym
endif
endif

endif

#-------------------------------------------------
# generic rules
#-------------------------------------------------

$(OBJ)/%.o: $(SRC)/%.c | $(OSPREBUILD)
	@echo Compiling $<...
	@$(CC) $(CDEFS) $(CFLAGS) -c $< -o $@

$(OBJ)/%.pp: $(SRC)/%.c | $(OSPREBUILD)
	@echo Compiling $<...
	@$(CC) $(CDEFS) $(CFLAGS) -E $< -o $@

$(OBJ)/%.s: $(SRC)/%.c | $(OSPREBUILD)
	@echo Compiling $<...
	@$(CC) $(CDEFS) $(CFLAGS) -S $< -o $@

$(OBJ)/%.lh: $(SRC)/%.lay $(FILE2STR)
	@echo Converting $<...
	@$(FILE2STR) $< $@ layout_$(basename $(notdir $<))

$(OBJ)/%.fh: $(SRC)/%.png $(PNG2BDC) $(FILE2STR)
	@echo Converting $<...
	@$(PNG2BDC) $< $(OBJ)/temp.bdc
	@$(FILE2STR) $(OBJ)/temp.bdc $@ font_$(basename $(notdir $<)) UINT8

$(OBJ)/%.a:
	@echo Archiving $@...
	@$(RM) $@
	@$(AR) $(ARFLAGS) $@ $^

$(OBJ)/%.o: %.m
	@echo Compiling $<...
	@$(CC) $(CDEFS) $(COBJFLAGS) $(CCOMFLAGS) -c $< -o $@

ifeq ($(TARGETOS),macosx)
$(OBJ)/%.o: $(SRC)/%.m | $(OSPREBUILD)
	@echo Objective-C compiling $<...
	$(CC) $(CDEFS) $(COBJFLAGS) $(CCOMFLAGS) -c $< -o $@
endif

# Add-in an empty variable to be able to add in CFLAGS when using the command line. i.e -w to reduce all error messages.
# In our case we'll use CDBG=-w for instance to remove warnings
CDBG +=
CFLAGS += $(CDBG)
