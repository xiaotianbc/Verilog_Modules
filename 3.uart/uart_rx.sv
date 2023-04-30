module uart_rx (
        input      clk,
        input      rst_n,

        input logic i_rxp,
        output byte o_rx_data,
        output logic o_rx_valid
    );

    parameter BAUDRATE_DIV = 25_000_000/5_000_000;

    localparam ST_IDLE = 4'b0001;
    localparam ST_START = 4'b0010;
    localparam ST_DATA = 4'b0100;
    localparam ST_STOP = 4'b1000;

    logic [3:0] state, next_state;

    logic [$clog2(BAUDRATE_DIV+1)-1:0]  baud_cnt;
    wire baud_cnt_will_overflow=(baud_cnt==BAUDRATE_DIV-1);

    logic [2:0] bits_cnt;


    always_ff @( posedge clk ) begin
        if (!rst_n) begin
            baud_cnt<=0;
        end
        else begin
            unique case (state)
                       ST_IDLE:
                           baud_cnt<=0;
                       ST_START:  begin
                           if (baud_cnt==BAUDRATE_DIV/2-1) begin
                               baud_cnt<=0;
                           end
                           else begin
                               baud_cnt<=baud_cnt+1'b1;
                           end
                       end
                       default: begin
                           if (baud_cnt==BAUDRATE_DIV-1) begin
                               baud_cnt<=0;
                           end
                           else begin
                               baud_cnt<=baud_cnt+1'b1;
                           end
                       end
                   endcase
               end
           end

           always_ff @( posedge clk ) begin
               if (!rst_n) begin
                   bits_cnt<=0;
               end
               else begin
                   if ((state==ST_DATA) && (baud_cnt==BAUDRATE_DIV-1)) begin
                       bits_cnt<=bits_cnt+1'b1;
                   end
                   else begin
                       bits_cnt<=bits_cnt;
                   end
               end

           end

           always_ff @( posedge clk ) begin
               if (!rst_n) begin
                   state<=ST_IDLE;
               end
               else begin
                   state<=next_state;
               end
           end

           always_comb begin
               unique case (state)
                          ST_IDLE: begin
                              if (i_rxp==1'b0) begin
                                  next_state=ST_START;
                              end
                              else begin
                                  next_state=ST_IDLE;
                              end
                          end
                          ST_START: begin
                              if (baud_cnt==BAUDRATE_DIV/2-1) begin
                                  next_state=ST_DATA;
                              end
                              else begin
                                  next_state=ST_START;
                              end
                          end
                          ST_DATA: begin
                              if (baud_cnt_will_overflow &&  bits_cnt=='h7) begin
                                  next_state=ST_STOP;
                              end
                              else begin
                                  next_state=ST_DATA;
                              end
                          end
                          ST_STOP: begin
                              if (baud_cnt_will_overflow ) begin
                                  next_state=ST_IDLE;
                              end
                              else begin
                                  next_state=ST_STOP;
                              end
                          end
                          default: begin
                              next_state=ST_IDLE;
                          end
                      endcase
                  end

                  always_ff @( posedge clk ) begin
                      if (!rst_n) begin
                          o_rx_data<=0;
                      end
                      else begin
                          if (state==ST_DATA && baud_cnt_will_overflow) begin
                              o_rx_data<={i_rxp,o_rx_data[7:1]};
                          end
                          else begin
                              o_rx_data<=o_rx_data;
                          end
                      end
                  end

                  always_ff @( posedge clk ) begin
                      if (!rst_n) begin
                          o_rx_valid<=1'b0;
                      end
                      else begin
                          if (state==ST_STOP && baud_cnt_will_overflow) begin
                              o_rx_valid<=1'b1;
                          end
                          else begin
                              o_rx_valid<=1'b0;
                          end
                      end
                  end

              endmodule //uart_rx
