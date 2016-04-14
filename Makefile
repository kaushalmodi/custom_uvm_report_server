# UVM_VERSION     = 1p1d
UVM_VERSION     = 1p2

ifeq ($(UVM_VERSION),1p2)
	UVM_HOME = ../../..
else
	UVM_HOME = ../../../../uvm-1.1d
endif

include Makefile.master.vcs
include Makefile.master.nc

UVM_VERBOSITY =	UVM_HIGH
EXTRA_COMP_ARGS =

all:	ncall
ncall:	nccomp ncrun
vcsall:	comp run

comp:
	$(VCS) +incdir+. \
                +define+UVM_NO_DEPRECATED \
                +define+UVM_$(UVM_VERSION) \
		$(EXTRA_COMP_ARGS) \
		hello_world.sv

run:
	$(SIMV)
	$(CHECK)

nccomp:
	$(NC2) -c \
	-ida -linedebug \
	$(EXTRA_COMP_ARGS) \
	hello_world.sv

ncrun:
	$(NC2) \
	-R -nclibdirname INCA_libs \
	-input ida_probe.tcl \
	$(EXTRA_RUN_ARGS)
