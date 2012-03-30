SRC = hci/hci.c wii/wii_bt.c wii_user/wii_user.c
OBJS = $(SRC:.c=.o)
LIB = libwiimote.a
CLEAN = $(OBJS) $(LIB)

all: $(LIB)

include ../Makefile.tmpl

$(LIB): $(OBJS)
	ar rcs $@ $(OBJS)

LDFLAGS += -static
CFLAGS += -Ihci/ -Iuart/ -Iwii/ -Iwii_user/
