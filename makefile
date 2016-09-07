###########################################################################
#
#   makefile
#
#   Core makefile for building MAME and derivatives
#
#   Copyright (c) Nicola Salmoria and the MAME Team.
#   Visit http://mamedev.org for licensing and usage restrictions.
#
###########################################################################

#http://gcc.gnu.org/onlinedocs/gcc/ARM-Options.html

OSD = droid-ios
#OSD = osdmini
#OSD = sdl
NOWERROR = 1

#SUBTARGET = tiny

############ ANDROID

#ANDROID = 1

#AMIPS=1

#AX86=1

#AARMV7=1

#AARMV6=1

########## iOS

iOS = 1

iOSOSX = 1
iOSNOJAILBREAK = 1

#iOSSIMULATOR = 1

#iOSARMV7=1

#iOSARMV7S=1

iOSARM64=1

################

CROSS_BUILD = 1

#TARGETOS = android
PTR64 = 0

X86_MIPS3_DRC =
X86_PPC_DRC =
FORCE_DRC_C_BACKEND = 1

#OPTIMIZE = 1

ifdef ANDROID

ifdef AMIPS
MYPREFIX=/home/david/Projects/android/my-android-toolchain-r8-mips/bin/mipsel-linux-android-
BASE_DEV=/home/david/Projects/android/my-android-toolchain-r8-mips/sysroot
endif

ifdef AX86
MYPREFIX=/home/david/Projects/android/my-android-toolchain-r8-x86/bin/i686-android-linux-
BASE_DEV=/home/david/Projects/android/my-android-toolchain-r8-x86/sysroot
endif

ifdef AARMV6
MYPREFIX=/home/david/Projects/android/my-android-toolchain-r8/bin/arm-linux-androideabi-
BASE_DEV=/home/david/Projects/android/my-android-toolchain-r8/sysroot
endif

ifdef AARMV7
MYPREFIX=/home/david/Projects/android/my-android-toolchain-r8/bin/arm-linux-androideabi-
BASE_DEV=/home/david/Projects/android/my-android-toolchain-r8/sysroot
endif

#MYPREFIX=/home/david/Projects/android/my-android-toolchain-14-crystax/bin/arm-linux-androideabi-
#BASE_DEV=/home/david/Projects/android/my-android-toolchain-14-crystax/sysroot

endif

ifdef iOS
ifndef iOSOSX
##TOOLCHAIN
MYPREFIX=/home/david/Projects/iphone/toolchain/toolchain/pre/bin/arm-apple-darwin9-
BASE_DEV=/home/david/Projects/iphone/toolchain/sdks/iPhoneOS2.0.sdk
#BASE_DEV=/home/david/Projects/iphone/toolchain/sdks/iPhoneOS4.1.sdk
else
##OSX
ifndef iOSSIMULATOR
#MYPREFIX=/Developer/Platforms/iPhoneOS.platform/Developer/usr/bin/arm-apple-darwin10-
#MYPREFIX=/Developer/Platforms/iPhoneOS.platform/Developer/usr/llvm-gcc-4.2/bin/arm-apple-darwin10-llvm-
#MYPREFIX=/Applications/Xcode.app/Contents/Developer/Platforms/iPhoneOS.platform/Developer/usr/llvm-gcc-4.2/bin/arm-apple-darwin10-llvm-
#MYPREFIX=/Applications/Xcode.app/Contents/Developer/Platforms/iPhoneOS.platform/Developer/usr/bin/
MYPREFIX=/usr/bin/

#BASE_DEV=/Developer/Platforms/iPhoneOS.platform/Developer/SDKs/iPhoneOS4.2.sdk
#BASE_DEV=/Applications/Xcode.app/Contents/Developer/Platforms/iPhoneOS.platform/Developer/SDKs/iPhoneOS6.1.sdk
BASE_DEV=/Applications/Xcode.app/Contents/Developer/Platforms/iPhoneOS.platform/Developer/SDKs/iPhoneOS.sdk
else

MYPREFIX=/Applications/Xcode.app/Contents/Developer/Platforms/iPhoneSimulator.platform/Developer/usr/bin/
BASE_DEV=/Applications/Xcode.app/Contents/Developer/Platforms/iPhoneSimulator.platform/Developer/SDKs/iPhoneSimulator6.1.sdk

endif

endif
endif

###########################################################################
#################   BEGIN USER-CONFIGURABLE OPTIONS   #####################
###########################################################################


#-------------------------------------------------
# specify core target: mame, mess, etc.
# specify subtarget: mame, mess, tiny, etc.
# build rules will be included from 
# src/$(TARGET)/$(SUBTARGET).mak
#-------------------------------------------------

ifndef TARGET
TARGET = mame
endif

ifndef SUBTARGET
SUBTARGET = $(TARGET)
endif



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

ifndef TARGETOS

ifeq ($(OS),Windows_NT)
TARGETOS = win32
else

ifneq ($(CROSSBUILD),1)

ifneq ($(OS2_SHELL),)
TARGETOS = os2
else

UNAME = $(shell uname -a)

ifeq ($(firstword $(filter Linux,$(UNAME))),Linux)
TARGETOS = unix
endif
ifeq ($(firstword $(filter Solaris,$(UNAME))),Solaris)
TARGETOS = solaris
endif
ifeq ($(firstword $(filter FreeBSD,$(UNAME))),FreeBSD)
TARGETOS = freebsd
endif
ifeq ($(firstword $(filter GNU/kFreeBSD,$(UNAME))),GNU/kFreeBSD)
TARGETOS = freebsd
endif
ifeq ($(firstword $(filter OpenBSD,$(UNAME))),OpenBSD)
TARGETOS = openbsd
endif
ifeq ($(firstword $(filter Darwin,$(UNAME))),Darwin)
TARGETOS = macosx
endif

ifndef TARGETOS
$(error Unable to detect TARGETOS from uname -a: $(UNAME))
endif

# Autodetect PTR64
ifndef PTR64
ifeq ($(firstword $(filter x86_64,$(UNAME))),x86_64)
PTR64 = 1
endif
ifeq ($(firstword $(filter amd64,$(UNAME))),amd64)
PTR64 = 1
endif
ifeq ($(firstword $(filter ppc64,$(UNAME))),ppc64)
PTR64 = 1
endif
endif

# Autodetect BIGENDIAN 
# MacOSX
ifndef BIGENDIAN
ifneq (,$(findstring Power,$(UNAME)))
BIGENDIAN=1
endif
# Linux
ifneq (,$(findstring ppc,$(UNAME)))
BIGENDIAN=1
endif
endif # BIGENDIAN

endif # OS/2
endif # CROSS_BUILD	
endif # Windows_NT

endif # TARGET_OS


ifeq ($(TARGETOS),win32)

# Autodetect PTR64
ifndef PTR64
ifneq (,$(findstring mingw64-w64,$(PATH)))
PTR64=1
endif
endif

endif



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

# compiler, linker and utilities

ifdef iOSOSX
AR = @$(MYPREFIX)ar
#CC = @$(MYPREFIX)gcc-4.2
#LD = @$(MYPREFIX)g++-4.2
CC = @$(MYPREFIX)gcc
LD = @$(MYPREFIX)g++


else

AR = @$(MYPREFIX)ar
CC = @$(MYPREFIX)gcc
LD = @$(MYPREFIX)g++

endif

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

# add an EXE suffix to get the final emulator name
ifdef iOSNOJAILBREAK
ifdef iOSSIMULATOR
EMULATOR = libmamesim.a
endif
ifdef iOSARMV7
EMULATOR = libmamearmv7.a
endif
ifdef iOSARMV7S
EMULATOR = libmamearmv7s.a
endif
ifdef iOSARM64
EMULATOR = libmamearm64.a
endif
else
EMULATOR = $(FULLNAME)$(EXE)
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
DEFS = -DCRLF=2

ifeq ($(TARGETOS),win32)
DEFS = -DCRLF=3
endif
ifeq ($(TARGETOS),os2)
DEFS = -DCRLF=3
endif

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

# CFLAGS is defined based on C or C++ targets
# (remember, expansion only happens when used, so doing it here is ok)
CFLAGS = $(CCOMFLAGS) $(CPPONLYFLAGS)

# we compile C-only to C89 standard with GNU extensions
# we compile C++ code to C++98 standard with GNU extensions
CONLYFLAGS += -std=gnu89
CPPONLYFLAGS += -x c++ -std=gnu++98
#COBJFLAGS += -x objective-c++
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
CCOMFLAGS += -Werror -fno-strict-aliasing $(ARCHOPTS)
else
CCOMFLAGS += -fno-strict-aliasing $(ARCHOPTS)
endif
else
CCOMFLAGS += -fno-strict-aliasing $(ARCHOPTS)
endif
endif

# add a basic set of warnings
CCOMFLAGS += \
	-Wformat -Wformat-security \
	-Wwrite-strings \
	-Wno-sign-compare \
	
#	-Wundef \	
#	-Wall \
#	-Wcast-align \
	
# warnings only applicable to C compiles
CONLYFLAGS += \
	-Wpointer-arith \
	-Wbad-function-cast \
	-Wstrict-prototypes

# warnings only applicable to OBJ-C compiles
COBJFLAGS += \
	-Wpointer-arith 



#-------------------------------------------------
# include paths
#-------------------------------------------------

#CCOMFLAGS +=  -I/Developer/Platforms/iPhoneOS.platform/Developer/SDKs/iPhoneOS4.2.sdk/usr/include

# add core include paths
CCOMFLAGS += \
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
#LDFLAGS = -Wl,--warn-common
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

#LIBEMU = $(OBJ)/libemu.a
#LIBCPU = $(OBJ)/libcpu.a
#LIBDASM = $(OBJ)/libdasm.a
#LIBSOUND = $(OBJ)/libsound.a
#LIBUTIL = $(OBJ)/libutil.a
#LIBOCORE = $(OBJ)/libocore.a
#LIBOSD = $(OBJ)/libosd.a

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


ifdef ANDROID
CCOMFLAGS += --sysroot $(BASE_DEV)
CCOMFLAGS += -DANDROID
CCOMFLAGS += -fpic

ifdef AARMV7
CCOMFLAGS += -march=armv7-a -mfloat-abi=softfp -DARMV7
#CCOMFLAGS += -mfpu=neon
#CCOMFLAGS += -pipe  -mtune=cortex-a9
LDFLAGS += -Wl,--fix-cortex-a8
endif

ifdef AARMV6
LDFLAGS += -Wl,--fix-cortex-a8
endif


CCOMFLAGS += -Wno-psabi

LDFLAGS += -llog -lgcc
LDFLAGS += -Wl,-soname,libMAME4droid.so -shared
LDFLAGS += -lc -lm 


CCOMFLAGS += -fsigned-char -finline  

#CCOMFLAGS += -fno-common -fno-builtin

#CCOMFLAGS += -Wno-sign-compare -Wunused -Wpointer-arith -Wcast-align -Waggregate-return -Wshadow

CCOMFLAGS += -ffast-math  -fsingle-precision-constant

#CCOMFLAGS += -falign-functions=16

#CCOMFLAGS +=  -fsched-spec-load -fmodulo-sched  -ftracer -funsafe-loop-optimizations -Wunsafe-loop-optimizations -fvariable-expansion-in-unroller

#CCOMFLAGS += -mstructure-size-boundary=32 -mthumb-interwork

#CCOMFLAGS += -fexceptions -frtti
#LDFLAGS +=  -lstdc++
	
endif

ifdef iOS
#CFLAGS += -isysroot $(BASE_DEV)
#CCOMFLAGS += --sysroot $(BASE_DEV)
CCOMFLAGS += -DIOS

###
#CCOMFLAGS += -fno-short-enums
#CCOMFLAGS += -fshort-enums  
###

ifndef iOSNOJAILBREAK
CCOMFLAGS += -DBTJOY -DJAILBREAK
endif

ifndef iOSOSX
CCOMFLAGS += -DIOS3
CCOMFLAGS += -F/home/david/Projects/iphone/toolchain/sdks/iPhoneOS3.1.2.sdk/System/Library/PrivateFrameworks
else #OSX

#CFLAGS += -isysroot /Applications/Xcode.app/Contents/Developer/Platforms/iPhoneSimulator.platform/Developer/SDKs/iPhoneSimulator6.0.sdk 

CCOMFLAGS += -F$(BASE_DEV)/System/Library/PrivateFrameworks
CCOMFLAGS += -F$(BASE_DEV)/System/Library/Frameworks
CCOMFLAGS +=  -I$(BASE_DEV)/usr/include
#CCOMFLAGS +=  -I$(BASE_DEV)/include/c++/4.2.1/armv7-apple-darwin10/

#CCOMFLAGS += -march=armv7-a -mfloat-abi=softfp -DARMV7
#CCOMFLAGS += -march=armv7s -DARMV7

ifndef iOSSIMULATOR

ifdef iOSARM64
CCOMFLAGS += -arch arm64
LDFLAGS += -arch arm64
else ifdef iOSARMV7S
CCOMFLAGS += -arch armv7s 
LDFLAGS += -arch armv7s
else 
CCOMFLAGS += -arch armv7 
LDFLAGS += -arch armv7
endif

CCOMFLAGS += -miphoneos-version-min=5.0

#LDFLAGS  += -march=armv7s
#LDFLAGS  += -march=armv7-a

#LDFLAGS +=   -ios_version_min 5.0
#CCOMFLAGS += -x objective-c 

else

CCOMFLAGS += -arch i386 
#CCOMFLAGS +=  -mios-simulator-version-min=6.0 
CCOMFLAGS += -D__IPHONE_OS_VERSION_MIN_REQUIRED=50000 
#CCOMFLAGS += -x objective-c  -fmessage-length=0 -Wno-trigraphs -fasm-blocks -O0 -Wreturn-type -Wunused-variable -fexceptions -fvisibility=hidden -fvisibility-inlines-hidden -mmacosx-version-min=10.6 -fpascal-strings -gdwarf-2 -fobjc-legacy-dispatch -fobjc-abi-version=2

LDFLAGS += -arch i386

endif

endif 

LDFLAGS += -framework Foundation -framework CoreFoundation -framework UIKit -framework QuartzCore -framework CoreGraphics -framework AudioToolbox -framework GameKit -framework CoreBluetooth
LDFLAGS += -F$(BASE_DEV)/System/Library/Frameworks
LDFLAGS += -F$(BASE_DEV)/System/Library/PrivateFrameworks
LDFLAGS += -L$(BASE_DEV)/usr/lib
LDFLAGS += -L$(BASE_DEV)/usr/lib/system  
LDFLAGS += -lobjc -lpthread -bind_at_load
LDFLAGS += -L./lib/
ifndef iOSNOJAILBREAK
#LDFLAGS += -lBTstack 
LDFLAGS += -weak_library ./lib/libBTstack.dylib
endif
CCOMFLAGS  += -ffast-math -fsingle-precision-constant


#LDFLAGS +=  -static
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

ifdef iOS
ifndef iOSNOJAILBREAK
include $(SRC)/../iOS/objc.mak
else
#include $(SRC)/../iOS/objc_njb.mak
endif
endif

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

#$(OBJ)/build/file2str$(EXE):
#	mkdir -p $(OBJ)/build
#	cp -t $(OBJ)/build prec-build/file2str$(EXE)

#$(OBJ)/build/m68kmake$(EXE):
#	cp -t $(OBJ)/build prec-build/m68kmake$(EXE)

#$(OBJ)/build/tmsmake$(EXE):
#	cp -t $(OBJ)/build prec-build/tmsmake$(EXE)
	
#$(OBJ)/build/png2bdc$(EXE):
#	cp -t $(OBJ)/build prec-build/png2bdc$(EXE)


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
#$(VERSIONOBJ): $(DRVLIBS) $(LIBOSD) $(LIBCPU) $(LIBEMU) $(LIBSOUND) $(LIBUTIL) $(EXPAT) $(ZLIB) $(SOFTFLOAT) $(LIBOCORE) $(RESFILE)
$(VERSIONOBJ): $(DRVLIBS) $(OSDOBJS) $(CPUOBJS) $(LIBEMUOBJS) $(SOUNDOBJS) $(UTILOBJS) $(EXPATOBJS) $(ZLIBOBJS) $(SOFTFLOATOBJS) $(OSDCOREOBJS) $(RESFILE)

#$(EMULATOR): $(VERSIONOBJ) $(DRVLIBS) $(LIBOSD) $(LIBCPU) $(LIBEMU) $(LIBDASM) $(LIBSOUND) $(LIBUTIL) $(EXPAT) $(SOFTFLOAT) $(ZLIBOBJS) $(LIBOCORE) $(RESFILE)
ifdef iOSNOJAILBREAK
$(EMULATOR): $(VERSIONOBJ) $(DRVLIBS) $(OSDOBJS) $(CPUOBJS) $(LIBEMUOBJS) $(DASMOBJS) $(SOUNDOBJS) $(UTILOBJS) $(EXPATOBJS) $(SOFTFLOATOBJS) $(ZLIBOBJS) $(OSDCOREOBJS) $(RESFILE)
	@echo Archiving $@...
	$(AR) -v $(ARFLAGS) $@ $^
else
$(EMULATOR): $(VERSIONOBJ) $(DRVLIBS) $(OSDOBJS) $(CPUOBJS) $(LIBEMUOBJS) $(DASMOBJS) $(SOUNDOBJS) $(UTILOBJS) $(EXPATOBJS) $(SOFTFLOATOBJS) $(ZLIBOBJS) $(OSDCOREOBJS) $(RESFILE)
	@echo Linking $@...
	$(LD) $(LDFLAGS) $(LDFLAGSEMULATOR) $^ $(LIBS) -o $@
endif 

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
	$(CC) $(CDEFS) $(CFLAGS) -c $< -o $@

$(OBJ)/%.pp: $(SRC)/%.c | $(OSPREBUILD)
	@echo Compiling $<...
	$(CC) $(CDEFS) $(CFLAGS) -E $< -o $@

$(OBJ)/%.s: $(SRC)/%.c | $(OSPREBUILD)
	@echo Compiling $<...
	$(CC) $(CDEFS) $(CFLAGS) -S $< -o $@

$(OBJ)/%.lh: $(SRC)/%.lay $(FILE2STR)
	@echo Converting $<...
	@$(FILE2STR) $< $@ layout_$(basename $(notdir $<))

$(OBJ)/%.fh: $(SRC)/%.png $(PNG2BDC) $(FILE2STR)
	@echo Converting $<...
	@$(PNG2BDC) $< $(OBJ)/temp.bdc
	@$(FILE2STR) $(OBJ)/temp.bdc $@ font_$(basename $(notdir $<)) UINT8

$(OBJ)/%.a:
	@echo Archiving $@...
	$(RM) $@
	$(AR) -v $(ARFLAGS) $@ $^

$(OBJ)/%.o: %.m
	@echo Compiling $<...
	$(CC) $(CDEFS) $(COBJFLAGS) $(CCOMFLAGS) -c $< -o $@	

ifeq ($(TARGETOS),macosx)
$(OBJ)/%.o: $(SRC)/%.m | $(OSPREBUILD)
	@echo Objective-C compiling $<...
	$(CC) $(CDEFS) $(COBJFLAGS) $(CCOMFLAGS) -c $< -o $@
endif

