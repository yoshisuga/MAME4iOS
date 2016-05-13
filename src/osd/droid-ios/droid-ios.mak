MYOSDSRC = $(SRC)/osd/$(OSD)
MYOSDOBJ = $(OBJ)/osd/$(OSD)

OBJDIRS += $(MYOSDOBJ)

#-------------------------------------------------
# OSD core library
#-------------------------------------------------

OSDCOREOBJS = \
	$(MYOSDOBJ)/osddir.o	\
	$(MYOSDOBJ)/osdfile.o  	\
	$(MYOSDOBJ)/osdos.o	\
	$(MYOSDOBJ)/osdsync.o     \
	$(MYOSDOBJ)/osdwork.o	

OSDOBJS =  $(MYOSDOBJ)/osdmain.o \
	$(MYOSDOBJ)/osdinput.o \
	$(MYOSDOBJ)/osdsound.o \
	$(MYOSDOBJ)/osdvideo.o \
	$(MYOSDOBJ)/netplay.o \
	$(MYOSDOBJ)/skt_netplay.o \
	
ifdef ANDROID

OSDOBJS += \
	$(MYOSDOBJ)/osd-droid.o
	
DEFS += -D_BSD_SETJMP_H	  
endif

ifdef iOS

OSDOBJS += $(MYOSDOBJ)/osd-ios.o

ifndef iOSNOJAILBREAK
OSDOBJS += $(MYOSDOBJ)/wiimote.o
OSDOBJS += $(MYOSDOBJ)/sixaxis.o
OSDOBJS += $(MYOSDOBJ)/bt_joy.o
endif
	
endif


$(LIBOCORE): $(OSDCOREOBJS)
$(LIBOSD): $(OSDOBJS)

	
