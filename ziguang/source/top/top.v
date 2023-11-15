module top(
    input                               sys_clk                    ,
    input                               sys_rst_n                  ,
	input             [6:0]             key                  ,
	//摄像头接口                       
    input                               cam_pclk                   ,//cmos 数据像素时钟
    input                               cam_vsync                  ,//cmos 场同步信号
    input                               cam_href                   ,//cmos 行同步信号
    input              [   7:0]         cam_data                   ,//cmos 数据
    output                              cam_rst_n                  ,//cmos 复位信号，低电平有效
    output                              cam_pwdn                   ,//电源休眠模式选择 0：正常模式 1：电源休眠模式
    output                              cam_scl                    ,//cmos SCCB_SCL线
    inout                               cam_sda                    ,//cmos SCCB_SDA线
	//7200接口
    input                               pixclk_in                  ,
    input                               vs_in                      ,
    input                               hs_in                      ,
    input                               de_in                      ,
    input              [   7:0]         r_in                       ,
    input              [   7:0]         g_in                       ,
    input              [   7:0]         b_in                       ,
	//配置72xx接口	
    output                              iic_tx_scl                 ,
    inout                               iic_tx_sda                 ,
    output                              iic_scl                    ,
    inout                               iic_sda                    ,
	//DDR3接口
    output                              mem_rst_n                  ,
    output                              mem_ck                     ,
    output                              mem_ck_n                   ,
    output                              mem_cke                    ,
    output                              mem_cs_n                   ,
    output                              mem_ras_n                  ,
    output                              mem_cas_n                  ,
    output                              mem_we_n                   ,
    output                              mem_odt                    ,
    output             [15-1:0]         mem_a                      ,
    output             [3-1:0]          mem_ba                     ,
    inout              [4-1:0]          mem_dqs                    ,
    inout              [4-1:0]          mem_dqs_n                  ,
    inout              [32-1:0]         mem_dq                     ,
    output             [4-1:0]          mem_dm                     ,
	//7210芯片接口
    output                              pix_clk                    ,
    output                              rstn_out                   ,
    output                              vs_out                     ,
    output                              hs_out                     ,
    output                              de_out                     ,
    output             [   7:0]         r_out                      ,
    output             [   7:0]         g_out                      ,
    output             [   7:0]         b_out                      ,
    output                            led_int                    ,
	output                             led                      ,
    //以太网接口
    input                               eth_rxc                    ,//RGMII接收数据时钟
    input                               eth_rx_ctl                 ,//RGMII输入数据有效信号
    input              [   3:0]         eth_rxd                    ,//RGMII输入数据
    output                              eth_txc                    ,//RGMII发送数据时钟    
    output                              eth_tx_ctl                 ,//RGMII输出数据有效信号
    output             [   3:0]         eth_txd                    ,//RGMII输出数据          
    output                              eth_rst_n                   //以太网芯片复位信号，低电平有效 
    );
	
//parameter define
//开发板MAC地址 00-11-22-33-44-55
    parameter                           BOARD_MAC = 48'h00_11_22_33_44_55;
//开发板IP地址 192.168.1.10
    parameter                           BOARD_IP  = {8'd192,8'd168,8'd1,8'd10}; 
//目的MAC地址 ff_ff_ff_ff_ff_ff
    parameter                           DES_MAC   = 48'hff_ff_ff_ff_ff_ff;
//目的IP地址 192.168.1.102     
    parameter                           DES_IP    = {8'd192,8'd168,8'd1,8'd102}; 

    parameter                           H_CMOS_DISP = 12'd960      ;
    parameter                           V_CMOS_DISP = 12'd540      ;
    parameter                           TOTAL_H_PIXEL = 12'd1892   ;
    parameter                           TOTAL_V_PIXEL = 12'd740    ;

//wire define
//pll
wire                                    clk_10                     ;
wire                                    clk_50                     ;
wire                                    clk_74                     ;
wire                                    clk_lock                   ;
//camera
wire                   [  31:0]         wr_data_camera             ;
wire                                    cmos_frame_vsync           ;
wire                                    cmos_frame_valid           ;
//hdmi
wire                   [  31:0]         wr_data_hdmi               ;
wire                                    scale_vs                   ;
wire                                    scale_de                   ;
//VSDMA0
wire                                    M0_AWID                    ;
wire                                    M0_AWVALID                 ;
wire                                    M0_AWREADY                 ;
wire                   [   7:0]         M0_AWLEN                   ;
wire                   [  31:0]         M0_AWADDR                  ;
wire                                    M0_WREADY                  ;
wire                   [  31:0]         M0_WSTRB                   ;
wire                                    M0_WLAST                   ;
wire                   [ 255:0]         M0_WDATA                   ;
wire                                    M0_ARID                    ;
wire                                    M0_ARVALID                 ;
wire                                    M0_ARREADY                 ;
wire                   [   7:0]         M0_ARLEN                   ;
wire                   [  31:0]         M0_ARADDR                  ;
wire                                    M0_RVALID                  ;
wire                                    M0_RLAST                   ;
wire                   [ 255:0]         M0_RDATA                   ;
wire                                    axi_wstart_locked0         ;
//VSDMA1
wire                                    M1_AWID                    ;
wire                                    M1_AWVALID                 ;
wire                                    M1_AWREADY                 ;
wire                   [   7:0]         M1_AWLEN                   ;
wire                   [  31:0]         M1_AWADDR                  ;
wire                                    M1_WREADY                  ;
wire                   [  31:0]         M1_WSTRB                   ;
wire                                    M1_WLAST                   ;
wire                   [ 255:0]         M1_WDATA                   ;
wire                                    axi_wstart_locked1         ;
//VSDMA2
wire                                    M2_AWID                    ;
wire                                    M2_AWVALID                 ;
wire                                    M2_AWREADY                 ;
wire                   [   7:0]         M2_AWLEN                   ;
wire                   [  31:0]         M2_AWADDR                  ;
wire                                    M2_WREADY                  ;
wire                   [  31:0]         M2_WSTRB                   ;
wire                                    M2_WLAST                   ;
wire                   [ 255:0]         M2_WDATA                   ;
wire                                    axi_wstart_locked2         ;
//VSDMA3
wire                                    M3_AWID                    ;
wire                                    M3_AWVALID                 ;
wire                                    M3_AWREADY                 ;
wire                   [   7:0]         M3_AWLEN                   ;
wire                   [  31:0]         M3_AWADDR                  ;
wire                                    M3_WREADY                  ;
wire                   [  31:0]         M3_WSTRB                   ;
wire                                    M3_WLAST                   ;
wire                   [ 255:0]         M3_WDATA                   ;
wire                                    axi_wstart_locked3         ;
//vsbuf
wire                   [   7:0]         bufn_i                     ;
wire                   [   7:0]         bufn_o                     ;
//ddr_ip
wire                                    ddr_init_done              ;
wire                                    ddrphy_clkin               ;
wire                   [  27:0]         axi_awaddr                 ;
wire                   [   3:0]         axi_awuser_id              ;
wire                   [   3:0]         axi_awlen                  ;
wire                                    axi_awready                ;
wire                                    axi_awvalid                ;
wire                   [ 255:0]         axi_wdata                  ;
wire                   [  31:0]         axi_wstrb                  ;
wire                                    axi_wready                 ;
wire                                    axi_wusero_last            ;
wire                   [  27:0]         axi_araddr                 ;
wire                   [   3:0]         axi_aruser_id              ;
wire                   [   3:0]         axi_arlen                  ;
wire                                    axi_arready                ;
wire                                    axi_arvalid                ;
wire                   [ 255:0]         axi_rdata                  ;
wire                   [   3:0]         axi_rid                    ;
wire                                    axi_rlast                  ;
wire                                    axi_rvalid                 ;
//video_timing_control
wire                   [  31:0]         rd_data                    ;
wire                                    o_vs                       ;
wire                                    o_hs                       ;
wire                                    de_re                      ;
wire                                    o_de                       ;
//scale
wire                                    scale_vs_out               ;//输出帧有效场同步信号
wire                                    scale_de_out               ;//图像有效信号
wire                   [  31:0]         scale_data_out             ;//图像有效数据

reg                    [  15:0]         rstn_1ms                   ;
    wire vs_out_p;
	wire hs_out_p;
	wire de_out_p;
	wire [7:0] r_out_p;
	wire [7:0] g_out_p;
	wire [7:0] b_out_p;


always @(posedge clk_10)
    begin
        if(!clk_lock)
            rstn_1ms <= 16'd0;
        else
        begin
            if(rstn_1ms == 16'h2710)
                rstn_1ms <= rstn_1ms;
            else
                rstn_1ms <= rstn_1ms + 1'b1;
        end
    end
    
assign rstn_out = (rstn_1ms == 16'h2710);


assign pix_clk   = clk_74;
assign vs_out   = vs_out_1;
assign hs_out   = hs_out_1;
assign de_out   = de_out_1;
assign r_out    = (x<=2*vout_xres&&y<=2*vout_yres)?data_out_con[23:16]:8'd0;
assign g_out    = (x<=2*vout_xres&&y<=2*vout_yres)?data_out_con[15:8]:8'd0;
assign b_out    = (x<=2*vout_xres&&y<=2*vout_yres)?data_out_con[7:0]:8'd0; 
/* assign vs_out = vs_out_p;
assign hs_out    = hs_out_p;
assign de_out    = de_out_p;
assign r_out    =  r_out_p;
assign g_out    =  g_out_p;
assign b_out    =  b_out_p; */
/* assign vs_out    = o_vs;
assign hs_out    = o_hs;
assign de_out    = o_de;
assign r_out    =  hdmi_r;
assign g_out    =  hdmi_g;
assign b_out    =  hdmi_b;  */
//控制输出
    reg        vs_out_1   ;
	reg        hs_out_1   ;
	reg        de_out_1   ;
	reg [31:0]  data_out_con  ;
reg [1:0] state;
always@(posedge sys_clk or negedge sys_rst_n)begin
   if(!sys_rst_n)
     state <= 2'b00;
	else if(key_out_2==1 || key_out_3==1)
	  state <= 2'b01; // 色彩度
	else if(key_out_4==1)
	  state <= 2'b10;	  //灰度
	 else if(key_out_5==1)
	  state <=2'b11;
	 else 
	  state <=state;
end
always@(*)begin
 case(state)
   2'b00: begin
          vs_out_1 <= vs_out_p          ;
		  hs_out_1 <= hs_out_p          ;
		  de_out_1 <= de_out_p          ;
          data_out_con <={8'd0,r_out_p,g_out_p,b_out_p} ;
   end                           
   2'b01: begin                  
          vs_out_1 <= o_vs         ;
		  hs_out_1 <= o_hs         ;
		  de_out_1 <= o_de         ;
          data_out_con <= {8'd0,hdmi_r,hdmi_g,hdmi_b} ;
   end   
   2'b10: begin
          vs_out_1 <= ycbcr_hs         ;
		  hs_out_1 <= ycbcr_vs         ;
		  de_out_1 <= ycbcr_de         ;
          data_out_con <= {8'd0,ycbcr_y,ycbcr_y,ycbcr_y} ;
   end
   2'b11: begin
          vs_out_1 <= !post_vs        ;
		  hs_out_1 <= !post_hs         ;
		  de_out_1 <= post_de         ;
          data_out_con <= {8'd0,wr_data[23:0]} ;
   end
   default:begin
          vs_out_1 <= vs_out_p          ;
		  hs_out_1 <= hs_out_p          ;
		  de_out_1 <= de_out_p          ;
          data_out_con <={8'd0,r_out_p,g_out_p,b_out_p} ;
   end  
   
   endcase
end

//*****************************************************
//**                    main code
//*****************************************************
//canny
wire post_hs;
wire post_vs;
wire post_de;
wire data_1;
wire [31:0]    wr_data;
canny_top canny_top1(
 .clk      (clk_74),
 .rst_n      (rstn_out),
 .per_frame_vsync   (!o_vs),
 .per_frame_href    (!o_hs),
 .per_frame_clken   (o_de),
 .per_frame_data    (rd_data[23:0]),
 .post_frame_vsync   (post_vs),
 .post_frame_href    (post_hs),
 .post_frame_clken    (post_de),
 .post_frame_data   (data_1)
 );
assign wr_data ={32{data_1}}; 
//对比度
wire[7:0]hdmi_r;
wire[7:0]hdmi_g;
wire[7:0]hdmi_b; 
	wire hdmi_hs1;
	wire hdmi_vs1;
	wire hdmi_de1;
photoshop photoshop1(
.clk_74(clk_74),
.sys_rst_n(sys_rst_n ),
.o_vs  (o_vs),
.o_hs  (o_hs),
.o_de  (o_de),
.rd_data (rd_data),
.hdmi_vs1(hdmi_vs1),
.hdmi_hs1(hdmi_hs1),
.hdmi_de1(hdmi_de1),
.RGB_o({hdmi_r,hdmi_g,hdmi_b}),
.key({key[1],key[0],key[5]})
 );
 
 
wire   ycbcr_hs ;
wire   ycbcr_vs ;
wire   ycbcr_de ;
wire  [7:0] ycbcr_y;

rgb_to_ycbcr rgb_to_ycbcr_m0(
	.clk                        (clk_74                ),
	.rst	                    (~rstn_out                  ),//高有效
	.rgb_r                      (rd_data[23:16]  ),
	.rgb_g                      (rd_data[15:8]  ),
	.rgb_b                      (rd_data[7:0]  ),
	.rgb_hs                     (o_vs                       ),
	.rgb_vs                     (o_hs                       ),
	.rgb_de                     (o_de                       ),
	.ycbcr_y                    (ycbcr_y                 ),
	.ycbcr_cb                   (                       ),
	.ycbcr_cr                   (                         ),
	.ycbcr_hs                   (ycbcr_hs                 ),
	.ycbcr_vs                   (ycbcr_vs                 ),
	.ycbcr_de                   (ycbcr_de                 )
);


wire  key_out;
wire key_out_1;
wire key_out_2;
wire key_out_3;
wire key_out_4;
wire key_out_5;
wire key_out_6;
xiaodou u1(
  .clk       (sys_clk  )        ,
  .rst       (rstn_out)        ,
  .key_in    (key[3])              ,
  
  .key_flag   (key_out)
);
xiaodou u2(
  .clk       (sys_clk  )        ,
  .rst       (rstn_out)        ,
  .key_in    (key[2])              ,
  
  .key_flag   (key_out_1)
);
xiaodou u3(
  .clk       (sys_clk  )        ,
  .rst       (rstn_out)        ,
  .key_in    (key[0])              ,
  
  .key_flag   (key_out_2)
);
xiaodou u4(
  .clk       (sys_clk  )        ,
  .rst       (rstn_out)        ,
  .key_in    (key[1])              ,
  
  .key_flag   (key_out_3)
);
xiaodou u5(
  .clk       (sys_clk  )        ,
  .rst       (rstn_out)        ,
  .key_in    (key[4])              ,
  
  .key_flag   (key_out_4)
);
xiaodou u6(
  .clk       (sys_clk  )        ,
  .rst       (rstn_out)        ,
  .key_in    (key[5])              ,
  
  .key_flag   (key_out_5)
);
xiaodou u7(
  .clk       (sys_clk  )        ,
  .rst       (rstn_out)        ,
  .key_in    (key[6])              ,
  
  .key_flag   (key_out_6)
);
reg en;
always@(posedge sys_clk or negedge rstn_out )begin
 if(!rstn_out)
  en<=0;
  else if(key_out_6 == 1)
    en <= ~en;
  else 
    en <= en;
end
assign led =!key[3];
pll_clk  u_pll_clk(
    .clkin1                            (sys_clk                   ),
    .clkout0                           (clk_10                    ),
    .clkout1                           (clk_50                    ),
    .clkout2                           (clk_74                    ),
    .pll_lock                          (clk_lock                  ) 
    );

ms72xx_ctl u_ms72xx_ctl(
    .clk                               (clk_10                    ),
    .rst_n                             (rstn_out                  ),
    .init_over                         (led_int                   ),
    .iic_tx_scl                        (iic_tx_scl                ),
    .iic_tx_sda                        (iic_tx_sda                ),
    .iic_scl                           (iic_scl                   ),
    .iic_sda                           (iic_sda                   ) 
    );
	
//ov5640 驱动
wire  cmos_frame_hsync;
ov5640_dri u_ov5640_dri(
    .clk                               (clk_50                    ),
    .rst_n                             (clk_lock                  ),
    .cam_pclk                          (cam_pclk                  ),
    .cam_vsync                         (cam_vsync                 ),
    .cam_href                          (cam_href                  ),
    .cam_data                          (cam_data                  ),
    .cam_rst_n                         (cam_rst_n                 ),
    .cam_pwdn                          (cam_pwdn                  ),
    .cam_scl                           (cam_scl                   ),
    .cam_sda                           (cam_sda                   ),
    .cmos_h_pixel                      (H_CMOS_DISP               ),
    .cmos_v_pixel                      (V_CMOS_DISP               ),
    .total_h_pixel                     (TOTAL_H_PIXEL             ),
    .total_v_pixel                     (TOTAL_V_PIXEL             ),
    .capture_start                     (ddr_init_done             ),
    .cmos_frame_vsync                  (cmos_frame_vsync          ),
    .cmos_frame_valid                  (cmos_frame_valid          ),
    .cmos_frame_href                   (cmos_frame_hsync          ),
    .cmos_frame_data                   (wr_data_camera            ) 
    );
//参数设置
reg [11:0] vout_xres ;
reg [11:0] vout_yres ;
always@(posedge sys_clk or negedge rstn_out )begin
   if(!rstn_out)begin
     vout_xres <= 12'd960;
     vout_yres <= 12'd540;
	 end
	 else if(key_out==1)begin
	 vout_xres <= vout_xres-12'd20;
	 vout_yres <= vout_yres-12'd10;
	 end
	 else if(key_out_1==1)begin
	 vout_xres <= vout_xres+12'd20;
	 vout_yres <= vout_yres+12'd10;
	 end
	 else begin
     vout_xres <= vout_xres	; 
	 vout_yres <= vout_yres;
	 end
end
wire [27:0]vsdma_addr_0;
wire [27:0]vsdma_addr_1;
wire [27:0]vsdma_addr_2;
wire [27:0]vsdma_addr_3;
assign vsdma_addr_0 =28'd0;
assign vsdma_addr_1 =vout_xres;
assign vsdma_addr_2 =28'd1920*vout_yres;
assign vsdma_addr_3 =28'd1920*vout_yres+vout_xres;
//video cut
 wire vs_c;
 wire hs_c;
 wire de_c;
 wire [31:0]c_data; 
suofang_scale u_camera(
     .vin_xres        (12'd960),
	   .vout_xres     (vout_xres),
       .vin_yres      (12'd540),
       .vout_yres     (vout_yres),
    .pixclk_in                         (cam_pclk                 ),
    .vs_in                             (cmos_frame_vsync                     ),
    .hs_in                             (cmos_frame_hsync                     ),
    .de_in                             (cmos_frame_valid                     ),
    .r_in                              (wr_data_camera[23:16]                    ),
    .g_in                              (wr_data_camera[15:8]                     ),
    .b_in                              (wr_data_camera[7:0]                      ),
    .vs_out                            (vs_c                  ),
    .hs_out                            (hs_c                          ),
    .de_out                            (de_c                  ),
    .wr_data                           (c_data              ) 
    );
suofang_scale u_hdmi(
     .vin_xres      (12'd1920),
	   .vout_xres     (vout_xres),
       .vin_yres      (12'd1080),
       .vout_yres     (vout_yres),
    .pixclk_in                         (pixclk_in                 ),
    .vs_in                             (vs_in                     ),
    .hs_in                             (hs_in                     ),
    .de_in                             (de_in                     ),
    .r_in                              (r_in                      ),
    .g_in                              (g_in                      ),
    .b_in                              (b_in                      ),
    .vs_out                            (scale_vs                  ),
    .hs_out                            (                          ),
    .de_out                            (scale_de                  ),
    .wr_data                           (wr_data_hdmi              ) 
    );

VSDMA #(
    .ENABLE_READ                       (1'b1                      ),
    .M_AXI_ID                          (4'd0                      ) 
    )
 uu1(
    .W_BASEADDR                        (vsdma_addr_0              ),
	.W_XSIZE                           (vout_xres                 ),
	.W_YSIZE                           (vout_yres                 ),
    .ui_clk                            (ddrphy_clkin              ),
    .ui_rstn                           (ddr_init_done             ),
    .W_wclk_i                          (cam_pclk                  ),
    .W_FS_i                            (vs_c          ),
    .W_wren_i                          (de_c          ),
    .W_data_i                          (c_data            ),
    .W_sync_cnt_o                      (bufn_i                    ),
    .W_buf_i                           (bufn_i                    ),
    .W_full                            (                          ),
    .R_rclk_i                          (clk_74                    ),
    .R_FS_i                            (o_vs                      ),
    .R_rden_i                          (de_re                     ),
    .R_data_o                          (rd_data                   ),
    .R_sync_cnt_o                      (                          ),
    .R_buf_i                           (bufn_o                    ),
    .R_empty                           (                          ),
    .axi_wstart_locked                 (axi_wstart_locked0        ),
    .M_AXI_ACLK                        (ddrphy_clkin              ),
    .M_AXI_ARESETN                     (ddr_init_done              ),
    .M_AXI_AWID                        (M0_AWID                   ),
    .M_AXI_AWADDR                      (M0_AWADDR                 ),
    .M_AXI_AWLEN                       (M0_AWLEN                  ),
    .M_AXI_AWVALID                     (M0_AWVALID                ),
    .M_AXI_AWREADY                     (M0_AWREADY                ),
    .M_AXI_WID                         (                          ),
    .M_AXI_WDATA                       (M0_WDATA                  ),
    .M_AXI_WSTRB                       (M0_WSTRB                  ),
    .M_AXI_WLAST                       (M0_WLAST                  ),
    .M_AXI_WVALID                      (                          ),
    .M_AXI_WREADY                      (M0_WREADY                 ),
    .M_AXI_ARID                        (M0_ARID                   ),
    .M_AXI_ARADDR                      (M0_ARADDR                 ),
    .M_AXI_ARLEN                       (M0_ARLEN                  ),
    .M_AXI_ARVALID                     (M0_ARVALID                ),
    .M_AXI_ARREADY                     (M0_ARREADY                ),
    .M_AXI_RID                         (                          ),
    .M_AXI_RDATA                       (M0_RDATA                  ),
    .M_AXI_RLAST                       (M0_RLAST                  ),
    .M_AXI_RVALID                      (M0_RVALID                 ),
	.en                                (en                        ),
    .M_AXI_RREADY                      (                          ) 
    );

VSDMA #(
    .ENABLE_READ                       (1'b0                      ),
    
    
    
    .M_AXI_ID                          (4'd1                      ) 
    )
uu2(
    .W_BASEADDR                        (vsdma_addr_1                  ),
    .W_XSIZE                           (vout_xres                       ),
    .W_YSIZE                           (vout_yres                       ),
    .ui_clk                            (ddrphy_clkin              ),
    .ui_rstn                           (ddr_init_done             ),
    .W_wclk_i                          (cam_pclk                  ),
    .W_FS_i                            (vs_c            ),
    .W_wren_i                          (de_c            ),
    .W_data_i                          (c_data          ),
    .W_sync_cnt_o                      (                          ),
    .W_buf_i                           (bufn_i                    ),
    .axi_wstart_locked                 (axi_wstart_locked1        ),
    .M_AXI_ACLK                        (ddrphy_clkin              ),
    .M_AXI_ARESETN                     (ddr_init_done             ),
    .M_AXI_AWID                        (M1_AWID                   ),
    .M_AXI_AWADDR                      (M1_AWADDR                 ),
    .M_AXI_AWLEN                       (M1_AWLEN                  ),
    .M_AXI_AWVALID                     (M1_AWVALID                ),
    .M_AXI_AWREADY                     (M1_AWREADY                ),
    .M_AXI_WID                         (                          ),
    .M_AXI_WDATA                       (M1_WDATA                  ),
    .M_AXI_WSTRB                       (M1_WSTRB                  ),
    .M_AXI_WLAST                       (M1_WLAST                  ),
    .M_AXI_WVALID                      (                          ),
    .M_AXI_WREADY                      (M1_WREADY                 ) 
    );

VSDMA #(
    .ENABLE_READ                       (1'b0                      ),
    
    
    
    .M_AXI_ID                          (4'd2                      )  
    )
uu3(
    .W_BASEADDR                        (vsdma_addr_2               ),
	.W_XSIZE                           (vout_xres                       ),
	.W_YSIZE                           (vout_yres                       ),
    .ui_clk                            (ddrphy_clkin              ),
    .ui_rstn                           (ddr_init_done             ),
    .W_wclk_i                          (pixclk_in                 ),
    .W_FS_i                            (scale_vs                  ),
    .W_wren_i                          (scale_de                  ),
    .W_data_i                          (wr_data_hdmi              ),
    .W_sync_cnt_o                      (                          ),
    .W_buf_i                           (bufn_i                    ),
    .axi_wstart_locked                 (axi_wstart_locked2        ),
    .M_AXI_ACLK                        (ddrphy_clkin              ),
    .M_AXI_ARESETN                     (ddr_init_done               ),
    .M_AXI_AWID                        (M2_AWID                   ),
    .M_AXI_AWADDR                      (M2_AWADDR                 ),
    .M_AXI_AWLEN                       (M2_AWLEN                  ),
    .M_AXI_AWVALID                     (M2_AWVALID                ),
    .M_AXI_AWREADY                     (M2_AWREADY                ),
    .M_AXI_WID                         (                          ),
    .M_AXI_WDATA                       (M2_WDATA                  ),
    .M_AXI_WSTRB                       (M2_WSTRB                  ),
    .M_AXI_WLAST                       (M2_WLAST                  ),
    .M_AXI_WVALID                      (                          ),
    .M_AXI_WREADY                      (M2_WREADY                 ) 
    );

VSDMA #(
    .ENABLE_READ                       (1'b0                      ),
    .M_AXI_ID                          (4'd3                      )  
    )
uu4(
    .W_BASEADDR                        (vsdma_addr_3               ),
    .W_XSIZE                           (vout_xres                       ),
    .W_YSIZE                           (vout_yres                       ),
    .ui_clk                            (ddrphy_clkin              ),
    .ui_rstn                           (ddr_init_done             ),
    .W_wclk_i                          (pixclk_in                 ),
    .W_FS_i                            (scale_vs                  ),
    .W_wren_i                          (scale_de                  ),
    .W_data_i                          (wr_data_hdmi              ),
    .W_sync_cnt_o                      (                          ),
    .W_buf_i                           (bufn_i                    ),
    .axi_wstart_locked                 (axi_wstart_locked3        ),
    .M_AXI_ACLK                        (ddrphy_clkin              ),
    .M_AXI_ARESETN                     (ddr_init_done               ),
    .M_AXI_AWID                        (M3_AWID                   ),
    .M_AXI_AWADDR                      (M3_AWADDR                 ),
    .M_AXI_AWLEN                       (M3_AWLEN                  ),
    .M_AXI_AWVALID                     (M3_AWVALID                ),
    .M_AXI_AWREADY                     (M3_AWREADY                ),
    .M_AXI_WID                         (                          ),
    .M_AXI_WDATA                       (M3_WDATA                  ),
    .M_AXI_WSTRB                       (M3_WSTRB                  ),
    .M_AXI_WLAST                       (M3_WLAST                  ),
    .M_AXI_WVALID                      (                          ),
    .M_AXI_WREADY                      (M3_WREADY                 ) 
    );

vsbuf u_vsbuf(
    .bufn_i                            (bufn_i                    ),
    .bufn_o                            (bufn_o                    ) 
    );

AXI_Interconnect u_axi_Interconnect(
    .ACLK                              (ddrphy_clkin              ),
    .ARESETn                           (ddr_init_done             ),

    .s0_AWID                           (M0_AWID                   ),
    .s0_AWADDR                         (M0_AWADDR                 ),
    .s0_AWLEN                          (M0_AWLEN                  ),
    .s0_AWVALID                        (M0_AWVALID                ),
    .s0_AWREADY                        (M0_AWREADY                ),
    .s0_WDATA                          (M0_WDATA                  ),
    .s0_WSTRB                          (M0_WSTRB                  ),
    .s0_WLAST                          (M0_WLAST                  ),
    .s0_WREADY                         (M0_WREADY                 ),
    .axi_wstart_locked0                (axi_wstart_locked0        ),

    .s1_AWID                           (M1_AWID                   ),
    .s1_AWADDR                         (M1_AWADDR                 ),
    .s1_AWLEN                          (M1_AWLEN                  ),
    .s1_AWVALID                        (M1_AWVALID                ),
    .s1_AWREADY                        (M1_AWREADY                ),
    .s1_WDATA                          (M1_WDATA                  ),
    .s1_WSTRB                          (M1_WSTRB                  ),
    .s1_WLAST                          (M1_WLAST                  ),
    .s1_WREADY                         (M1_WREADY                 ),
    .axi_wstart_locked1                (axi_wstart_locked1        ),


    .s2_AWID                           (M2_AWID                   ),
    .s2_AWADDR                         (M2_AWADDR                 ),
    .s2_AWLEN                          (M2_AWLEN                  ),
    .s2_AWVALID                        (M2_AWVALID                ),
    .s2_AWREADY                        (M2_AWREADY                ),
    .s2_WDATA                          (M2_WDATA                  ),
    .s2_WSTRB                          (M2_WSTRB                  ),
    .s2_WLAST                          (M2_WLAST                  ),
    .s2_WREADY                         (M2_WREADY                 ),
    .axi_wstart_locked2                (axi_wstart_locked2        ),

    .s3_AWID                           (M3_AWID                   ),
    .s3_AWADDR                         (M3_AWADDR                 ),
    .s3_AWLEN                          (M3_AWLEN                  ),
    .s3_AWVALID                        (M3_AWVALID                ),
    .s3_AWREADY                        (M3_AWREADY                ),
    .s3_WDATA                          (M3_WDATA                  ),
    .s3_WSTRB                          (M3_WSTRB                  ),
    .s3_WLAST                          (M3_WLAST                  ),
    .s3_WREADY                         (M3_WREADY                 ),
    .axi_wstart_locked3                (axi_wstart_locked3        ),

    .s0_ARID                           (M0_ARID                   ),
    .s0_ARADDR                         (M0_ARADDR                 ),
    .s0_ARLEN                          (M0_ARLEN                  ),
    .s0_ARVALID                        (M0_ARVALID                ),
    .s0_ARREADY                        (M0_ARREADY                ),
    .s0_RVALID                         (M0_RVALID                 ),
    .s0_RDATA                          (M0_RDATA                  ),
    .s0_RLAST                          (M0_RLAST                  ),

    .axi_awaddr                        (axi_awaddr                ),
    .axi_awuser_ap                     (                          ),
    .axi_awuser_id                     (axi_awuser_id             ),
    .axi_awlen                         (axi_awlen                 ),
    .axi_awready                       (axi_awready               ),
    .axi_awvalid                       (axi_awvalid               ),
    .axi_wdata                         (axi_wdata                 ),
    .axi_wstrb                         (axi_wstrb                 ),
    .axi_wready                        (axi_wready                ),
    .axi_wusero_id                     (                          ),
    .axi_wusero_last                   (axi_wusero_last           ),
    .axi_araddr                        (axi_araddr                ),
    .axi_aruser_ap                     (                          ),
    .axi_aruser_id                     (axi_aruser_id             ),
    .axi_arlen                         (axi_arlen                 ),
    .axi_arready                       (axi_arready               ),
    .axi_arvalid                       (axi_arvalid               ),
    .axi_rdata                         (axi_rdata                 ),
    .axi_rid                           (axi_rid                   ),
    .axi_rlast                         (axi_rlast                 ),
    .axi_rvalid                        (axi_rvalid                ) 
    );

ddr3_ip u_ddr3_ip(
    .ref_clk                           (clk_50                    ),
    .resetn                            (clk_lock                  ), 
    .ddr_init_done                     (ddr_init_done             ),
    .ddrphy_clkin                      (ddrphy_clkin              ),
    .pll_lock                          (pll_lock                  ),
    .axi_awaddr                        (axi_awaddr                ),
    .axi_awuser_ap                     (1'b1                      ),
    .axi_awuser_id                     (axi_awuser_id             ),
    .axi_awlen                         (axi_awlen                 ),
    .axi_awready                       (axi_awready               ),
    .axi_awvalid                       (axi_awvalid               ),
    .axi_wdata                         (axi_wdata                 ),
    .axi_wstrb                         (axi_wstrb                 ),
    .axi_wready                        (axi_wready                ),
    .axi_wusero_id                     (                          ),
    .axi_wusero_last                   (axi_wusero_last           ),
    .axi_araddr                        (axi_araddr                ),
    .axi_aruser_ap                     (1'b1                      ),
    .axi_aruser_id                     (axi_aruser_id             ),
    .axi_arlen                         (axi_arlen                 ),
    .axi_arready                       (axi_arready               ),
    .axi_arvalid                       (axi_arvalid               ),
    .axi_rdata                         (axi_rdata                 ),
    .axi_rid                           (axi_rid                   ),
    .axi_rlast                         (axi_rlast                 ),
    .axi_rvalid                        (axi_rvalid                ),
    .apb_clk                           (1'b0                      ),
    .apb_rst_n                         (1'b1                      ),
    .apb_sel                           (1'b0                      ),
    .apb_enable                        (1'b0                      ),
    .apb_addr                          (8'b0                      ),
    .apb_write                         (1'b0                      ),
    .apb_ready                         (                          ),
    .apb_wdata                         (16'b0                     ),
    .apb_rdata                         (                          ),
    .apb_int                           (                          ),
    .debug_data                        (                          ),
    .debug_slice_state                 (                          ),
    .debug_calib_ctrl                  (                          ),
    .ck_dly_set_bin                    (                          ),
    .force_ck_dly_en                   (1'b0                      ),
    .force_ck_dly_set_bin              (8'h05                     ),
    .dll_step                          (                          ),
    .dll_lock                          (                          ),
    .init_read_clk_ctrl                (2'b0                      ),
    .init_slip_step                    (4'b0                      ),
    .force_read_clk_ctrl               (1'b0                      ),
    .ddrphy_gate_update_en             (1'b0                      ),
    .update_com_val_err_flag           (                          ),
    .rd_fake_stop                      (1'b0                      ),
    .mem_rst_n                         (mem_rst_n                 ),
    .mem_ck                            (mem_ck                    ),
    .mem_ck_n                          (mem_ck_n                  ),
    .mem_cke                           (mem_cke                   ),
    .mem_cs_n                          (mem_cs_n                  ),
    .mem_ras_n                         (mem_ras_n                 ),
    .mem_cas_n                         (mem_cas_n                 ),
    .mem_we_n                          (mem_we_n                  ),
    .mem_odt                           (mem_odt                   ),
    .mem_a                             (mem_a                     ),
    .mem_ba                            (mem_ba                    ),
    .mem_dqs                           (mem_dqs                   ),
    .mem_dqs_n                         (mem_dqs_n                 ),
    .mem_dq                            (mem_dq                    ),
    .mem_dm                            (mem_dm                    ) 
    );
wire [11:0]x;
wire [11:0]y;
vtc u_vtc(
    .clk                               (clk_74                    ),
    .rstn                              (clk_lock                  ),
    .vs_out                            (o_vs                      ),
    .hs_out                            (o_hs                      ),
    .de_re                             (de_re                     ),
    .de_out                            (o_de                      ),
     .x_act                            (x),
	 .y_act                            (y)
    );

	
  pattern_vg #(
        .COCLOR_DEPP          (  8                    ), // Bits per channel
        .X_BITS               (  12              ),
        .Y_BITS               (  12              ),
        .H_ACT                (  1920                ),
        .V_ACT                (  1080                )
    ) // Number of fractional bits for ramp pattern
    yitaiwang_zifu (
        .rstn                 (  rstn_out              ),//input                         rstn,                                                     
        .pix_clk              (  clk_74               ),//input                         clk_in,  
        .udp_clk              (  eth_txc               ),
		.act_x                (  x                 ),//input      [X_BITS-1:0]       x, 
        .act_y		          (  y                 ),
		.data                  (rd_data),
        // input video timing
        .vs_in                (  o_vs                   ),//input                         vn_in                        
        .hs_in                (  o_hs                   ),//input                         hn_in,                           
        .de_in                (  o_de                   ),//input                         dn_in,
        // test pattern image output                                                    
        .vs_out               (  vs_out_p               ),//output reg                    vn_out,                       
        .hs_out               (  hs_out_p               ),//output reg                    hn_out,                       
        .de_out               (  de_out_p               ),//output reg                    den_out,                      
        .r_out                (  r_out_p                ),//output reg [COCLOR_DEPP-1:0]  r_out,                      
        .g_out                (  g_out_p                ),//output reg [COCLOR_DEPP-1:0]  g_out,                       
        .b_out                (  b_out_p                ), //output reg [COCLOR_DEPP-1:0]  b_out  
        .rec_en(rec_en),
        .rec_data(rec_data) 
    );	
  wire                        rec_en;
  wire [31:0]                 rec_data;  	

 eth_udp_loop  eth_udp_loop_inst (
    .sys_clk(sys_clk),
    .sys_rst_n(rstn_out),
    .eth_rxc(eth_rxc),
    .eth_rx_ctl(eth_rx_ctl),
    .eth_rxd(eth_rxd),
    .eth_txc(eth_txc),
    .eth_tx_ctl(eth_tx_ctl),
    .eth_txd(eth_txd),
    .eth_rst_n(eth_rst_n),
    .rec_en(rec_en),
    .rec_data(rec_data)
  );	
	

endmodule


