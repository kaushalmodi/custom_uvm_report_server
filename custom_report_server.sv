// Time-stamp: <2015-06-18 01:17:59 kmodi>

//------------------------------------------------------------------------------
// File Name    : custom_report_server.sv
// Author       : Kaushal.Modi@analog.com
// Description  : Custom format the uvm_info messages
//                * Use the following defines to customize the report server from
//                  commandline
//                  - UVM_REPORT_NOCOLOR - Don't color format the messages
//                  - UVM_REPORT_NOTRACEBACK - Don't print the traceback info such
//                                           class name, file name, line number
//                  - UVM_REPORT_FORCETRACEBACK - Always print the traceback info
//                    Note: Traceback info will not be shown by default for
//                          UVM_MEDIUM verbosity level if neither of above two
//                          traceback info modification defines are used
//                  - UVM_REPORT_NOMSGWRAP - Don't wrap long messages
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
//------------------------------------------------------------------------------

class custom_report_server extends
`ifndef UVM_1p1d
  uvm_default_report_server;
`else
  uvm_report_server;
`endif

   // identation size = 11(%11s) + 1 space + 1("@") + 7(%7t) + 2("ns") +
   //                   2 spaces (%2s) + 2(extra indentation) = 26
   parameter INDENT = 26;
   parameter MAX_MSG_CHARS_PER_LINE = 75 - INDENT;

   typedef enum {BLACK    , GRAY,GREY , UBLACK,
                 RED      , BRED      , URED,
                 GREEN    , BGREEN    , UGREEN,
                 YELLOW   , BYELLOW   , UYELLOW,
                 BLUE     , BBLUE     , UBLUE,
                 MAGENTA  , BMAGENTA  , UMAGENTA,
                 CYAN     , BCYAN     , UCYAN,
                 WHITE    , BWHITE    , UWHITE,
                 NOCHANGE , BOLD      , ULINE} color_t;

   string       font_format[color_t] = '{BLACK    : "\033[0;30%s\033[0m",
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

   string       bg_format[color_t] = '{BLACK    : ";40m%s",
                                       RED      : ";41m%s",
                                       GREEN    : ";42m%s",
                                       YELLOW   : ";43m%s",
                                       BLUE     : ";44m%s",
                                       MAGENTA  : ";45m%s",
                                       CYAN     : ";46m%s",
                                       WHITE    : ";47m%s",
                                       NOCHANGE : "m%s"};

`ifndef UVM_1p1d
   function new(string name = "custom_report_server");
      super.new(name);
   endfunction // new
`else
   function new();
      super.new();
   endfunction // new
`endif

`ifndef UVM_1p1d
   virtual      function string compose_report_message(uvm_report_message report_message,
                                                       string report_object_name = "");

      string                                                  sev_string;
      uvm_severity l_severity;
      uvm_verbosity l_verbosity;
      string                                                  context_str;
      string                                                  verbosity_str;
      uvm_report_message_element_container el_container;
      string                                                  prefix;
      uvm_report_handler l_report_handler;

      // Declare function-internal vars
      string                                                  format_str                = "";

      string                                                  filename                  = "";
      string                                                  line                      = "";
      string                                                  filename_nopath           = "";
      bit                                                     add_newline               = 0;
      bit                                                     emulate_dollardisplay     = 0;
      string                                                  indentation_str           = {INDENT{" "}};

      string                                                  severity_str              = "";
      string                                                  time_str                  = "";
      string                                                  message                   = "";
      string                                                  message_str               = "";
      string                                                  id                        = "";
      string                                                  filename_str              = "";
      string                                                  tracebackinfo_str         = "";

      string                                                  severity_str_fmtd         = "";
      string                                                  time_str_fmtd             = "";
      string                                                  message_str_fmtd          = "";
      string                                                  id_str_fmtd               = "";
      string                                                  tracebackinfo_str_fmtd    = "";

      string                                                  my_composed_message       = "";
      string                                                  my_composed_message_fmtd  = "";

      begin

         if (report_object_name == "") begin
            l_report_handler = report_message.get_report_handler();
            report_object_name = l_report_handler.get_full_name();
         end

         // --------------------------------------------------------------------
         // SEVERITY
         l_severity                        = report_message.get_severity();
         sev_string                        = l_severity.name();

         if (sev_string=="UVM_INFO") begin
            format_str        = $sformatf(font_format[GREY], bg_format[NOCHANGE]);
            severity_str      = "   UVM_INFO";
            severity_str_fmtd = $sformatf({"   ", format_str}, "UVM_INFO");
            // Emulate $display if the last char of the uvm_info ID field is '*'
            if (id[id.len()-1]=="*") begin
               emulate_dollardisplay = 1;
               // Remove that last '*' character from the ID string
               id = id.substr(0, id.len()-2);
            end // if (id[id.len()-1]=="*")
         end else if (sev_string=="UVM_WARNING") begin
            format_str        = $sformatf(font_format[BLACK], bg_format[YELLOW]);
            severity_str      = "UVM_WARNING";
            severity_str_fmtd = $sformatf(format_str, "UVM_WARNING");
         end else if (sev_string=="UVM_ERROR") begin
            format_str        = $sformatf(font_format[WHITE], bg_format[RED]);
            severity_str      = "  UVM_ERROR";
            severity_str_fmtd = $sformatf({"  ", format_str}, "UVM_ERROR");
         end else if (sev_string=="UVM_FATAL") begin
            format_str        = $sformatf(font_format[BLACK], bg_format[RED]);
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
         format_str    = $sformatf(font_format[CYAN], bg_format[NOCHANGE]);
         time_str      = $sformatf("@%7tns", $time);
         time_str_fmtd = $sformatf({"@", format_str, "ns"}, $sformatf("%7t", $time));
         // end TIME

         // --------------------------------------------------------------------
         // MESSAGE + ID

         el_container = report_message.get_element_container();
         if (el_container.size() == 0)
           message = report_message.get_message();
         else begin
            prefix = uvm_default_printer.knobs.prefix;
            uvm_default_printer.knobs.prefix = " +";
            message = {report_message.get_message(), "\n", el_container.sprint()};
            uvm_default_printer.knobs.prefix = prefix;
         end

   `ifndef UVM_REPORT_NOMSGWRAP
         // Wrap the message string if it's too long.
         // Don't wrap the lines so that they break words (makes searching difficult)
         // Do NOT wrap the message IF,
         //  - wrapping takes more than 10 lines
         //  - emulate_dollardisplay == 1
         if ( report_object_name!="reporter" &&
              message.len()<=10*MAX_MSG_CHARS_PER_LINE &&
              emulate_dollardisplay==0 ) begin
            foreach(message[i]) begin
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
               end // else: !if(add_newline &&...

            end // foreach (message[i])
         end else begin
            message_str = message;
         end // else: !if( message.len()<=10*MAX_MSG_CHARS_PER_LINE &&...
   `endif //  `ifndef UVM_REPORT_NOMSGWRAP

         if (emulate_dollardisplay==0) begin
            // Append the id string to message_str
            format_str        = $sformatf(font_format[NOCHANGE], bg_format[NOCHANGE]);
            message_str_fmtd  = $sformatf(format_str, message_str);
            format_str        = $sformatf(font_format[CYAN], bg_format[NOCHANGE]);
            id                = report_message.get_id();
            id_str_fmtd       = $sformatf(format_str, id);
            message_str       = {message_str, " :", id};
            message_str_fmtd  = {message_str_fmtd, " :", id_str_fmtd};
         end
         // end MESSAGE + ID

         // --------------------------------------------------------------------
         // REPORT_OBJECT_NAME + FILENAME + LINE NUMBER
         // Extract just the file name, remove the preceeding path
         filename = report_message.get_filename();
         line.itoa(report_message.get_line());
         foreach(filename[i]) begin
            if (filename[i]=="/")
              filename_nopath = "";
            else
              filename_nopath = {filename_nopath, filename[i]};
         end

         if (filename=="")
           filename_str = "";
         else
           filename_str     = $sformatf("%s(%0d)", filename_nopath, line);

         format_str         = $sformatf(font_format[GREY], bg_format[NOCHANGE]);

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
   `ifdef UVM_REPORT_NOTRACEBACK
            my_composed_message = $sformatf("%5s %s  %s",
                                            severity_str, time_str, message_str);
            my_composed_message_fmtd = $sformatf("%5s %s  %s",
                                                 severity_str_fmtd, time_str_fmtd,
                                                 message_str_fmtd);
   `else
      `ifdef UVM_REPORT_FORCETRACEBACK
            my_composed_message = $sformatf("%5s %s  %s%s",
                                            severity_str, time_str, message_str,
                                            tracebackinfo_str);
            my_composed_message_fmtd = $sformatf("%5s %s  %s%s",
                                                 severity_str_fmtd, time_str_fmtd,
                                                 message_str_fmtd,
                                                 tracebackinfo_str_fmtd);
      `else
            // Only for UVM_MEDIUM verbosity messages, do not print the
            // traceback info by default.
            if ($cast(l_verbosity, report_message.get_verbosity()))
              verbosity_str = l_verbosity.name();
            else
              verbosity_str.itoa(report_message.get_verbosity());

            if ( verbosity_str=="UVM_MEDIUM" ) begin
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
      `endif // !`ifdef UVM_REPORT_FORCETRACEBACK
   `endif // !`ifdef UVM_REPORT_NOTRACEBACK
         end // else: !if(emulate_dollardisplay)
         // end FINAL PRINTED MESSAGE

   `ifdef UVM_REPORT_NOCOLOR
         compose_report_message = my_composed_message;
   `else
         compose_report_message = my_composed_message_fmtd;
   `endif
      end
   endfunction // compose_report_message
`else // !`ifndef UVM_1p1d
virtual      function string compose_message
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

      // Declare function-internal vars
      string format_str = "";

      uvm_severity_type severity_type  = uvm_severity_type'( severity );

      string filename_nopath           = "";
      bit    add_newline               = 0;
      bit    emulate_dollardisplay     = 0;
      string indentation_str           = {INDENT{" "}};

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

      uvm_verbosity vb;

      begin
         vb = uvm_verbosity'(verbosity_level);

         // --------------------------------------------------------------------
         // SEVERITY
         if (severity_type.name()=="UVM_INFO") begin
            format_str        = $sformatf(font_format[GREY], bg_format[NOCHANGE]);
            severity_str      = "   UVM_INFO";
            severity_str_fmtd = $sformatf({"   ", format_str}, "UVM_INFO");
            // Emulate $display if the last char of the uvm_info ID field is '*'
            if (id[id.len()-1]=="*") begin
               emulate_dollardisplay = 1;
               // Remove that last '*' character from the ID string
               id = id.substr(0, id.len()-2);
            end // if (id[id.len()-1]=="*")
         end else if (severity_type.name()=="UVM_WARNING") begin
            format_str        = $sformatf(font_format[BLACK], bg_format[YELLOW]);
            severity_str      = "UVM_WARNING";
            severity_str_fmtd = $sformatf(format_str, "UVM_WARNING");
         end else if (severity_type.name()=="UVM_ERROR") begin
            format_str        = $sformatf(font_format[WHITE], bg_format[RED]);
            severity_str      = "  UVM_ERROR";
            severity_str_fmtd = $sformatf({"  ", format_str}, "UVM_ERROR");
         end else if (severity_type.name()=="UVM_FATAL") begin
            format_str        = $sformatf(font_format[BLACK], bg_format[RED]);
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
         format_str    = $sformatf(font_format[CYAN], bg_format[NOCHANGE]);
         time_str      = $sformatf("@%7tns", $time);
         time_str_fmtd = $sformatf({"@", format_str, "ns"}, $sformatf("%7t", $time));
         // end TIME

         // --------------------------------------------------------------------
         // MESSAGE + ID
   `ifdef UVM_REPORT_NOMSGWRAP
         message_str = message;
   `else
         // Wrap the message string if it's too long.
         // Don't wrap the lines so that they break words (makes searching difficult)
         // Do NOT wrap the message IF,
         //  - wrapping takes more than 10 lines
         //  - emulate_dollardisplay == 1
         if ( message.len()<=10*MAX_MSG_CHARS_PER_LINE &&
              emulate_dollardisplay==0 ) begin
            foreach(message[i]) begin
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
               end // else: !if(add_newline &&...

            end // foreach (message[i])
         end else begin
            message_str = message;
         end // else: !if( message.len()<=10*MAX_MSG_CHARS_PER_LINE &&...
   `endif // !`ifdef UVM_REPORT_NOMSGWRAP

         if (emulate_dollardisplay==0) begin
            // Append the id string to message_str
            format_str       = $sformatf(font_format[NOCHANGE], bg_format[NOCHANGE]);
            message_str_fmtd = $sformatf(format_str, message_str);
            format_str       = $sformatf(font_format[CYAN], bg_format[NOCHANGE]);
            id_str_fmtd      = $sformatf(format_str, id);
            message_str      = {message_str, " :", id};
            message_str_fmtd = {message_str_fmtd, " :", id_str_fmtd};
         end
         // end MESSAGE + ID

         // --------------------------------------------------------------------
         // NAME + FILENAME + LINE NUMBER
         // Extract just the file name, remove the preceeding path
         foreach(filename[i]) begin
            if (filename[i]=="/")
              filename_nopath = "";
            else
              filename_nopath = {filename_nopath, filename[i]};
         end

         if (filename=="")
           filename_str = "";
         else
           filename_str = $sformatf("%s(%0d)", filename_nopath, line);

         format_str        = $sformatf(font_format[GREY], bg_format[NOCHANGE]);
         // The traceback info will be indented with respect to the message_str
         tracebackinfo_str = {name, ", ", filename_str};
         if ( tracebackinfo_str.len() > MAX_MSG_CHARS_PER_LINE ) begin
            tracebackinfo_str = {indentation_str, name, ",\n",
                                 indentation_str, filename_str};
         end else begin
            tracebackinfo_str = {indentation_str, tracebackinfo_str};
         end
         tracebackinfo_str_fmtd = $sformatf(format_str, tracebackinfo_str);
         // end NAME + FILENAME + LINE NUMBER

         // --------------------------------------------------------------------
         // FINAL PRINTED MESSAGE
         if (emulate_dollardisplay) begin
            my_composed_message      = message_str;
            my_composed_message_fmtd = message_str;
         end else begin
   `ifdef UVM_REPORT_NOTRACEBACK
            my_composed_message = $sformatf("%5s %s  %s",
                                            severity_str, time_str, message_str);
            my_composed_message_fmtd = $sformatf("%5s %s  %s",
                                                 severity_str_fmtd, time_str_fmtd,
                                                 message_str_fmtd);
   `else
      `ifdef UVM_REPORT_FORCETRACEBACK
            my_composed_message = $sformatf("%5s %s  %s\n%s",
                                            severity_str, time_str, message_str,
                                            tracebackinfo_str);
            my_composed_message_fmtd = $sformatf("%5s %s  %s\n%s",
                                                 severity_str_fmtd, time_str_fmtd,
                                                 message_str_fmtd,
                                                 tracebackinfo_str_fmtd);
      `else
            // Only for UVM_MEDIUM verbosity messages, do not print the
            // traceback info by default.
            if ( vb.name()=="UVM_MEDIUM" ) begin
               my_composed_message = $sformatf("%5s %s  %s",
                                               severity_str, time_str, message_str);
               my_composed_message_fmtd = $sformatf("%5s %s  %s",
                                                    severity_str_fmtd, time_str_fmtd,
                                                    message_str_fmtd);
            end else begin
               my_composed_message = $sformatf("%5s %s  %s\n%s",
                                               severity_str, time_str, message_str,
                                               tracebackinfo_str);
               my_composed_message_fmtd = $sformatf("%5s %s  %s\n%s",
                                                    severity_str_fmtd, time_str_fmtd,
                                                    message_str_fmtd,
                                                    tracebackinfo_str_fmtd);
            end // else: !if( vb.name()=="UVM_MEDIUM" )
      `endif
   `endif
         end // else: !if(emulate_dollardisplay)
         // end FINAL PRINTED MESSAGE

         // update counts
         incr_severity_count(severity);
         incr_id_count(id);

         if(action & UVM_DISPLAY) begin
   `ifdef UVM_REPORT_NOCOLOR
            $display("%s",my_composed_message);
   `else
            $display("%s",my_composed_message_fmtd);
   `endif
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
