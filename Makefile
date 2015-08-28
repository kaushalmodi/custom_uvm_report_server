# UVM_VERSION     = 1p1d
UVM_VERSION     = 1p2

ifeq ($(UVM_VERSION),1p2)
	UVM_HOME = ../../..
else
	UVM_HOME = ../../../../uvm-1.1d
endif

include Makefile.master.vcs

UVM_VERBOSITY =	UVM_MEDIUM
EXTRA_COMP_ARGS =

all: comp run

comp:
	$(VCS) +incdir+. \
                +define+UVM_NO_DEPRECATED \
                +define+UVM_$(UVM_VERSION) \
		$(EXTRA_COMP_ARGS) \
		hello_world.sv

run:
	$(SIMV)
	$(CHECK)

# Local Variables:
# mode: makefile
# End:
