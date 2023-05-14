`timescale 1ns / 1ps

module tb_spi_tx(

    );


    reg clk=0;

    always #5 clk=~clk;

    reg spi_tx_en_i=0;
    reg [7:0] spi_tx_data_i=0;

    initial begin
        #200
         @(posedge clk) begin
             spi_tx_en_i=1;
             spi_tx_data_i='h55;
         end

         @(posedge clk) spi_tx_en_i=0;
    end



    wire 	spi_tx_o;
    wire 	spi_clk_o;
    wire 	spi_en_o;
    wire 	spi_busy_o;

    master_spi_tx #(
                      .CPOL    		( 1'b0    		),
                      .CPHA    		( 1'b0    		),
                      .SPI_DIV 		( 10'd7		))
                  u_master_spi_tx(
                      //ports
                      .clk_i         		( clk         		),
                      .spi_tx_o      		( spi_tx_o      		),
                      .spi_clk_o     		( spi_clk_o     		),
                      .spi_tx_en_i   		( spi_tx_en_i   		),
                      .spi_tx_data_i 		( spi_tx_data_i 		),
                      .spi_en_o      		( spi_en_o      		),
                      .spi_busy_o    		( spi_busy_o    		)
                  );


endmodule
