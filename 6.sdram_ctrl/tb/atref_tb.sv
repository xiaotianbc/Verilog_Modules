
`timescale 1ns/1ps

module tb_sdram_atref;
    reg clk;
    reg rst_n;


    wire 	sdr_ck;
    wire 	sdr_cke;
    wire 	sdr_csn;
    wire 	sdr_rasn;
    wire 	sdr_casn;
    wire 	sdr_wen;
    wire [10:0]	sdr_addr;
    wire [1:0]	sdr_ba;

    sdram_ctrl_top u_sdram_ctrl_top(
                       //ports
                       .clk      		( clk      		),
                       .rst_n    		( rst_n    		),
                       .sdr_ck   		( sdr_ck   		),
                       .sdr_cke  		( sdr_cke  		),
                       .sdr_csn  		( sdr_csn  		),
                       .sdr_rasn 		( sdr_rasn 		),
                       .sdr_casn 		( sdr_casn 		),
                       .sdr_wen  		( sdr_wen  		),
                       .sdr_addr 		( sdr_addr 		),
                       .sdr_ba   		( sdr_ba   		)
                   );






    sdram_model_plus #(
                         //型号 mt48lc2m32b2， Row: [10:0], column [7:0] ,共512K地址，4个Bank，数据位宽32Bits
                         .addr_bits     		( 11            		),
                         .data_bits     		( 32            		),
                         .col_bits      		( 8             		),
                         .mem_sizes     		( 512*1024-1 		))
                     u_sdram_model_plus(
                         //ports
                         .Dq    		( Dq    		),
                         .Addr  		( sdr_addr  		),
                         .Ba    		( sdr_ba    		),
                         .Clk   		( sdr_ck   		),
                         .Cke   		( sdr_cke   		),
                         .Cs_n  		( sdr_csn  		),
                         .Ras_n 		( sdr_rasn 		),
                         .Cas_n 		( sdr_casn 		),
                         .We_n  		( sdr_wen  		),
                         .Dqm   		( 4'b0000   		),
                         .Debug 		( 1'b1 		)
                     );






    localparam CLK_PERIOD = 10;
    always #(CLK_PERIOD/2) clk=~clk;




    initial begin
        #1 rst_n<=1'bx;
        clk<=1'bx;
        #(CLK_PERIOD*3) rst_n<=1;
        #(CLK_PERIOD*3) rst_n<=0;
        clk<=0;
        repeat(5) @(posedge clk);
        rst_n<=1;
        @(posedge clk);
        repeat(2) @(posedge clk);

        #300000000;
        $finish();

    end



endmodule
`default_nettype wire
