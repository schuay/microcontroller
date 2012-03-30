== GLCD Library ==

How to use it:

Include glcd.h wherever you want to use the glcd functions. Link your object files together with the library (add -lglcd to the linker command). E.g. call the linker in the following way:

avr-gcc main.o -mmcu=atmega1280 -lglcd -L. -o application.elf

Make sure that the header and library files are in the compilers and linkers search path. E.g. in the same directory as your other source files (-L. adds the current directory to the linkers library search path).
