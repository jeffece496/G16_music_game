`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2014/05/23 16:24:31
// Design Name: 
// Module Name: ov7725_top
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


//module ov7670_top(
//input  clk25,
//input  OV7670_VSYNC,
//input  OV7670_HREF,
//input  OV7670_PCLK,
//output OV7670_XCLK,
//output OV7670_SIOC,
//inout  OV7670_SIOD,
//input [7:0] OV7670_D,

//input BTNC,
//output pwdn,
//output reset,
//output [16:0] frame_addr,
//output [15:0] frame_pixel
//);

module ov7670_top(
input clk25,
input  OV7670_VSYNC,
input  OV7670_HREF,
input  OV7670_PCLK,
output OV7670_XCLK,
output OV7670_SIOC,
inout  OV7670_SIOD,
input [7:0] OV7670_D,

output reg m_axis_tlast,
output reg m_axis_tuser,
input m_axis_tready,
output m_axis_tvalid,
output [31:0] m_axis_tdata,

input BTNC,
output pwdn,
output cam_reset,
output a_clk
); 

wire [16:0] capture_addr;
wire [15:0]  data_16;
//wire  capture_we;  
wire  config_finished;  
     
wire  resend;        
reg pre_v;
reg prev_h;

assign ena = 1;
assign pwdn = 0;
assign cam_reset = 1;
assign a_clk = !OV7670_PCLK;

assign  	OV7670_XCLK = clk25;

// The button (BTNC) is used to resend the configuration bits to the camera.
// The button is debounced with a 50 MHz clock
debounce   btn_debounce(
		.clk(clk25),
		.i(BTNC),
		.o(resend)
);
 
/* vga444   Inst_vga(
		.clk25       (clk25),
		.vga_red    (vga444_red),
		.vga_green   (vga444_green),
		.vga_blue    (vga444_blue),
		.vga_hsync   (vga_hsync),
		.vga_vsync  (vga_vsync),
		.HCnt       (),
		.VCnt       (),

		.frame_addr   (frame_addr),
		.frame_pixel  (frame_pixel)
 );*/

// BRAM using memory generator from IP catalog
// dual-port, 16 bits wide, 76800 deep 
  

 ov7670_capture capture(
 		.pclk  (OV7670_PCLK),
 		.vsync (OV7670_VSYNC),
 		.href  (OV7670_HREF),
 		.d     ( OV7670_D),
 		.addr  (capture_addr),
 		.dout( data_16),
 		.we   (m_axis_tvalid)
 	);
 
I2C_AV_Config IIC(
 		.iCLK   ( clk25),    
 		.iRST_N (! resend),    
 		.Config_Done ( config_finished),
 		.I2C_SDAT  ( OV7670_SIOD),    
 		.I2C_SCLK  ( OV7670_SIOC),
 		.LUT_INDEX (),
 		.I2C_RDATA ()
 		); 

assign m_axis_tdata[31:24] = 8'b0;
assign m_axis_tdata[23:19] = data_16[15:11];
assign m_axis_tdata[18:16] = 3'b0;
assign m_axis_tdata[15:10] = data_16[10:5];
assign m_axis_tdata[9:8] = 2'b0;
assign m_axis_tdata[7:3] = data_16[4:0];
assign m_axis_tdata[2:0] = 3'b0;


always@(posedge OV7670_PCLK) begin
    if( capture_addr==0)
        m_axis_tuser <= 1;
    else
        m_axis_tuser <= 0;
    if(capture_addr%320==319)
        m_axis_tlast <= 1;
    else 
        m_axis_tlast <= 0;
end

endmodule
