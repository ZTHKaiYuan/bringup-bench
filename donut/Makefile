
LOCAL_CFLAGS=
LOCAL_LIBS=
LOCAL_OBJS=donut.o

PROG=donut

include ../Makefile

test: $(TARGET_EXE)
	-$(TARGET_SIM) ./$(TARGET_EXE) > FOO 
	$(TARGET_DIFF) FOO donut.$(TARGET_REFEXT)
	rm -f FOO

