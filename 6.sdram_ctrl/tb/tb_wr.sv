
`timescale 1ns/1ps

module tb_sdram_wr;
    reg clk;
    reg rst_n;


    localparam CLK_PERIOD = 10;             //100MHz
    always #(CLK_PERIOD/2) clk=~clk;




    wire [3:0]	init_sdr_cmds;
    wire [10:0]	init_sdr_addr;
    wire [1:0]	init_sdr_ba;
    wire 	init_done;


    wire [3:0]	wr_sdr_cmds;
    wire [10:0]	wr_sdr_addr;
    wire [1:0]	wr_sdr_ba;
    wire [31:0]	wr_sdr_dq;
    wire [3:0]	wr_sdr_dqm;


    wire [31:0] sdram_model_dq=init_done?wr_sdr_dq:{32{1'bz}};
    wire [10:0] sdram_model_addr=init_done?wr_sdr_addr:init_sdr_addr;
    wire [1:0] sdram_model_ba=init_done?wr_sdr_ba:init_sdr_ba;

    wire sdram_model_sdr_csn;
    wire sdram_model_sdr_rasn;
    wire sdram_model_sdr_casn;
    wire sdram_model_sdr_wen;

    assign {sdram_model_sdr_csn,sdram_model_sdr_rasn,sdram_model_sdr_casn,sdram_model_sdr_wen}=init_done?wr_sdr_cmds:init_sdr_cmds;


    reg         i_wr_en;
    reg [20:0] i_wr_addr;
    reg [31:0]  i_wr_data;
    reg [7:0]   i_burst_len;

    wire 	o_wr_ack;
    wire 	o_wr_end;
    wire 	o_wr_output_en;


    initial begin
        #1 rst_n<=1'bx;
        clk<=1'bx;
        #(CLK_PERIOD*3) rst_n<=1;
        #(CLK_PERIOD*3) rst_n<=0;
        clk<=0;
        i_wr_addr<='h10111;
        i_burst_len<='d9;

        repeat(5) @(posedge clk);
        rst_n<=1;
        @(posedge clk);
        repeat(2) @(posedge clk);
    end

    always_ff @( posedge clk ) begin
        if (!rst_n) begin
            i_wr_en<=1'b0;
        end
        else begin
            if (init_done && !i_wr_en && i_wr_data==0) begin
                i_wr_en<=1'b1;
            end
            else begin
                i_wr_en<=1'b0;
            end
        end
    end

    reg [7:0]   wr_num=10;

    always_ff @( posedge clk ) begin
        if (!rst_n) begin
            i_wr_data<='h0;
        end
        else begin
            if (o_wr_ack) begin
                i_wr_data<=wr_num;
                wr_num<=wr_num+1'b1;
            end
            else begin
                i_wr_data<=i_wr_data;
            end
        end
    end



    sdram_model_plus #(
                         //型号 mt48lc2m32b2， Row: [10:0], column [7:0] ,共512K地址，4个Bank，数据位宽32Bits
                         .addr_bits     		( 11            	),
                         .data_bits     		( 32            	),
                         .col_bits      		( 8             	),
                         .mem_sizes     		( 512*1024-1 		))
                     u_sdram_model_plus(
                         //ports
                         .Dq    		( sdram_model_dq    		),
                         .Addr  		( sdram_model_addr  		),
                         .Ba    		( sdram_model_ba    		),
                         .Clk   		( clk   		),
                         .Cke   		( 1'b1   		),
                         .Cs_n  		( sdram_model_sdr_csn  		),
                         .Ras_n 		( sdram_model_sdr_rasn 		),
                         .Cas_n 		( sdram_model_sdr_casn 		),
                         .We_n  		( sdram_model_sdr_wen  		),
                         .Dqm   		( 4'b0000   		),
                         .Debug 		( 1'b1 		)
                     );





    sdram_init #(
                   .INIT_US 		( 200 		),
                   .tRP     		( 3   		),
                   .tRFC    		( 7   		),
                   .tMRD    		( 2   		))
               u_sdram_init(
                   //ports
                   .clk       		( clk       		),
                   .rst_n     		( rst_n     		),
                   .sdr_cmds  		(init_sdr_cmds  		),
                   .sdr_addr  		( init_sdr_addr  		),
                   .sdr_ba    		(init_sdr_ba    		),
                   .init_done 		( init_done 		)
               );




    sdram_wr #(
                 .tRP  		( 3 		),
                 .tRFC 		( 7 		),
                 .tMRD 		( 2 		),
                 .tRCD 		( 2 		),
                 .tWR  		( 2 		))
             u_sdram_wr(
                 //ports
                 .clk            		( clk            		),
                 .rst_n          		( rst_n          		),
                 .sdr_cmds       		( wr_sdr_cmds       		),
                 .sdr_addr       		( wr_sdr_addr       		),
                 .sdr_ba         		( wr_sdr_ba         		),
                 .sdr_dq         		( wr_sdr_dq         		),
                 .sdr_dqm        		( wr_sdr_dqm        		),
                 .i_wr_en        		( i_wr_en        		),
                 .i_wr_addr      		( i_wr_addr      		),
                 .i_wr_data      		( i_wr_data      		),
                 .i_burst_len    		( i_burst_len    		),
                 .o_wr_ack       		( o_wr_ack       		),
                 .o_wr_end       		( o_wr_end       		),
                 .o_wr_output_en 		( o_wr_output_en 		)
             );





endmodule
`default_nettype wire
