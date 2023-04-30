`timescale 1ns/1ps

module tb_sync_fifo;
    reg clk;
    reg rst_n;


    logic rd_en;        //读使能
    logic wr_en;        //写使能
    logic [7:0] wr_data;        //写数据



    wire 	full;
    wire [7:0]	rd_data;
    wire 	empty;

    sync_fifo #(
                  .DATA_WIDTH 		( 'd8 		),
                  .DATA_DEPTH 		( 'd8 		))
              u_sync_fifo(
                  //ports
                  .clk     		( clk     		),
                  .rst_n   		( rst_n   		),
                  .wr_en   		( wr_en   		),
                  .wr_data 		( wr_data 		),
                  .full    		( full    		),
                  .rd_en   		( rd_en   		),
                  .rd_data 		( rd_data 		),
                  .empty   		( empty   		)
              );



    localparam CLK_PERIOD = 10;
    always #(CLK_PERIOD/2) clk=~clk;





    initial begin
        rst_n<=1'bx;
        clk<=1'b0;
        #(CLK_PERIOD*3) rst_n<=1;
        #(CLK_PERIOD*3) rst_n<=0;
        wr_en<=1'b0;
        rd_en<=1'b0;
        wr_data<='h0;

        repeat(5) @(posedge clk);
        rst_n<=1;
        @(posedge clk);
        repeat(2) @(posedge clk);

        repeat(8) begin
            @(negedge clk) begin
                 wr_en<=1'b1;
                 wr_data<=$random();
             end
         end
         @(posedge clk);
        wr_en<=1'b0;
        repeat(5) @(posedge clk);

        repeat(8) begin
            @(negedge clk) begin
                 rd_en<=1'b1;
             end
         end
         @(posedge clk);
        rd_en<=1'b0;

        repeat(5) @(posedge clk);

        //同时读写
        repeat(40) begin
            @(negedge clk) begin
                 rd_en<=1'b1;
                 wr_en<=1'b1;
                 wr_data<=$random();
             end
         end
         @(posedge clk);
        rd_en<=1'b0;
        wr_en<=1'b0;

    end

endmodule
`default_nettype wire
