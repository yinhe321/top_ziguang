`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: Guangzhou
// Engineer: Liguozhu
// 
// Create Date: 2018/07/29 14:24:42
// Design Name: 
// Module Name: Contrast_Prj
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


module Contrast_Prj(
    input wire Pclk,
    input wire Rst,
    input wire Vsync,
    input wire Hsync,
    input wire De,
    input wire[23:0] RGB,
    output wire Vsync_o,
    output wire Hsync_o,
    output wire De_o,    
    output wire [23:0]RGB_o,
    input wire CONTRAST_SIG,
    input wire BRIGHT_SIG,
    input wire[7:0] CONTRAST,
    input wire[7:0] BRIGHT
    );


//Contrast_Core Contrast_Core(
//    .Pclk(Pclk),
//    .Rst(Rst),
//    .Vsync(Vsync),
//    .Hsync(Hsync),
//    .De(De),
//    .RGB(RGB),
//    .Vsync_o(Vsync_o),
//    .Hsync_o(Hsync_o),
//    .De_o(De_o),
//    .RGB_o(RGB_o)
//    );
    
    
constrast_ipcore constrast_ipcore(
    .Pclk(Pclk),
    .Rst(Rst),
    .Vsync(Vsync),
    .Hsync(Hsync),
    .De(De),
    .RGB(RGB),
    .CONTRAST_SIG(CONTRAST_SIG),
    .BRIGHT_SIG(BRIGHT_SIG),
    .CONTRAST(CONTRAST),
    .BRIGHT(BRIGHT),
    .Vsync_o(Vsync_o),
    .Hsync_o(Hsync_o),
    .De_o(De_o),
    .RGB_o(RGB_o)
       
    ); 
    
    
    
    
    
endmodule
