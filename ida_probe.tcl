# Time-stamp: <2016-04-12 14:10:11 kmodi>

# http://cad.analog.com/adsim-feature-focus#Cadence_Indago_Debug_Analyzer_IDA

# set ida_log_objects ""
# # setenv IDA_LOG_OBJECTS "" - Enables recording of links to dynamic objects in messages.
# if {[info exists env(IDA_LOG_OBJECTS)]} {
#     set ida_log_objects " -log_objects"
# }
# ida_probe -log $ida_log_objects

set default_flow_options " -log -log_objects -ignore_sv_files=\"*coverage*\" "

# setenv IDA_REC_PATH "" - Files location to record - should be setenv IDA_REC_PATH "*vr_ad* *ahb*"
set ida_rec_path ""
if {[info exists env(IDA_REC_PATH)]} {
    set default_flow_options " -sv_files=\"$::env(IDA_REC_PATH)\" "
}

# setenv IDA_EXTRA_OPTS "" - Extra options to add to the ida_probe -sv_flow command (like -include_build_phase)
set ida_extra_options ""
if {[info exists env(IDA_EXTRA_OPTS)]} {
    set ida_extra_options " $::env(IDA_EXTRA_OPTS) "
}

# setenv IDA_REC_HDL "" - Record SV module information to the database
set ida_rec_hdl_options ""
if {[info exists env(IDA_REC_HDL)]} {
    set ida_rec_hdl_options "-sv_modules -sv_files=\"*.sv *.v *.tv\""
}

# setenv IDA_REC_START_TIME "" - To start recording from a specific time (should be with time units - e.g 430us)
# setenv IDA_REC_END_TIME ""   - To stop recording at a specific time (should be with time units - e.g 860000ns)
set ida_start_time ""
set ida_end_time ""
if {[info exists env(IDA_REC_START_TIME)]} {
    set ida_start_time "-start_time=$::env(IDA_REC_START_TIME)"
}
if {[info exists env(IDA_REC_END_TIME)]} {
    set ida_end_time "-end_time=$::env(IDA_REC_END_TIME)"
}

ida_probe -sv_flow $default_flow_options $ida_rec_hdl_options $ida_start_time $ida_end_time $ida_extra_options
ida_probe -wave -wave_probe_args="top -depth all"
# ida_probe -statement -wave -wave_probe_args="top -depth all"

# # Create a report that profiles the data recorded during simulation.
# ida_report

run
exit

# Thu Apr 07 17:57:37 EDT 2016 - kmodi
# It is very important to have -include_build_phase on the same line as -sv_flow,
# otherwise the simulation flow during the build_phase will not be recorded.


# # Older config tested to work
# ida_probe -sv_flow -include_build_phase -log -log_objects
# ida_probe -wave -wave_probe_args="top -depth all"
# ida_probe –ignore_sv_files="*coverage*"
# run
# exit
# #
