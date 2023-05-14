`timescale 1ns / 1ps


module tb_master_tx_r(

    );

    wire flash_sck;
    wire flash_cs;
    wire [3:0] flash_Io;
    //SIO1 = MISO, SIO0 = MOSI

    assign flash_Io[3:2]=2'b11;
    assign flash_cs=1'b0;

    reg clk=0;
    always #5 clk=~clk;
    reg rst;

    reg [7:0]   wdata;
    reg         wvalid;


    wire 	wready;
    wire [7:0]	rdata;

    //*****************         UART
    wire 	ready;
    wire 	o_txp;
    reg wr_en;
    reg     [7:0]    wr_data;


    initial begin
        rst=1;
        #100
         rst=0;
    end

    reg [3:0] s;

    wire [7:0] spi_dr [3:0];

    assign spi_dr[0]=8'h9F;
    assign spi_dr[1]=8'hFF;
    assign spi_dr[2]=8'hFF;
    assign spi_dr[3]=8'hFF;

    reg [1:0] dr_index=0;

    always @(posedge clk ) begin
        if (rst) begin
            s<=0;
            wr_en<=0;
            wr_data<='h0;
            wdata<='h0;
            wvalid<='h0;
        end
        else begin
            wr_en<=1'b0;
            case (s)
                0: begin
                    wdata<=spi_dr[dr_index];
                    wvalid<='b1;
                    s<='d1;
                end
                1: begin
                    if (wready) begin
                        if (dr_index!=0) begin      //第一个字节不发
                            wr_en<=1'b1;
                            wr_data<=rdata;
                        end
                        wvalid<='b0;
                        if (dr_index=='d3) begin
                            s<='d2;
                        end
                        else begin
                            dr_index<=dr_index+1'b1;
                            s<='d0;
                        end
                    end
                end
                2: begin

                end
                default: begin

                end
            endcase
        end
    end





    master_spi_tx_r #(
                        .CLK_DIV 		( 2 		))
                    u_master_spi_tx_r(
                        //ports
                        .clk        		( clk        		),
                        .rst        		( rst        		),
                        .wdata      		( wdata      		),
                        .wvalid     		( wvalid     		),
                        .wready     		( wready     		),
                        .rdata      		( rdata      		),
                        .spi_mosi_o 		( flash_Io[0] 		),
                        .spi_sck_o  		( flash_sck  		),
                        .spi_miso_i 		( 	flash_Io[1] 	)
                    );


    sst26vf064b u_sst26vf064b(
                    .SCK(flash_sck),
                    .CEb(flash_cs),
                    .SIO(flash_Io)
                );





    uart_tx_fifo #(
                     .baud_cycles 		( 100_000_000/5_000_000 		))
                 u_uart_tx_fifo(
                     //ports
                     .clk     		( clk     		),
                     .rst_n   		( ~rst   		),
                     .wr_en   		( wr_en   		),
                     .wr_data 		( wr_data 		),
                     .ready   		( ready   		),
                     .o_txp   		( o_txp   		)
                 );







endmodule
