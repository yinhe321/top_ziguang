module photoshop(
    input wire clk_74,
    input wire sys_rst_n,
    input wire o_vs,
    input wire o_hs,
    input wire o_de,
    input wire  [  31:0] rd_data ,
    output wire hdmi_vs1,
    output wire hdmi_hs1,
    output wire hdmi_de1,    
    output wire [23:0]RGB_o,
/*     input wire CONTRAST_SIG,
    input wire BRIGHT_SIG, */
  /*   input wire[7:0] CONTRAST,
    input wire[7:0] BRIGHT,
   */
   input		[ 2:0]		key
  
/*    output		[ 2:0]		key_out
 */
   );


wire   [7:0] hdmi_r;
wire   [7:0] hdmi_g;
wire   [7:0] hdmi_b;
wire   [ 2:0]		key_out;
 reg [7:0] CONTRAST1;
reg [7:0] BRIGHT1;  

/*  assign pix_clk    = clk_74; */
/* assign vs_out    = o_vs;
assign hs_out    = o_hs;
assign de_out    = o_de;
assign r_out    = hdmi_r;
assign g_out    = hdmi_g;
assign b_out    = hdmi_b; */


Contrast_Prj Contrast_Prj1 (
    .Pclk(clk_74),
    .Rst(~sys_rst_n),
    .Vsync(o_vs),
    .Hsync(o_hs),
    .De(o_de),
    .RGB({rd_data[23:16],rd_data[15:8], rd_data[7:0]}),


    .Vsync_o(hdmi_vs1),
    .Hsync_o(hdmi_hs1),
    .De_o(hdmi_de1),
    .RGB_o(RGB_o),
    .CONTRAST_SIG(key_out[1]),
    .BRIGHT_SIG(key_out[2]),
    .CONTRAST(CONTRAST1),
    .BRIGHT(BRIGHT1)
    );



always@(posedge clk_74)begin
   if(!sys_rst_n)begin
	CONTRAST1<=8'd0;
	BRIGHT1<=8'd0;
   end
 else if(key_out[1])
	    CONTRAST1<=CONTRAST1+8'd6;
	else if(key_out[2]) 
	    BRIGHT1<=BRIGHT1+8'd6;
   end






 key_Module key_Module1(
	.clk(clk_74),
	.rst_n(sys_rst_n),
	.key_in(key),
	.key_out(key_out)
);  




























endmodule