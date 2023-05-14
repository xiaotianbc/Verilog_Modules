`default_nettype none
module read_spi_flash_id (
        input   wire   clk,
        input   wire   rst_n,
        output  wire    flash_sck,
        output  wire    flash_cs,
        output  wire [3:2]   flash_Io,
        output  wire    flash_MOSI_O,
        input   wire   flash_MISO_I,
        output  wire    o_txp

    );


    //SIO1 = MISO, SIO0 = MOSI

    assign flash_Io[3:2]={1'b1,1'b1};
    assign flash_cs=1'b0;



    wire  rst=~rst_n;

    reg [7:0]   wdata;
    reg         wvalid;

    wire 	wready;
    wire [7:0]	rdata;

    //*****************         UART
    wire 	ready;
    reg wr_en;
    reg     [7:0]    wr_data;


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
                        .CLK_DIV 		( 8 		))
                    u_master_spi_tx_r(
                        //ports
                        .clk        		( clk        		),
                        .rst        		( rst        		),
                        .wdata      		( wdata      		),
                        .wvalid     		( wvalid     		),
                        .wready     		( wready     		),
                        .rdata      		( rdata      		),
                        .spi_mosi_o 		( flash_MOSI_O		),
                        .spi_sck_o  		( flash_sck  		),
                        .spi_miso_i 		( 	flash_MISO_I	)
                    );





    uart_tx_fifo #(
                     .baud_cycles 		( 25_000_000/115200 		))
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
