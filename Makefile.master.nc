# Time-stamp: <2019-04-22 18:17:04 kmodi>

x: all

#
# Include file for NC Makefiles
#

UVM_VERBOSITY =	UVM_LOW
EXTRA_RUN_ARGS =

TEST = /usr/bin/test
N_ERRS = 0
N_FATALS = 0

NC_BIN ?= xrun

ifeq ($(UVM_VERSION),1p2)
CDNS_UVM_DIR=CDNS-1.2
else
CDNS_UVM_DIR=CDNS-1.1d
endif

_NC =   $(NC_BIN) -sv \
	+xmtimescale+1ns/10ps \
        +define+UVM_NO_DEPRECATED \
        +define+UVM_$(UVM_VERSION) \
        +UVM_VERBOSITY=$(UVM_VERBOSITY)  \
	-nowarn DSEMEL \
	-nowarn DSEM2009 \
	-nowarn RNDNOXCEL \
	-nowarn RNDXCELON \
        +incdir+./

# Use local UVM source pointed to by the env var ${UVM_HOME}.
NC =    $(_NC) \
	+incdir+$(UVM_HOME)/src \
        -uvmnocdnsextra -uvmhome $(UVM_HOME)

# Use the Cadence provided UVM source.
# Note: The Cadence UVM version is needed for Indago to run
NC2 =   $(_NC) \
	-uvmhome $(CDNS_UVM_DIR)

ncclean:
	rm -rf *~ *.log INCA_libs/ xcelium.d/ .ida.db*/ ida.db/ .ida.db_safe* *.key *.history .simvision/

# Local Variables:
# mode: makefile-gmake
# End:
