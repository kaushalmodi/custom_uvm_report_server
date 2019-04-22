# Time-stamp: <2016-04-14 12:10:08 kmodi>

x: all

#
# Include file for NC Makefiles
#

UVM_VERBOSITY =	UVM_LOW
EXTRA_RUN_ARGS =

TEST = /usr/bin/test
N_ERRS = 0
N_FATALS = 0

ifeq ($(UVM_VERSION),1p2)
CDNS_UVM_DIR=CDNS-1.2
else
CDNS_UVM_DIR=CDNS-1.1d
endif


NC =    irun +sv +nctimescale+1ns/10ps \
        +define+UVM_NO_DEPRECATED \
        +define+UVM_$(UVM_VERSION) \
        +UVM_VERBOSITY=$(UVM_VERBOSITY)  \
        +incdir+./ +incdir+$(UVM_HOME)/src \
        -uvmnocdnsextra -uvmhome $(UVM_HOME)

# NC2 will use the version of UVM that ships with Cadence
# The Cadence UVM version is needed for Indago to run
NC2 =   irun +sv +nctimescale+1ns/10ps \
        -nclibdirname INCA_libs \
        +define+UVM_NO_DEPRECATED \
        +define+UVM_$(UVM_VERSION) \
        +UVM_VERBOSITY=$(UVM_VERBOSITY)  \
        +incdir+./ \
	-uvmhome $(CDNS_UVM_DIR)

ncclean:
	rm -rf *~ *.log INCA_libs/ ida.db/ .ida.db_safe*

# Local Variables:
# mode: makefile-gmake
# End:
