`timescale  1ns/1ps

module tb_;
    reg clk;
    reg rst_n;


    reg wr_en;
    reg [7:0]   wr_data;


    wire 	ready;
    wire 	o_txp;

    uart_tx_fifo u_uart_tx_fifo(
                     //ports
                     .clk     		( clk     		),
                     .rst_n   		( rst_n   		),
                     .wr_en   		( wr_en   		),
                     .wr_data 		( wr_data 		),
                     .ready   		( ready   		),
                     .o_txp   		( o_txp   		)
                 );


    localparam CLK_PERIOD = 40;     //25MHz
    always #(CLK_PERIOD/2) clk=~clk;



    initial begin
        #1 rst_n<=1'bx;
        clk<=1'bx;
        #(CLK_PERIOD*3) rst_n<=1;
        #(CLK_PERIOD*3) rst_n<=0;
        clk<=0;
        wr_en<=0;
        wr_data<=0;
        repeat(5) @(posedge clk);
        rst_n<=1;
        @(posedge clk);
        repeat(2) @(posedge clk);

        @(posedge clk) begin
             wr_en<=1;
             wr_data<='h55;
         end
         @(posedge clk) begin
              wr_en<=1;
              wr_data<='hAA;
          end
          @(posedge clk) begin
               wr_en<=1;
               wr_data<='h12;
           end
           @(posedge clk) begin
                wr_en<=1;
                wr_data<='h34;
            end
            @(posedge clk) begin
                 wr_en<=0;
             end
         end
     endmodule
`default_nettype wire
