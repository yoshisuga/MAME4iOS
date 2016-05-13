IOSSRC = $(SRC)../iOS/
IOSOBJ = $(OBJ)/iOS

OBJDIRS += $(IOSOBJ)

OSDOBJS +=  $(IOSOBJ)/iph_main.o \
	$(IOSOBJ)/Bootstrapper.o \
	$(IOSOBJ)/ScreenView.o \
	$(IOSOBJ)/EmulatorController.o \
	$(IOSOBJ)/HelpController.o \
	$(IOSOBJ)/OptionsController.o \
	$(IOSOBJ)/ListOptionController.o \
        $(IOSOBJ)/DonateController.o \
	$(IOSOBJ)/BTJoyHelper.o \
	$(IOSOBJ)/DebugView.o \
	$(IOSOBJ)/BTDevice.o \
	$(IOSOBJ)/BTInquiryViewController.o \
	$(IOSOBJ)/LayoutData.o \
	$(IOSOBJ)/LayoutView.o \
	$(IOSOBJ)/iCadeView.o \
	$(IOSOBJ)/AnalogStick.o \
	$(IOSOBJ)/FilterOptionController.o \
	$(IOSOBJ)/InputOptionController.o \
	$(IOSOBJ)/DefaultOptionController.o \
	$(IOSOBJ)/NetplayController.o \
	$(IOSOBJ)/NetplayGameKit.o
	


