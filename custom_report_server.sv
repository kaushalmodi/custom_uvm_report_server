// Time-stamp: <2016-04-14 11:53:42 kmodi>

//------------------------------------------------------------------------------
// File Name    : custom_report_server.sv
// Author       : Kaushal.Modi@analog.com
// Description  : Custom format the uvm_info messages
//                * Use the following at command line to customize the report
//                  server
//                  - +UVM_REPORT_NOCOLOR - Do not color format the messages.
//                  - +UVM_REPORT_NOMSGWRAP - Do not wrap long messages.
//                  - +UVM_REPORT_TRACEBACK=NONE - Do not print the traceback info
//                                     such class name, file name, line number.
//                  - +UVM_REPORT_TRACEBACK=ALL - Always print the traceback info.
//                    Note: Traceback info will not be shown by default for
//                          UVM_LOW and UVM_MEDIUM verbosity level if neither of
//                          above two traceback info command line args are used.
//                * Auto wrap the messages and traceback infos.
//                * If the last character of the ID field of an uvm_info is '*',
//                  that message display will emulate a $display,
//                   - Severity tag, time stamp, id and traceback info will not
//                     be printed.
//                   - Message will not be auto-wrapped.
//                   - '*' will be removed from the ID string and the msg id
//                     counter for this modified string will be incremented.
//                     If the user entered ID as "RXQEC_TABLE*", the id counter
//                     for "RXQEC_TABLE" will be incremented.
//                * If the background color of the terminal is white or a light
//                  color, set the environment variable TERM_BG_LIGHT to 1 before
//                  running the sims. If that value is 0 or if that variable is
//                  not set, a dark background terminal will be assumed.
//------------------------------------------------------------------------------

import "DPI-C" function string getenv(input string env_var);

class custom_report_server extends
`ifndef UVM_1p1d
  uvm_default_report_server;
`else
   uvm_report_server;
`endif

   uvm_cmdline_processor clp;
   string clp_uvm_args[$];

   // identation size = 11(%11s) + 1 space + 1("@") + 7(%7t) + 2("ns") +
   //                   2 spaces (%2s) + 2(extra indentation) = 26
   parameter INDENT                          = 26;
   parameter MAX_MSG_CHARS_PER_LINE          = 75 - INDENT;
   // Do not wrap the message is it takes more than 20 lines to do so
   parameter MAX_MSG_LEN_FOR_WRAP            = 20*MAX_MSG_CHARS_PER_LINE;
   parameter NUM_CONSEC_DASH_TO_DETECT_TABLE = 15;

   typedef enum {BLACK    , GRAY,GREY , UBLACK,
                 RED      , BRED      , URED,
                 GREEN    , BGREEN    , UGREEN,
                 YELLOW   , BYELLOW   , UYELLOW,
                 BLUE     , BBLUE     , UBLUE,
                 MAGENTA  , BMAGENTA  , UMAGENTA,
                 CYAN     , BCYAN     , UCYAN,
                 WHITE    , BWHITE    , UWHITE,
                 NOCHANGE , BOLD      , ULINE} color_t;

   string fg_format[color_t] = '{BLACK    : "\033[0;30%s\033[0m",
                                 GRAY     : "\033[1;30%s\033[0m",
                                 GREY     : "\033[1;30%s\033[0m",
                                 UBLACK   : "\033[4;30%s\033[0m",
                                 RED      : "\033[0;31%s\033[0m",
                                 BRED     : "\033[1;31%s\033[0m",
                                 URED     : "\033[4;31%s\033[0m",
                                 GREEN    : "\033[0;32%s\033[0m",
                                 BGREEN   : "\033[1;32%s\033[0m",
                                 UGREEN   : "\033[4;32%s\033[0m",
                                 YELLOW   : "\033[0;33%s\033[0m",
                                 BYELLOW  : "\033[1;33%s\033[0m",
                                 UYELLOW  : "\033[4;33%s\033[0m",
                                 BLUE     : "\033[0;34%s\033[0m",
                                 BBLUE    : "\033[1;34%s\033[0m",
                                 UBLUE    : "\033[4;34%s\033[0m",
                                 MAGENTA  : "\033[0;35%s\033[0m",
                                 BMAGENTA : "\033[1;35%s\033[0m",
                                 UMAGENTA : "\033[4;35%s\033[0m",
                                 CYAN     : "\033[0;36%s\033[0m",
                                 BCYAN    : "\033[1;36%s\033[0m",
                                 UCYAN    : "\033[4;36%s\033[0m",
                                 WHITE    : "\033[0;37%s\033[0m",
                                 BWHITE   : "\033[1;37%s\033[0m",
                                 UWHITE   : "\033[4;37%s\033[0m",
                                 NOCHANGE : "\033[0%s\033[0m",
                                 BOLD     : "\033[1%s\033[0m",
                                 ULINE    : "\033[4%s\033[0m"};

   string bg_format[color_t] = '{BLACK    : ";40m%s",
                                 RED      : ";41m%s",
                                 GREEN    : ";42m%s",
                                 YELLOW   : ";43m%s",
                                 BLUE     : ";44m%s",
                                 MAGENTA  : ";45m%s",
                                 CYAN     : ";46m%s",
                                 WHITE    : ";47m%s",
                                 NOCHANGE : "m%s"};

   color_t c_uvm_info[2];
   color_t c_uvm_warning[2];
   color_t c_uvm_error[2];
   color_t c_uvm_fatal[2];
   color_t c_time[2];
   color_t c_message[2];
   color_t c_id[2];
   color_t c_tracebackinfo[2];

   bit uvm_report_nocolor;
   bit uvm_report_nomsgwrap;

   typedef enum bit [1:0] { UVM_REPORT_TRACEBACK_NONE,
                            UVM_REPORT_TRACEBACK_HIGHPLUS,
                            UVM_REPORT_TRACEBACK_ALL } uvm_report_traceback_e;
   uvm_report_traceback_e uvm_report_traceback;

`ifndef UVM_1p1d
   function new(string name = "custom_report_server");
      super.new(name);
`else
      function new();
         super.new();
`endif
         clp = uvm_cmdline_processor::get_inst();

         if (clp.get_arg_matches("+UVM_REPORT_NOCOLOR", clp_uvm_args)) begin
            uvm_report_nocolor = 1;
         end else begin
            uvm_report_nocolor = 0;
         end

         if (clp.get_arg_matches("+UVM_REPORT_NOMSGWRAP", clp_uvm_args)) begin
            uvm_report_nomsgwrap = 1;
         end else begin
            uvm_report_nomsgwrap = 0;
         end

         if (clp.get_arg_matches("+UVM_REPORT_TRACEBACK=NONE", clp_uvm_args)) begin
            uvm_report_traceback = UVM_REPORT_TRACEBACK_NONE;
         end else if (clp.get_arg_matches("+UVM_REPORT_TRACEBACK=ALL", clp_uvm_args)) begin
            uvm_report_traceback = UVM_REPORT_TRACEBACK_ALL;
         end else begin
            uvm_report_traceback = UVM_REPORT_TRACEBACK_HIGHPLUS;
         end

         if ( getenv("TERM_BG_LIGHT") == "1" ) begin
            c_uvm_info       = {GREY     ,NOCHANGE};
            c_uvm_warning    = {BLACK    ,YELLOW};
            c_uvm_error      = {WHITE    ,RED};
            c_uvm_fatal      = {BLACK    ,RED};
            c_time           = {BLUE     ,NOCHANGE};
            c_message        = {NOCHANGE ,NOCHANGE};
            c_id             = {BLUE     ,NOCHANGE};
            c_tracebackinfo  = {GREY     ,NOCHANGE};
         end else begin
            c_uvm_info       = {GREY     ,NOCHANGE};
            c_uvm_warning    = {BLACK    ,YELLOW};
            c_uvm_error      = {WHITE    ,RED};
            c_uvm_fatal      = {BLACK    ,RED};
            c_time           = {CYAN     ,NOCHANGE};
            c_message        = {NOCHANGE ,NOCHANGE};
            c_id             = {CYAN     ,NOCHANGE};
            c_tracebackinfo  = {GREY     ,NOCHANGE};
         end
      endfunction // new

`ifndef UVM_1p1d
      virtual function string compose_report_message (uvm_report_message report_message,
                                                      string report_object_name = "");
         uvm_severity l_severity;
         uvm_verbosity l_verbosity;
         uvm_report_message_element_container el_container;
         uvm_report_handler l_report_handler;
         string message  = "";
         string filename = "";
         string line     = "";
         string id       = "";
`else
         virtual function string compose_message
           ( uvm_severity severity,
             string name,
             string id,
             string message,
             string filename,
             int line );
            // Do nothing
            return "";
         endfunction // compose_message

         virtual function void process_report
           ( uvm_severity severity,
             string name,
             string id,
             string message,
             uvm_action action,
             UVM_FILE file,
             string filename,
             int line,
             string composed_message, // this input is provided by compose_message
             // function but we are not using that function
             int verbosity_level,
             uvm_report_object client );

            uvm_severity_type severity_type = uvm_severity_type'( severity );
            string report_object_name       = "";
            string compose_report_message   = "";
`endif // !`ifndef UVM_1p1d

            string sev_string;
            string context_str;
            string verbosity_str;
            string prefix;

            // Declare function-internal vars
            string format_str                = "";

            string filename_nopath           = "";
            bit    add_newline               = 0;
            bit    emulate_dollardisplay     = 0;
            string indentation_str           = {INDENT{" "}};

            int    dash_cnt                  = 0;
            bit    table_print_detected      = 0;

            string severity_str              = "";
            string time_str                  = "";
            string message_str               = "";
            string filename_str              = "";
            string tracebackinfo_str         = "";

            string severity_str_fmtd         = "";
            string time_str_fmtd             = "";
            string message_str_fmtd          = "";
            string id_str_fmtd               = "";
            string tracebackinfo_str_fmtd    = "";

            string my_composed_message       = "";
            string my_composed_message_fmtd  = "";

            begin

`ifndef UVM_1p1d
               if (report_object_name == "") begin
                  l_report_handler = report_message.get_report_handler();
                  report_object_name = l_report_handler.get_full_name();
               end
`else
               report_object_name  = name;
`endif

               // --------------------------------------------------------------------
               // SEVERITY
`ifndef UVM_1p1d
               l_severity = report_message.get_severity();
               sev_string = l_severity.name();
`else
               sev_string = severity_type.name();
`endif

`ifndef UVM_1p1d
               id = report_message.get_id();
`endif

               if (sev_string=="UVM_INFO") begin
                  format_str        = $sformatf(fg_format[c_uvm_info[0]],
                                                bg_format[c_uvm_info[1]]);
                  severity_str      = "   UVM_INFO";
                  severity_str_fmtd = $sformatf({"   ", format_str}, "UVM_INFO");
                  // Emulate $display if the last char of the uvm_info ID field is '*'
                  if (id[id.len()-1]=="*") begin
                     emulate_dollardisplay = 1;
                     // Remove that last '*' character from the ID string
                     id = id.substr(0, id.len()-2);
                  end // if (id[id.len()-1]=="*")
               end else if (sev_string=="UVM_WARNING") begin
                  format_str        = $sformatf(fg_format[c_uvm_warning[0]],
                                                bg_format[c_uvm_warning[1]]);
                  severity_str      = "UVM_WARNING";
                  severity_str_fmtd = $sformatf(format_str, "UVM_WARNING");
               end else if (sev_string=="UVM_ERROR") begin
                  format_str        = $sformatf(fg_format[c_uvm_error[0]],
                                                bg_format[c_uvm_error[1]]);
                  severity_str      = "  UVM_ERROR";
                  severity_str_fmtd = $sformatf({"  ", format_str}, "UVM_ERROR");
               end else if (sev_string=="UVM_FATAL") begin
                  format_str        = $sformatf(fg_format[c_uvm_fatal[0]],
                                                bg_format[c_uvm_fatal[1]]);
                  severity_str      = "  UVM_FATAL";
                  severity_str_fmtd = $sformatf({"  ", format_str}, "UVM_FATAL");
                  // The below else condition should never be executed
               end else begin
                  severity_str      = "";
                  severity_str_fmtd = "";
               end
               // end SEVERITY

               // --------------------------------------------------------------------
               // TIME
               // Note: Add the below statement in the initial block in top.sv along
               // with run_test()
               /*
                // Print the simulation time in ns by default
                $timeformat(-9, 0, "", 11);  // units, precision, suffix, min field width
                */
               format_str    = $sformatf(fg_format[c_time[0]],
                                         bg_format[c_time[1]]);
               time_str      = $sformatf("@%7tns", $time);
               time_str_fmtd = $sformatf({"@", format_str, "ns"}, $sformatf("%7t", $time));
               // end TIME

               // --------------------------------------------------------------------
               // MESSAGE + ID

`ifndef UVM_1p1d
               el_container = report_message.get_element_container();
               if (el_container.size() == 0)
                 message = report_message.get_message();
               else begin
                  prefix = uvm_default_printer.knobs.prefix;
                  uvm_default_printer.knobs.prefix = " +";
                  message = {report_message.get_message(), "\n", el_container.sprint()};
                  uvm_default_printer.knobs.prefix = prefix;
               end
`endif //  `ifndef UVM_1p1d

               if ( uvm_report_nomsgwrap ) begin
                  message_str = message;
               end else begin
                  // If the last character of message is a newline, replace it with
                  // space
                  if ( message[message.len()-1]=="\n" ) begin
                     message[message.len()-1] = " ";
                  end

                  // Wrap the message string if it's too long.
                  // Do not wrap the lines so that they break words (makes searching difficult)
                  // Do NOT wrap the message IF,
                  //  - message len > MAX_MSG_LEN_FOR_WRAP
                  //  - emulate_dollardisplay == 1
                  if ( report_object_name!="reporter" &&
                       message.len()<=MAX_MSG_LEN_FOR_WRAP &&
                       emulate_dollardisplay==0 ) begin
                     foreach(message[i]) begin
                        if ( message[i]=="-" ) begin
                           dash_cnt++;
                        end else begin
                           dash_cnt = 0;
                        end
                        // If more than NUM_CONSEC_DASH_TO_DETECT_TABLE consecutive
                        // dashes are detected, do not wrap the message as it could
                        // be a pre-formatted string output by the uvm_printer.
                        if ( dash_cnt > NUM_CONSEC_DASH_TO_DETECT_TABLE ) begin
                           table_print_detected = 1;
                           break;
                        end

                        // Set the "add_newline" flag so that newline is added as soon
                        // as a 'wrap-friendly' character is detected
                        if ( (i+1)%MAX_MSG_CHARS_PER_LINE==0) begin
                           add_newline = 1;
                        end

                        if (add_newline &&
                            // add newline only if the curr char is 'wrap-friendly'
                            ( message[i]==" " || message[i]=="." || message[i]==":" ||
                              message[i]=="/" || message[i]=="=" ||
                              i==(message.len()-1) )) begin
                           message_str = {message_str, message[i],"\n", indentation_str};
                           add_newline = 0;
                        end else begin
                           message_str = {message_str, message[i]};
                        end
                     end // foreach (message[i])
                  end else begin
                     message_str = message;
                  end // else: !if( message.len()<=20*MAX_MSG_CHARS_PER_LINE &&...
               end // else: !if( uvm_report_nomsgwrap )

               if ( table_print_detected ) begin
                  message_str = message;
               end

               if (emulate_dollardisplay==0) begin
                  // Append the id string to message_str
                  format_str        = $sformatf(fg_format[c_message[0]],
                                                bg_format[c_message[1]]);
                  message_str_fmtd  = $sformatf(format_str, message_str);
                  format_str        = $sformatf(fg_format[c_id[0]],
                                                bg_format[c_id[1]]);
                  id_str_fmtd       = $sformatf(format_str, id);
                  message_str       = {message_str, " :", id};
                  message_str_fmtd  = {message_str_fmtd, " :", id_str_fmtd};
               end
               // end MESSAGE + ID

               // --------------------------------------------------------------------
               // REPORT_OBJECT_NAME + FILENAME + LINE NUMBER
               // Extract just the file name, remove the preceeding path
`ifndef UVM_1p1d
               filename = report_message.get_filename();
               line     = report_message.get_line();
`endif
               for (int i=filename.len(); i>=0; i--) begin
                  if (filename[i]=="/")
                    break;
                  else
                    filename_nopath = {filename[i], filename_nopath};
               end

               if (filename=="")
                 filename_str = "";
               else
                 filename_str     = $sformatf("%s(%0d)", filename_nopath, line);

               format_str         = $sformatf(fg_format[c_tracebackinfo[0]],
                                              bg_format[c_tracebackinfo[1]]);

               // The traceback info will be indented with respect to the message_str
               if ( report_object_name=="reporter" )
                 tracebackinfo_str = {" ", report_object_name, "\n"};
               else begin
                  tracebackinfo_str = {report_object_name, ", ", filename_str};
                  if ( tracebackinfo_str.len() > MAX_MSG_CHARS_PER_LINE ) begin
                     tracebackinfo_str = {"\n", indentation_str, report_object_name, ",",
                                          "\n", indentation_str, filename_str};
                  end else begin
                     tracebackinfo_str = {"\n", indentation_str, tracebackinfo_str};
                  end
               end
               tracebackinfo_str_fmtd = $sformatf(format_str, tracebackinfo_str);
               // end REPORT_OBJECT_NAME + FILENAME + LINE NUMBER

               // --------------------------------------------------------------------
               // FINAL PRINTED MESSAGE
               if (emulate_dollardisplay) begin
                  my_composed_message      = message_str;
                  my_composed_message_fmtd = message_str;
               end else begin
                  if ( uvm_report_traceback == UVM_REPORT_TRACEBACK_NONE ) begin
                     my_composed_message = $sformatf("%5s %s  %s",
                                                     severity_str, time_str, message_str);
                     my_composed_message_fmtd = $sformatf("%5s %s  %s",
                                                          severity_str_fmtd, time_str_fmtd,
                                                          message_str_fmtd);
                  end else if ( uvm_report_traceback == UVM_REPORT_TRACEBACK_ALL ) begin
                     my_composed_message = $sformatf("%5s %s  %s%s",
                                                     severity_str, time_str, message_str,
                                                     tracebackinfo_str);
                     my_composed_message_fmtd = $sformatf("%5s %s  %s%s",
                                                          severity_str_fmtd, time_str_fmtd,
                                                          message_str_fmtd,
                                                          tracebackinfo_str_fmtd);
                  end else begin
                     // By default do not print the traceback info only for
                     // UVM_LOW and UVM_MEDIUM verbosity messages
`ifndef UVM_1p1d
                     if ($cast(l_verbosity, report_message.get_verbosity()))
                       verbosity_str = l_verbosity.name();
                     else
                       verbosity_str.itoa(report_message.get_verbosity());
`else
                     uvm_verbosity vb;
                     vb = uvm_verbosity'(verbosity_level);
                     verbosity_str = vb.name();
`endif

                     if ( verbosity_str=="UVM_LOW"
                          || verbosity_str=="UVM_MEDIUM") begin
                        my_composed_message = $sformatf("%5s %s  %s",
                                                        severity_str, time_str, message_str);
                        my_composed_message_fmtd = $sformatf("%5s %s  %s",
                                                             severity_str_fmtd, time_str_fmtd,
                                                             message_str_fmtd);
                     end else begin
                        my_composed_message = $sformatf("%5s %s  %s%s",
                                                        severity_str, time_str, message_str,
                                                        tracebackinfo_str);
                        my_composed_message_fmtd = $sformatf("%5s %s  %s%s",
                                                             severity_str_fmtd, time_str_fmtd,
                                                             message_str_fmtd,
                                                             tracebackinfo_str_fmtd);
                     end // else: !if( verbosity_str=="UVM_MEDIUM" )
                  end // else: !if( uvm_report_traceback == UVM_REPORT_TRACEBACK_ALL )
               end // else: !if(emulate_dollardisplay)
               // end FINAL PRINTED MESSAGE

               if ( uvm_report_nocolor ) begin
                  compose_report_message = my_composed_message;
               end else begin
                  compose_report_message = my_composed_message_fmtd;
               end

`ifndef UVM_1p1d
            end
         endfunction // compose_report_message
`else
         // update counts
         incr_severity_count(severity);
         incr_id_count(id);

         if(action & UVM_DISPLAY) begin
            $display("%s", compose_report_message);
         end

         // if log is set we need to send to the file but not resend to the
         // display. So, we need to mask off stdout for an mcd or we need
         // to ignore the stdout file handle for a file handle.
         if(action & UVM_LOG)
           if( (file == 0) || (file != 32'h8000_0001) ) //ignore stdout handle
             begin
                UVM_FILE tmp_file = file;
                if( (file&32'h8000_0000) == 0) //is an mcd so mask off stdout
                  begin
                     tmp_file = file & 32'hffff_fffe;
                  end
                f_display(tmp_file,my_composed_message);
             end

         if(action & UVM_EXIT) client.die();

         if(action & UVM_COUNT) begin
            if(get_max_quit_count() != 0) begin
               incr_quit_count();
               if(is_quit_count_reached()) begin
                  client.die();
               end
            end
         end

         if (action & UVM_STOP) $stop;
      end
endfunction // process_report
`endif // !`ifndef UVM_1p1d

      endclass // custom_report_server
