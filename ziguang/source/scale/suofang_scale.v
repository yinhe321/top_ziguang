`timescale 1ns / 1ps
module suofang_scale(
    input      [11:0]             vin_xres                         ,
	input      [11:0]             vout_xres                        ,
	input      [11:0]             vin_yres                         ,
	input      [11:0]             vout_yres                        ,
																   
    input                               pixclk_in                  ,
    input                               vs_in                      ,
    input                               hs_in                      ,
    input                               de_in                      ,
    input              [   7:0]         r_in                       ,
    input              [   7:0]         g_in                       ,
    input              [   7:0]         b_in                       ,

    output                              pixclk_out                 ,
    output                              vs_out                     ,
    output reg                          hs_out                     ,
    output reg                          de_out                     ,
    output             [  31:0]         wr_data                     

);
///////////////////////////////////////////////////////
reg                    [   7:0]         r_out                      ;
reg                    [   7:0]         g_out                      ;
reg                    [   7:0]         b_out                      ;

    /* parameter                           vin_xres    =1920          ;
    parameter                           vout_xres   =960           ;
    parameter                           vin_yres    =1080          ;
    parameter                           vout_yres   =540           ; */
 
assign pixclk_out   =  pixclk_in    ;
assign vs_out       =  vs_in;
assign wr_data      =  {8'b0,r_out,g_out,b_out};
///////////////////////////////////////////////////////////////
/* reg                    [  31:0]         scaler_height	=   ((vin_yres << 16 )/vout_yres) + 1;//垂直缩放系数，[31:16]高16位是整数，低16位是小数
reg                    [  31:0]         scaler_width	=   ((vin_xres << 16 )/vout_xres) + 1;//水平缩放系数，[31:16]高16位是整数，低16位是小数	 */
 wire   [31:0]         scaler_height;
 wire   [31:0]         scaler_width;	
 assign    scaler_height	=   ((vin_yres << 16 )/vout_yres) + 1;
 assign    scaler_width	    =   ((vin_xres << 16 )/vout_xres) + 1;


reg                    [  15:0]         vin_x			= 0                ;//输入视频水平计数
reg                    [  15:0]         vin_y			= 0                ;//输入视频垂直计数
reg                    [  31:0]         vout_x			= 0               ;//输出视频水平计数,定浮点数,[31:16]高16位是整数部分
reg                    [  31:0]         vout_y			= 0               ;//输出视频垂直计数,定浮点数,[31:16]高16位是整数部分
always@(posedge pixclk_in)
begin                                                               //输入视频水平计数和垂直计数，按像素个数计数。
    if(vs_in )begin
        vin_x            <= 0;
        vin_y            <= 0;
    end
    else if (de_in == 1 )begin                                      //当前输入视频数据有效
        if( vin_x < vin_xres -1 )begin                              //vin_xres = 输入视频宽度
            vin_x    <= vin_x + 1;
        end
        else begin
            vin_x        <= 0;
            vin_y        <= vin_y + 1;
        end
    end
end                                                                 //always

always@(posedge pixclk_in)
begin                                                               //临近缩小算法，就是计算出要保留的像素保留，其他的像素舍弃。保留像素的水平坐标和垂直坐标
    if(vs_in)begin
        vout_x        <= 0;
        vout_y        <= 0;
    end
    else if (de_in == 1 )begin                                      //当前输入视频数据有效
        if(vin_x < vin_xres -1)begin                                //vin_xres = 输入视频宽度
            if (vout_x[31:16] <= vin_x)begin                        //[31:16]高16位是整数部分
                vout_x    <= vout_x + scaler_width;                 //vout_x 需要保留的像素的 x 坐标
            end
        end
        else begin
            vout_x        <= 0;
            if (vout_y[31:16] <= vin_y)begin                        //[31:16]高16位是整数部分
                vout_y    <= vout_y + scaler_height;                //vout_y 需要保留的像素的 y 坐标
            end
        end
    end
end                                                                 //	always
//vin_x,vin_y 一直在变化，随着输入视频的扫描，一线线一行行的变化
//当 vin_x == vout_x && vin_y == vout_y 该点像素保留输出，否则舍弃该点像素。
always@(posedge pixclk_in)
begin
    if(vs_in)begin
	  
        hs_out       <=  0   ;
        de_out       <=  0   ;
        r_out        <=  0   ;
        g_out        <=  0   ;
        b_out        <=  0   ;
    end
    else begin                                                      //当前输入视频数据有效
        if(vout_x[31:16] == vin_x && vout_y[31:16] == vin_y)begin   //[31:16]高16位是整数部分,判断是否保留该像素
				//置输出有效
        r_out        <=  r_in         ;
        g_out        <=  g_in         ;
        b_out        <=  b_in         ;
        hs_out       <=  hs_in        ;
        de_out       <=  de_in        ;
			//该点像素保留输出
        end
        else begin
			
					//置输出无效，舍弃该点像素。
            r_out        <=  0        ;
            g_out        <=  0        ;
            b_out        <=  0        ;
            hs_out       <=  hs_in    ;
            de_out       <=  0        ;
        end
    end
end                                                                 //	always
	 
endmodule
