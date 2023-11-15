`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company:Meyesemi
// Engineer: Will
//
// Create Date: 2023-11-02 20:32
// Design Name:
// Module Name:
// Project Name:
// Target Devices: Pango
// Tool Versions:
// Description:
//
// Dependencies:
//
// Revision:
// Revision 1.0 - File Created
// Additional Comments:
//
//////////////////////////////////////////////////////////////////////////////////
`define UD #1
module pattern_vg # (
    parameter                            COCLOR_DEPP=8, // number of bits per channel
    parameter                            X_BITS=13,
    parameter                            Y_BITS=13,
    parameter                            H_ACT = 12'd1280,
    parameter                            V_ACT = 12'd720
  )(
    input                                rstn,
    input                                pix_clk,
    input                                udp_clk,
    input [X_BITS-1:0]                   act_x,
    input [X_BITS-1:0]                   act_y,
    input                                vs_in,
    input                                hs_in,
    input                                de_in,
	input [31:0]                         data,
    output reg                           vs_out,
    output reg                           hs_out,
    output reg                           de_out,
    output wire [COCLOR_DEPP-1:0]         r_out,
    output wire [COCLOR_DEPP-1:0]         g_out,
    output wire [COCLOR_DEPP-1:0]         b_out,
    input                                 rec_en/*synthesis PAP_MARK_DEBUG="true"*/,
    input  [31:0]                         rec_data/*synthesis PAP_MARK_DEBUG="true"*/
  );
  reg [31:0] pix_data;
  assign r_out=pix_data[23:16];
  assign g_out=pix_data[15:8];
  assign b_out=pix_data[7:0];
  //参数定义
  parameter   CHAR_B_H = 13'd1650 ,//字符开始横坐标
              CHAR_B_V = 13'd10 ;//字符开始纵坐标

  parameter   CHAR_W   = 13'd256 ,//字符宽度
              CHAR_H   = 13'd32  ;//字符深度

  //颜色参数  RGB565格式
  parameter   BLACK    = 32'h0000,//黑色（背景色）
              GOLDEN   = 32'h0;/* 31'h00FFD700 */;//金色（字符颜色）

  //信号定义
  wire    [9:0]    char_x    ;//字符横坐标
  wire    [7:0]    char_y  /*synthesis PAP_MARK_DEBUG="1"*/  ;//字符纵坐标

  //reg     [255:0]  char [63:0]  ;

  //char_x
  assign char_x = (((act_x >= CHAR_B_H)&&(act_x < (CHAR_B_H + CHAR_W)))
                   &&((act_y >= CHAR_B_V)&&(act_y < (CHAR_B_V + CHAR_H))))
         ? (13'd255-(act_x - CHAR_B_H)) : 13'd0;
  //char_yh3
  assign char_y = (((act_x >= CHAR_B_H)&&(act_x < (CHAR_B_H + CHAR_W)))
                   &&((act_y >= CHAR_B_V)&&(act_y < (CHAR_B_V + CHAR_H))))
         ? (act_y - CHAR_B_V) : 8'd0;

  

  reg [10:0] wr_addr /*synthesis PAP_MARK_DEBUG="1"*/;
  wire [255:0]rd_data;

  always@(posedge udp_clk or negedge rstn)
  begin
    if(~rstn)
      wr_addr <= 11'd0;
    else if (rec_en==1)
      wr_addr <= wr_addr + 11'd1;
  end
  wire [255:0] char_data;

  ram_32to256 u0 (
                .wr_data(rec_data),  // input [31:0]
                .wr_addr(wr_addr),   // input [10:0]
                .wr_en(rec_en),      // input
                .wr_clk(udp_clk),    // input
                .wr_rst(~rstn),      // input
                .rd_addr(char_y),    // input [7:0]
                .rd_data(rd_data),   // output [255:0]]
                .rd_clk(pix_clk),    // input
                .rd_rst(~rstn)       // input
              );


  assign char_data = {rd_data[31:0],rd_data[63:32],rd_data[95:64],rd_data[127:96],rd_data[159:128],rd_data[191:160],rd_data[223:192],rd_data[255:224]};
  //pix_data
  always @(posedge pix_clk )
  begin
 if(((act_x >= CHAR_B_H-1)&&(act_x < (CHAR_B_H + CHAR_W-1)))
            &&((act_y >= CHAR_B_V)&&(act_y < (CHAR_B_V + CHAR_H)))
            &&(char_data[char_x] == 1'b1))
    begin
      pix_data <= GOLDEN;
    end
    else
    begin
      pix_data <= data;
    end
  end



  always @(posedge pix_clk)
  begin
    vs_out <= `UD vs_in;
    hs_out <= `UD hs_in;
    de_out <= `UD de_in;
  end


endmodule



