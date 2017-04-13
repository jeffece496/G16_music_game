
`timescale 1 ns / 1 ps

	module col_detection_v1_0_M00_AXI #
(
            // Users to add parameters here
    
            // User parameters ends
            // Do not modify the parameters beyond this line
    
            // The master will start generating data from the C_M_START_DATA_VALUE value
            parameter  C_M_START_DATA_VALUE    = 32'hAA000000,
            // The master requires a target slave base address.
            // The master will initiate read and write transactions on the slave with base address specified here as a parameter.
            parameter  C_M_TARGET_SLAVE_BASE_ADDR    = 32'h81000000,
            // Width of M_AXI address bus.
            // The master generates the read and write addresses of width specified as C_M_AXI_ADDR_WIDTH.
            parameter integer C_M_AXI_ADDR_WIDTH    = 32,
            // Width of M_AXI data bus.
            // The master issues write data and accept read data where the width of the data bus is C_M_AXI_DATA_WIDTH
            parameter integer C_M_AXI_DATA_WIDTH    = 32,
            // Transaction number is the number of write
            // and read transactions the master will perform as a part of this example memory test.
            parameter integer C_M_TRANSACTIONS_NUM    = 4
        )
        (
            input wire init,
            input wire [31:0] request_color,
            output wire [31:0] pos,
            output wire [31:0] done,
            
            input wire  M_AXI_ACLK,
            // AXI active low reset signal
            input wire  M_AXI_ARESETN,
            // Master Interface Write Address Channel ports. Write address (issued by master)
            output wire [C_M_AXI_ADDR_WIDTH-1 : 0] M_AXI_AWADDR,
            // Write channel Protection type.
            // This signal indicates the privilege and security level of the transaction,
            // and whether the transaction is a data access or an instruction access.
            output wire [2 : 0] M_AXI_AWPROT,
            // Write address valid.
            // This signal indicates that the master signaling valid write address and control information.
            output wire  M_AXI_AWVALID,
            // Write address ready.
            // This signal indicates that the slave is ready to accept an address and associated control signals.
            input wire  M_AXI_AWREADY,
            // Master Interface Write Data Channel ports. Write data (issued by master)
            output wire [C_M_AXI_DATA_WIDTH-1 : 0] M_AXI_WDATA,
            // Write strobes.
            // This signal indicates which byte lanes hold valid data.
            // There is one write strobe bit for each eight bits of the write data bus.
            output wire [C_M_AXI_DATA_WIDTH/8-1 : 0] M_AXI_WSTRB,
            // Write valid. This signal indicates that valid write data and strobes are available.
            output wire  M_AXI_WVALID,
            // Write ready. This signal indicates that the slave can accept the write data.
            input wire  M_AXI_WREADY,
            // Master Interface Write Response Channel ports.
            // This signal indicates the status of the write transaction.
            input wire [1 : 0] M_AXI_BRESP,
            // Write response valid.
            // This signal indicates that the channel is signaling a valid write response
            input wire  M_AXI_BVALID,
            // Response ready. This signal indicates that the master can accept a write response.
            output wire  M_AXI_BREADY,
            // Master Interface Read Address Channel ports. Read address (issued by master)
            output wire [C_M_AXI_ADDR_WIDTH-1 : 0] M_AXI_ARADDR,
            // Protection type.
            // This signal indicates the privilege and security level of the transaction,
            // and whether the transaction is a data access or an instruction access.
            output wire [2 : 0] M_AXI_ARPROT,
            // Read address valid.
            // This signal indicates that the channel is signaling valid read address and control information.
            output wire  M_AXI_ARVALID,
            // Read address ready.
            // This signal indicates that the slave is ready to accept an address and associated control signals.
            input wire  M_AXI_ARREADY,
            // Master Interface Read Data Channel ports. Read data (issued by slave)
            input wire [C_M_AXI_DATA_WIDTH-1 : 0] M_AXI_RDATA,
            // Read response. This signal indicates the status of the read transfer.
            input wire [1 : 0] M_AXI_RRESP,
            // Read valid. This signal indicates that the channel is signaling the requicolor read data.
            input wire  M_AXI_RVALID,
            // Read ready. This signal indicates that the master can accept the read data and response information.
            output wire  M_AXI_RREADY
        );
    
          // function called clogb2 that returns an integer which has the
          // value of the ceiling of the log base 2
          function integer clogb2 (input integer bit_depth);
              begin
                  for(clogb2=0; bit_depth>0; clogb2=clogb2+1)
                      bit_depth = bit_depth >> 1;
              end
          endfunction
    
          // TRANS_NUM_BITS is the width of the index counter for
          // number of write or read transaction.
          localparam integer vx_NUM_BITS = clogb2(320-1);
          localparam integer vy_NUM_BITS = clogb2(240-1);
          localparam integer bx_NUM_BITS = clogb2(32-1);
          localparam integer by_NUM_BITS = clogb2(24-1);
    
  
          parameter [3:0] IDLE = 4'b0000, // This state initiates AXI4Lite transaction
                // after the state machine changes state to INIT_WRITE
                // when there is 0 to 1 transition on INIT_AXI_TXN
            INIT_READ = 4'b0001, // This state initializes read transaction
 
            INIT_READ_HORIZONTAL = 4'b0010,
             
            R_HORIZONTAL = 4'b0011,  
              
            INIT_RB = 4'b0100,  
                
            RB = 4'b0101, 
               
            IRR = 4'b0110,  
               
            RR = 4'b0111,  
              
            INIT_COMPLETE = 4'b1000;
                
    
          reg [3:0] mst_exec_state;
          reg [vx_NUM_BITS : 0]    write_index;
          reg [vx_NUM_BITS : 0]    read_index;
          reg [vy_NUM_BITS : 0]    lCounter;
          reg [bx_NUM_BITS : 0]    bCounter;
          reg [by_NUM_BITS : 0]    rCounter;
          // AXI4LITE signals
          //write address valid
          reg      axi_awvalid;
          //write data valid
          reg      axi_wvalid;
          //read address valid
          reg      axi_arvalid;
          //read data acceptance
          reg      axi_rready;
          //write response acceptance
          reg   axi_bready;
          //write address
          reg [C_M_AXI_ADDR_WIDTH-1 : 0]     axi_awaddr;
          //write data
          reg [C_M_AXI_DATA_WIDTH-1 : 0]     axi_wdata;
          //read addresss
          reg [C_M_AXI_ADDR_WIDTH-1 : 0]     axi_araddr;
          //Asserts when there is a write response error
          wire      write_resp_error;
          //Asserts when there is a read response error
          wire      read_resp_error;
      
          reg      start_single_write;
          
          reg   start_single_read;
          
          reg   start_sl;
   
          reg   start_sb;
    
          reg   start_sr;
      
        
          reg   writes_done;      
          reg   reads_done;
          reg   error_reg;
      
   
          reg   compare_done;
          reg   block_done;
          reg   row_done;
          reg   frame_done;

          reg   init_txn_ff;
          reg   init_txn_ff2;
          reg   init_txn_edge;
          wire  init_txn_pulse;
          reg   init_write;
          reg   init_read;
    
    
         
          assign M_AXI_AWADDR    = C_M_TARGET_SLAVE_BASE_ADDR  + axi_awaddr;
          //AXI 4 write data
          assign M_AXI_WDATA    = axi_wdata;
          assign M_AXI_AWPROT    = 3'b000;
          assign M_AXI_AWVALID    = axi_awvalid;
          //Write Data(W)
          assign M_AXI_WVALID    = axi_wvalid;

          assign M_AXI_WSTRB    = 4'b1111;
          //Write Response (B)
          assign M_AXI_BREADY    = axi_bready;
          //Read Address (AR)
          assign M_AXI_ARADDR    = C_M_TARGET_SLAVE_BASE_ADDR  + axi_araddr;
          assign M_AXI_ARVALID    = axi_arvalid;
          assign M_AXI_ARPROT    = 3'b001;
          //Read and Read Response (R)
          assign M_AXI_RREADY    = axi_rready;
          //Example design I/O
          assign TXN_DONE    = compare_done;
          assign init_txn_pulse    = (!init_txn_ff2) && init_txn_ff;
          
               reg [31 : 0] curr_raddr; 
               reg [31 : 0] data[0 : 9]; 
               reg [31 : 0] reg_pos;
               reg [31 : 0] reg_done;

			   reg   found_color;

               reg [31 : 0] blk_rgb_r;
               reg [31 : 0] blk_rgb_g;
               reg [31 : 0] blk_rgb_b;
         
               wire [31 : 0] rgb_color_r;
               wire [31 : 0] rgb_color_g;
               wire [31 : 0] rgb_color_b;
         
               assign rgb_color_r = request_color[23 : 16] * 100;
               assign rgb_color_g = request_color[15 :  8] * 100;
               assign rgb_color_b = request_color[ 7 :  0] * 100;
          assign pos = reg_pos;
          assign done = reg_done;
    
          //Generate a pulse to initiate AXI transaction.
          always @ ( posedge M_AXI_ACLK )
            begin
              // Initiates AXI transaction delay
              if ( M_AXI_ARESETN == 0 )
                begin
                  init_txn_ff <= 1'b0;
                  init_txn_ff2 <= 1'b0;
                end
              else
                begin
                  init_txn_ff <= init;
                  init_txn_ff2 <= init_txn_ff;
                end
            end
    
    
          always @ ( posedge M_AXI_ACLK )
            begin
              //Only VALID signals must be deasserted during reset per AXI spec
              //Consider inverting then registering active-low reset for higher fmax
              if ( M_AXI_ARESETN == 0 || init_txn_pulse == 1'b1 )
                begin
                  axi_awvalid <= 1'b0;
                end
              else if ( init_write )
                begin
                  axi_awvalid <= 1'b0;
                end
              //Signal a new address/data command is available by user logic
              else
                begin
                  if ( start_single_write )
                    begin
                      axi_awvalid <= 1'b1;
                    end
                  //Address accepted by interconnect/slave (issue of M_AXI_AWREADY by slave)
                  else if ( M_AXI_AWREADY && axi_awvalid )
                    begin
                      axi_awvalid <= 1'b0;
                    end
                end
            end
    
    
          always @ ( posedge M_AXI_ACLK )
            begin
              if ( M_AXI_ARESETN == 0 || init_txn_pulse == 1'b1 )
                begin
                  write_index <= 0;
                end
              else if ( init_write )
                begin
                  write_index <= 0;
                end
              // Signals a new write address/ write data is
              // available by user logic
              else if ( start_single_write )
                begin
                  write_index <= write_index + 1;
                end
            end
    
    
          always @ ( posedge M_AXI_ACLK )
            begin
              if ( M_AXI_ARESETN == 0 || init_txn_pulse == 1'b1 )
                begin
                  axi_wvalid <= 1'b0;
                end
              else if ( init_write )
                begin
                  axi_wvalid <= 1'b0;
                end
              //Signal a new address/data command is available by user logic
              else if ( start_single_write )
                begin
                  axi_wvalid <= 1'b1;
                end
              //Data accepted by interconnect/slave (issue of M_AXI_WREADY by slave)
              else if ( M_AXI_WREADY && axi_wvalid )
                begin
                  axi_wvalid <= 1'b0;
                end
            end
    
    
          always @ ( posedge M_AXI_ACLK )
            begin
              if ( M_AXI_ARESETN == 0 || init_txn_pulse == 1'b1 )
                begin
                  axi_bready <= 1'b0;
                end
              else if ( init_write )
                begin
                  axi_bready <= 1'b0;
                end
              // accept/acknowledge bresp with axi_bready by the master
              // when M_AXI_BVALID is asserted by slave
              else if ( M_AXI_BVALID && ~axi_bready )
                begin
                  axi_bready <= 1'b1;
                end
              // deassert after one clock cycle
              else if ( axi_bready )
                begin
                  axi_bready <= 1'b0;
                end
              // retain the previous value
              else
                axi_bready <= axi_bready;
            end
    
          //Flag write errors
          assign write_resp_error = (axi_bready & M_AXI_BVALID & M_AXI_BRESP[1]);
    
    
        //----------------------------
        //Read Address Channel
        //----------------------------
    
          always @ ( posedge M_AXI_ACLK )
            begin
              if ( M_AXI_ARESETN == 0 || init_txn_pulse == 1'b1 )
                begin
                  rCounter <= 0;
                end
              // Signals a new read address is
              // available by user logic
              else if ( start_sr )
                begin
                  rCounter <= rCounter + 1;
                end
            end
    

          always @ ( posedge M_AXI_ACLK )
            begin
              if ( M_AXI_ARESETN == 0 || init_txn_pulse == 1'b1 )
                begin
                  bCounter <= 0;
                end
              else if ( start_sr )
                begin
                  bCounter <= 0;
                end
              // Signals a new read address is
              // available by user logic
              else if ( start_sb )
                begin
                  bCounter <= bCounter + 1;
                end
            end
    

          always @ ( posedge M_AXI_ACLK )
            begin
              if ( M_AXI_ARESETN == 0 || init_txn_pulse == 1'b1 )
                begin
                  lCounter <= 0;
                end
              else if ( start_sb )
                begin
                  lCounter <= 0;
                end
              // Signals a new read address is
              // available by user logic
              else if ( start_sl )
                begin
                  lCounter <= lCounter + 1;
                end
            end
    

          always @ ( posedge M_AXI_ACLK )
            begin
              if ( M_AXI_ARESETN == 0 || init_txn_pulse == 1'b1 )
                begin
                  read_index <= 0;
                end
              else if ( init_read )
                begin
                  read_index <= 0;
                end
              // Signals a new read address is
              // available by user logic
              else if ( start_single_read )
                begin
                  read_index <= read_index + 1;
                end
            end
    
    
          always @ ( posedge M_AXI_ACLK )
            begin
              if ( M_AXI_ARESETN == 0 || init_txn_pulse == 1'b1 )
                begin
                  axi_arvalid <= 1'b0;
                end
              else if ( init_read )
                begin
                  axi_arvalid <= 1'b0;
                end
              //Signal a new read address command is available by user logic
              else if ( start_single_read )
                begin
                  axi_arvalid <= 1'b1;
                end
              //RAddress accepted by interconnect/slave (issue of M_AXI_ARREADY by slave)
              else if ( M_AXI_ARREADY && axi_arvalid )
                begin
                  axi_arvalid <= 1'b0;
                end
              // retain the previous value
            end
    
       
          always @ ( posedge M_AXI_ACLK )
            begin
              if ( M_AXI_ARESETN == 0 || init_txn_pulse == 1'b1 )
                begin
                  axi_rready <= 1'b0;
                end
              else if ( init_read )
                begin
                  axi_rready <= 1'b0;
                end
              // accept/acknowledge rdata/rresp with axi_rready by the master
              // when M_AXI_RVALID is asserted by slave
              else if ( M_AXI_RVALID && ~axi_rready )
                begin
                  axi_rready <= 1'b1;
                end
              // deassert after one clock cycle
              else if ( axi_rready )
                begin
                  axi_rready <= 1'b0;
                end
              // retain the previous value
            end
    
          //Flag write errors
          assign read_resp_error = (axi_rready & M_AXI_RVALID & M_AXI_RRESP[1]);

    
          always @ ( posedge M_AXI_ACLK )
            begin
              if ( M_AXI_ARESETN == 0 || init_txn_pulse == 1'b1 )
                begin
                  axi_awaddr <= 0;
                end
 
              // Signals a new write address/ write data is
              // available by user logic
              else if ( M_AXI_AWREADY && axi_awvalid )
                begin
                  axi_awaddr <= axi_awaddr + 32'h00000004;
                end
            end
    
    
          always @ ( posedge M_AXI_ACLK )
            begin
              if ( M_AXI_ARESETN == 0 || init_txn_pulse == 1'b1 )
                begin
                  axi_wdata <= C_M_START_DATA_VALUE;
                end
              else if ( init_write )
                begin
                  axi_wdata <= data[0];
                end
       
              else if ( M_AXI_WREADY && axi_wvalid )
                begin
                  axi_wdata <= data[write_index];
                end
            end
    

          always @ ( posedge M_AXI_ACLK )
            begin
              if ( M_AXI_ARESETN == 0  || init_txn_pulse == 1'b1 )
                begin
                  axi_araddr <= 0;
                end
              else if ( init_read )
                begin
                  axi_araddr <= curr_raddr;
                end
  
              else if ( M_AXI_ARREADY && axi_arvalid )
                begin
                  axi_araddr <= axi_araddr + 32'h00000004;
                end
            end
    
          always @ ( posedge M_AXI_ACLK )
            begin
              if ( M_AXI_ARESETN == 1'b0 )
                begin
                  mst_exec_state <= IDLE;
    
                  start_sl <= 1'b0;
                  compare_done <= 1'b0;
    
                  curr_raddr <= 32'h00000000;
    
                  found_color <= 1'b0;
                  reg_done <= 0;
               end
              else
                begin
                  case ( mst_exec_state )
    
                    IDLE:
                     
                      if ( init_txn_pulse == 1'b1 )
                        begin
                          start_sl <= 1'b0;
                          compare_done <= 1'b0;
							 found_color <= 1'b0;
                          reg_done <= 0;
                          curr_raddr <= 32'h00000000;
    
                          mst_exec_state <= IRR;
                        end
                      else
                        begin
                          mst_exec_state  <= IDLE;
                        end
    
                    IRR:
                      begin
                        start_sr <= 1'b1;
                        mst_exec_state <= RR;
                      end
    
                    RR:
                      begin
                        start_sr <= 1'b0;
                        mst_exec_state <= INIT_RB;
                      end
    
                    INIT_RB:
                      begin
                        start_sb <= 1'b1;
                        mst_exec_state <= RB;
                      end
    
                    RB:
                      begin
                        start_sb <= 1'b0;
                        mst_exec_state <= INIT_READ_HORIZONTAL;
                      end
    
                    INIT_READ_HORIZONTAL:
                      begin
                     
                
                        start_sl <= 1'b1;
                        mst_exec_state <= R_HORIZONTAL;
    
                        start_single_write <= 1'b0;

                        start_single_read <= 1'b0;
 
                        init_write <= 1'b0;
                        init_read <= 1'b0;
                      end
                      
                    R_HORIZONTAL:
                      begin
                        start_sl <= 1'b0;
                        mst_exec_state <= INIT_READ;
                      end
    
                    INIT_READ:
                      begin
                        start_single_read <= 1'b0;

                        if ( init_read == 0 )
                          begin
                            init_read <= 1'b1;
                            mst_exec_state <= INIT_READ;
                          end
                        else
                          begin
                            init_read <= 1'b0;
                            mst_exec_state <= INIT_COMPLETE;
                          end
                      end
    
    
                    INIT_COMPLETE:
                      begin
                        if ( block_done )
                          begin

                            if ( !found_color && blk_rgb_r   > rgb_color_r && blk_rgb_g < rgb_color_g && blk_rgb_b  < rgb_color_b )
                              begin
                                found_color <= 1'b1;
                                reg_pos[31 : 16] <= ((rCounter - 1) * 10 + reg_pos[31 : 16])/2;
                                reg_pos[15 :  0] <= ((bCounter - 1) * 10 + reg_pos[15 :  0])/2 ;

                              end
                          end
    
                        if ( frame_done )
                          begin
                            reg_done[0 : 0] <= 1'b1;
                            mst_exec_state <= IDLE;
                          end
                        else if ( row_done )
                          begin
                            mst_exec_state <= IRR;
                          end
                        else if ( block_done )
                          begin
                            mst_exec_state <= INIT_RB;
                          end
                        else
                          begin
                            mst_exec_state <= INIT_READ_HORIZONTAL;
                          end
                      end
                    default :
                      begin
                        mst_exec_state <= IDLE;
                      end
                  endcase
                end
            end 
    
    
          always @ ( posedge M_AXI_ACLK )
            begin
              if ( M_AXI_ARESETN == 0 || init_txn_pulse == 1'b1 )
                begin
                  block_done <= 1'b0;
                end
              else if ( start_sb )
                begin
                  block_done <= 1'b0;
                end
             
              else if ( (lCounter == 10) && writes_done )
                begin
                  block_done <= 1'b1;
                end
              else
                begin
                  block_done <= block_done;
                end
            end
    
          always @ ( posedge M_AXI_ACLK )
            begin
              if ( M_AXI_ARESETN == 0 || init_txn_pulse == 1'b1 )
                begin
                  row_done <= 1'b0;
                end
              else if ( start_sr )
                begin
                  row_done <= 1'b0;
                end
             
              else if ( (bCounter == 32) &&
                        (lCounter  == 10) &&
                        writes_done )
                begin
                  row_done <= 1'b1;
                end
              else
                begin
                  row_done <= row_done;
                end
            end
    
          always @ ( posedge M_AXI_ACLK )
            begin
              if ( M_AXI_ARESETN == 0 || init_txn_pulse == 1'b1 )
                begin
                  frame_done <= 1'b0;
                end

              else if ( (rCounter   == 24) &&
                        (bCounter == 32) &&
                        (lCounter  == 10) &&
                        writes_done )
                begin
                  frame_done <= 1'b1;
                end
              else
                begin
                  frame_done <= frame_done;
                end
            end
    
          always @ ( posedge M_AXI_ACLK )
            begin
              if ( M_AXI_ARESETN == 0 || init_txn_pulse == 1'b1 )
                begin
                end
          
              else if ( !reads_done && M_AXI_RVALID && axi_rready )
                begin
                  data[ read_index - 1 ] <= M_AXI_RDATA;
                end
              else
                begin
         
                  data[ read_index - 1 ] <= data[ read_index - 1 ];
                end
            end
    
          always @ ( posedge M_AXI_ACLK )
            begin
              if ( M_AXI_ARESETN == 0 || init_txn_pulse == 1'b1 )
                begin
                  blk_rgb_r   <= 0;
                  blk_rgb_g <= 0;
                  blk_rgb_b  <= 0;
                end
              else if ( start_sb )
                begin
                  blk_rgb_r   <= 0;
                  blk_rgb_g <= 0;
                  blk_rgb_b  <= 0;
                end
             
              else if ( !reads_done && M_AXI_RVALID && axi_rready )
                begin
                  blk_rgb_r   <= blk_rgb_r   + M_AXI_RDATA[23 : 16];
                  blk_rgb_g <= blk_rgb_g + M_AXI_RDATA[15 :  8];
                  blk_rgb_b  <= blk_rgb_b  + M_AXI_RDATA[ 7 :  0];
                end
              else
                begin
                  blk_rgb_r   <= blk_rgb_r;
                  blk_rgb_g <= blk_rgb_g;
                  blk_rgb_b  <= blk_rgb_b;
                end
            end
    
   
   
          always @ ( posedge M_AXI_ACLK )
            begin
              if ( M_AXI_ARESETN == 0  || init_txn_pulse == 1'b1 )
                error_reg <= 1'b0;
    
              else if ( write_resp_error || read_resp_error )
                error_reg <= 1'b1;
              else
                error_reg <= error_reg;
            end
    
    
        endmodule