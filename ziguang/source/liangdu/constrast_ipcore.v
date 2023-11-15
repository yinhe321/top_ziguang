`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: Guangzhou
// Engineer:Liguozhu 
// 
// Create Date: 2018/08/18 09:49:44
// Design Name: 
// Module Name: constrast_ipcore
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
/*  �Աȶ������ȼ��㷨��ʽ���ο�photoshop-matlab�㷨
�Աȶ��ϵ�
    R = Average_R + 100*(R-Average_R)/(100-Contrast) + Bright;
    G = Average_G + 100*(G-Average_G)/(100-Contrast) + Bright;
    B = Average_B + 100*(B-Average_B)/(100-Contrast) + Bright;
 �Աȶ��µ�   
    R= Average_R + (R - Average_R) * (100 + Contrast)/100 + Bright;
    G= Average_G + (G - Average_G) * (100 + Contrast)/100 + Bright;
    B= Average_B + (B - Average_B) * (100 + Contrast)/100 + Bright;
    
    1�����ڵ���ΪС������������漰���˶������ļ��㡣��ν���������ǽ�С��λ���̶��������ͻ�������?����������?ѡ����ʵ�С��λ������֤����㹻С��
       �Ա�����?����������Ϊ32λ��1λ����λ��31λС��λ��
    2����Բ��?�ķֱ��ʣ���Ҫ��ǰ���ú÷ֱ��ʵĵ���������
       parameter IamgeSize = 32'h00001945; //(1/IamgeSize)*(2^31) = 32'h00001945��1λ����λ��31λС��λ,IamgeSize=720*461
*/
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module constrast_ipcore(
    input wire Pclk,
    input wire Rst,
    input wire Vsync,
    input wire Hsync,
    input wire De,
    input wire[23:0] RGB,
    input wire CONTRAST_SIG,
    input wire BRIGHT_SIG,
    input wire[7:0] CONTRAST,
    input wire[7:0] BRIGHT,
    output reg Vsync_o,
    output reg Hsync_o,
    output reg De_o,
     output reg [23:0]RGB_o
    /* output  [23:0] RGB_reg3 */
    );
//==================================================================================    
/* parameter IamgeSize = 32'h00001945; */     // (1/IamgeSize)*(2^31) = 32'h00001945��1λ����λ��31λС��λ,IamgeSize=720*461
    parameter IamgeSize = 32'h0000040D;
reg[31:0] R_Sum,G_Sum,B_Sum;
reg[31:0] R_Sum_r,G_Sum_r,B_Sum_r;

wire[63:0]  AverageR_temp;
wire[63:0]  AverageG_temp;  
wire[63:0]  AverageB_temp;  

reg[7:0]    AverageR;       //Rͨ����ֵ
reg[7:0]    AverageG;       //Gͨ����ֵ
reg[7:0]    AverageB;       //Bͨ����ֵ

reg vsync_r;
wire vsync_p;

/* reg [23:0]RGB_o;


reg [23:0] RGB_reg;

assign RGB_reg3=RGB_reg;

always @(posedge Pclk) begin
  if (De == 1'b1) begin
    RGB_reg <= RGB_o; // 在顶升沿时存储RGB信号的当前值
  end
end

 */

















    always @(posedge Pclk)
        vsync_r<=Vsync;
    assign vsync_p = Vsync & (~vsync_r);

    assign AverageR_temp = R_Sum_r * IamgeSize;           
    assign AverageG_temp = G_Sum_r * IamgeSize;
    assign AverageB_temp = B_Sum_r * IamgeSize;

    always @ (posedge Pclk or negedge Rst) //�Ĵ�������
        begin
            if(Rst)
                begin
                    AverageR <= 8'd0;
                    AverageG <= 8'd0;
                    AverageB <= 8'd0;
                end
            else
                begin
                    AverageR <= AverageR_temp[38:31];       //��ȡ����λ
                    AverageG <= AverageG_temp[38:31];
                    AverageB <= AverageB_temp[38:31];
                end
        end

always @(posedge Pclk)
    begin
    if(vsync_p || Rst)
        begin            
        R_Sum_r<=R_Sum;
        G_Sum_r<=G_Sum;
        B_Sum_r<=B_Sum;
     
        R_Sum<=0;
        G_Sum<=0;
        B_Sum<=0;
        end
    else if(De==1'b1)
        begin
        R_Sum<=R_Sum+RGB[23:16];
        G_Sum<=G_Sum+RGB[15:8];
        B_Sum<=B_Sum+RGB[7:0];     
        end
    end
    
//==================================================================================
wire[7:0] Contrast_Sel;
wire[31:0] Contrast_Recip;   
assign Contrast_Sel = (CONTRAST_SIG==1)? (8'd100-CONTRAST):8'd100;

Reciprocal Reciprocal(
    .Divisor_Sel(Contrast_Sel),
    .Recip(Contrast_Recip)
    );


reg[63:0] Contrast_r,Contrast_g,Contrast_b;
reg[7:0] divisor_percent;
reg tvalid_RGB;
wire dout_tvalid_R,dout_tvalid_G,dout_tvalid_B;
wire[55:0] dout_tdata_R,dout_tdata_G,dout_tdata_B;
reg[7:0] R_o,G_o,B_o;
reg de_r;
reg R_flg,G_flg,B_flg;//���ܲ���������,���ڷ���ʶ��

always @(posedge Pclk)
  begin
  de_r<=De;   
  
    if(De==1'b1)
        begin
        if(CONTRAST_SIG==1) //�Աȶ��ϵ�   
            begin
//            divisor_percent<=100-CONTRAST;     
            if(RGB[23:16]>AverageR) 
                begin
                Contrast_r<=(RGB[23:16]-AverageR)*100*Contrast_Recip; 
                R_flg<=1;
                end 
            else begin
                Contrast_r<=(AverageR-RGB[23:16])*100*Contrast_Recip;  
                R_flg<=0;
                end
            
            if(RGB[15:8]>AverageG) 
                begin
                Contrast_g<=(RGB[15:8]-AverageG)*100*Contrast_Recip;    
                G_flg<=1;
                end          
            else begin
                Contrast_g<=(AverageG-RGB[15:8])*100*Contrast_Recip;  
                G_flg<=0;
                end
            
            if(RGB[7:0]>AverageB) 
                begin
                Contrast_b<=(RGB[7:0]-AverageB)*100*Contrast_Recip; 
                B_flg<=1;
                end
            else  begin
                Contrast_b<=(AverageB-RGB[7:0])*100*Contrast_Recip; 
                B_flg<=0;
                end
            end 
            
        else if(CONTRAST_SIG==0) //�Աȶ��µ�
            begin
//            divisor_percent<=100;     
             if(RGB[23:16]>AverageR) 
                 begin
                 Contrast_r<=(RGB[23:16]-AverageR)*(100-CONTRAST)*Contrast_Recip; 
                 R_flg<=1;
                 end 
             else begin
                 Contrast_r<=(AverageR-RGB[23:16])*(100-CONTRAST)*Contrast_Recip;  
                 R_flg<=0;
                 end
             
             if(RGB[15:8]>AverageG) 
                 begin
                 Contrast_g<=(RGB[15:8]-AverageG)*(100-CONTRAST)*Contrast_Recip;    
                 G_flg<=1;
                 end          
             else begin
                 Contrast_g<=(AverageG-RGB[15:8])*(100-CONTRAST)*Contrast_Recip;  
                 G_flg<=0;
                 end
             
             if(RGB[7:0]>AverageB) 
                 begin
                 Contrast_b<=(RGB[7:0]-AverageB)*(100-CONTRAST)*Contrast_Recip; 
                 B_flg<=1;
                 end
             else  begin
                 Contrast_b<=(AverageB-RGB[7:0])*(100-CONTRAST)*Contrast_Recip; 
                 B_flg<=0;
                 end
            end      
        end    
  

        
  //--------------------------------------------------------  
  // Contrast_r��Contrast_g��Contrast_b�������ܴ���255����ȡ���Ƚ�ʱҪע��ѡȡ����λ��[63:31]
    
    if(de_r)
        begin
        if(R_flg) 
            begin
            if(AverageR+Contrast_r[63:31]>255)      
                R_o<=8'hff;
            else R_o<=AverageR+Contrast_r[63:31];
            end
        else begin
            if(AverageR<Contrast_r[63:31])
                R_o<=8'h00;
            else R_o<=AverageR-Contrast_r[63:31];
            end
        end

    if(de_r)
        begin
        if(G_flg) 
            begin
            if(AverageG+Contrast_g[63:31]>255)
                G_o<=8'hff;
            else G_o<=AverageG+Contrast_g[63:31];
            end
        else begin
            if(AverageG<Contrast_g[63:31])
                G_o<=8'h00;
            else G_o<=AverageG-Contrast_g[63:31];
            end
        end
        
     if(de_r)
        begin
        if(B_flg) 
            begin
            if(AverageB+Contrast_b[63:31]>255)
                B_o<=8'hff;
            else B_o<=AverageB+Contrast_b[63:31];
            end
        else begin
            if(AverageB<Contrast_b[63:31])
                B_o<=8'h00;
            else B_o<=AverageB-Contrast_b[63:31];
            end 
        end

    end
    
    
                
 //=============================================================���ȵ���
    
always @(*)  
    begin
    Vsync_o <= Vsync;
    Hsync_o <= de_r;
    De_o <= de_r;
    if(BRIGHT_SIG)
        begin
        if((R_o+BRIGHT)>255)
            RGB_o[23:16]<=8'hff;
        else RGB_o[23:16]<=(R_o+BRIGHT);
        if((G_o+BRIGHT)>255)
            RGB_o[15:8]<=8'hff;
        else RGB_o[15:8]<=(G_o+BRIGHT);       
        if((B_o+BRIGHT)>255)
            RGB_o[7:0]<=8'hff;
        else RGB_o[7:0]<=(B_o+BRIGHT);       
        end
    else begin
        if((R_o<BRIGHT))
            RGB_o[23:16]<=8'h00;
        else RGB_o[23:16]<=(R_o-BRIGHT);
        if(G_o<BRIGHT)
            RGB_o[15:8]<=8'h00;
        else RGB_o[15:8]<=(G_o-BRIGHT);       
        if(B_o<BRIGHT)
            RGB_o[7:0]<=8'h00;
        else RGB_o[7:0]<=(B_o-BRIGHT);       
        end
    end 

    

    
    
    
    
    
    
    
endmodule
