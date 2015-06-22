//----------------------------------------------------------------------
//   Copyright 2007-2010 Mentor Graphics Corporation
//   Copyright 2007-2010 Cadence Design Systems, Inc.
//   Copyright 2010-2011 Synopsys, Inc.
//   All Rights Reserved Worldwide
//
//   Licensed under the Apache License, Version 2.0 (the
//   "License"); you may not use this file except in
//   compliance with the License.  You may obtain a copy of
//   the License at
//
//       http://www.apache.org/licenses/LICENSE-2.0
//
//   Unless required by applicable law or agreed to in
//   writing, software distributed under the License is
//   distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR
//   CONDITIONS OF ANY KIND, either express or implied.  See
//   the License for the specific language governing
//   permissions and limitations under the License.
//----------------------------------------------------------------------

`include "custom_report_server.sv"

class top extends uvm_component;

   custom_report_server my_report_server;

   producer #(packet) p1;
   producer #(packet) p2;
   uvm_tlm_fifo #(packet) f;
   consumer #(packet) c;

   `uvm_component_utils(top)

   function new (string name, uvm_component parent=null);
      super.new(name,parent);

      p1 = new("producer1",this);
      p2 = new("producer2",this);
      f  = new("fifo",this);
      c  = new("consumer",this);

      p1.out.connect( c.in );
      p2.out.connect( f.blocking_put_export );
      c.out.connect( f.get_export );
   endfunction

   virtual function void build_phase(uvm_phase phase);
      begin
         // Set the custom report server to output the uvm_info
         // messages in custom format
`ifndef UVM_REPORT_DEFAULT
   `ifndef UVM_1p1d
         my_report_server  = new("my_report_server");
   `else
         my_report_server  = new();
   `endif
         uvm_report_server::set_server( my_report_server );
`endif
         super.build_phase(phase);
      end
   endfunction // build_phase

   virtual task run_phase(uvm_phase phase);
      phase.raise_objection(this);
      // uvm_top.print_topology();
      fork
         begin
            `uvm_info("TEST*", {{15{"-"}},
                                " Example of $display emulation ",
                                {15{"-"}}}, UVM_MEDIUM)
            `uvm_info("TEST_INFO", "This is a long message: Lorem ipsum dolor sit amet, consectetur adipiscing elit. Vivamus luctus, quam in fringilla blandit, lorem sem vestibulum quam, id pretium lorem justo vel neque. In quis ullamcorper tellus. Donec eget cursus ex. Suspendisse ut sodales ligula. Morbi id eros velit. Proin posuere neque urna, nec rutrum dolor semper vitae. Ut dapibus libero nisi, eu feugiat urna placerat a. Nunc blandit, sapien sit amet fringilla auctor, sapien nibh gravida urna, vel venenatis elit nulla sit amet elit. Suspendisse et diam finibus, suscipit justo eget, luctus leo.", UVM_MEDIUM)
            `uvm_info("TEST_INFO", "This is a UVM_LOW info.", UVM_LOW)
            `uvm_info("TEST_INFO", "This is a UVM_MEDIUM info.", UVM_MEDIUM)
            `uvm_info("TEST_INFO", "This is a UVM_HIGH info.", UVM_HIGH)
            `uvm_warning("TEST_WARN", "This is a warning.")
            `uvm_error("TEST_ERR", "This is an error!")
            #1ns;
            `uvm_fatal("TEST_FATAL", "This is a fatal error!")
         end
         begin
            #1us;
         end
      join
      phase.drop_objection(this);
   endtask // run_phase

endclass // top
