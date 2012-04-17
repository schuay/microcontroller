#
# Microcontroller VL
#
# Makefile for generating the lab protocol
#
# Author: Bettina Weiss
#
# Date:         16.06.2006
#
# TU Vienna, Embedded Computing Systems Group
#
# Targets:
#	(default)	generates .dvi, .ps, .pdf files
#	protocol	generates .dvi, .ps, .pdf files
#	print		prints the title page (you need to sign it!)
#
#	help		lists all possible targets
#	clean		removes intermediate files
#

#!/bin/bash


PROJECT = Protocol

#------------------------------------------------------------------------------
protocol:
#------------------------------------------------------------------------------
	latex $(PROJECT)
	latex $(PROJECT)
	dvips -o $(PROJECT).ps $(PROJECT).dvi
	ps2pdf $(PROJECT).ps $(PROJECT).pdf


#------------------------------------------------------------------------------
print: protocol
#------------------------------------------------------------------------------
	psselect -p1 $(PROJECT).ps | lpr


#------------------------------------------------------------------------------
help:
#------------------------------------------------------------------------------
	@echo -e "\n>>> the following targets are available <<<"
	@echo -e "\t(default) \t generate .dvi, .ps, and .pdf files"
	@echo -e "\tprotocol \t generate .dvi, .ps, and .pdf files"
	@echo -e "\tprint \t\t print the title page (you need to sign it!)"
	@echo -e "\n\thelp \t\t list this text"
	@echo -e "\tclean \t\t remove generated files"

#------------------------------------------------------------------------------
clean:
#------------------------------------------------------------------------------
	rm -f $(PROJECT).aux $(PROJECT).log $(PROJECT).dvi $(PROJECT).toc \
		$(PROJECT).pdf $(PROJECT).ps

