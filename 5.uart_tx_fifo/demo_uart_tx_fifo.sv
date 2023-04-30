module demo (
        input      clk,
        input      rst_n,
        input       key,
        output      o_txp
    );



    wire 	ready;
    wire 	o_txp;

    reg wr_en;
    reg [7:0]wr_data;

    uart_tx_fifo u_uart_tx_fifo(
                     //ports
                     .clk     		( clk     		),
                     .rst_n   		( rst_n   		),
                     .wr_en   		( wr_en   		),
                     .wr_data 		( wr_data 		),
                     .ready   		( ready   		),
                     .o_txp   		( o_txp   		)
                 );

    wire 	is_press;
    wire 	is_release;

    key_debounce #(
                     .CLK_FREQ 		( 25 		))
                 u_key_debounce(
                     //ports
                     .clk        		( clk        		),
                     .rst_n      		( rst_n      		),
                     .key        		( key        		),
                     .is_press   		( is_press   		),
                     .is_release 		( is_release 		)
                 );

    enum  logic { ST_IDLE=1'b0,
                  ST_SEND=1'b1  } state;


    reg [7:0] i;

    always_ff @( posedge clk ) begin
        if (!rst_n) begin
            state<=ST_IDLE;
            i<=0;
            wr_en<1'b0;
            wr_data>='h0;
        end
        else begin
            case (state)
                ST_IDLE: begin
                    if (is_press) begin
                        state<=ST_SEND;
                    end
                end
                ST_SEND: begin
                    case (i)
                        0: begin
                            wr_en<1'b1;
                            wr_data>='h55;
                            i<=i+1'b1;
                        end
                        1: begin
                            wr_en<1'b1;
                            wr_data>='hAA;
                            i<=i+1'b1;
                        end
                        2: begin
                            wr_en<1'b1;
                            wr_data>='h12;
                            i<=i+1'b1;
                        end
                        3: begin
                            wr_en<1'b1;
                            wr_data>='h34;
                            i<=i+1'b1;
                        end
                        4: begin
                            i<='h0;
                            state<=ST_IDLE;
                        end
                    endcase
                end
            endcase
        end
    end


endmodule //demo




module key_debounce (
        input      clk,
        input      rst_n,
        input       key,
        output reg  is_press,
        output reg is_release
    );

    reg [2:0] s;        //状态

    parameter CLK_FREQ = 25;
    localparam  debounce_cnt_MAX= CLK_FREQ*10000;

    reg [$clog2(debounce_cnt_MAX)-1:0] debounce_cnt;


    always_ff @( posedge clk ) begin
        if (!rst_n) begin
            s<='h0;
            debounce_cnt<='h0;
            is_press<=1'b0;
        end
        else begin
            case (s)
                0: begin
                    is_press<=1'b0;
                    is_release<=1'b0;
                    if (key==1'b0) begin      //如果被按下
                        s<=s+1'b1;
                    end
                end
                1: begin
                    if (debounce_cnt==debounce_cnt_MAX-1) begin
                        debounce_cnt<='h0;
                        s<=s+1'b1;
                    end
                    else begin
                        debounce_cnt<=debounce_cnt+1'b1;
                    end
                end
                2: begin
                    if (key==1'b0) begin        //如果 确实被按下
                        is_press<=1'b1;
                        s<=s+1'b1;
                    end
                    else begin                  //说明是误操作
                        s<='h0;
                    end
                end
                3: begin
                    is_press<=1'b0;
                    if (key==1'b1) begin        //等待松开
                        s<=s+1'b1;
                    end
                end
                4: begin
                    if (debounce_cnt==debounce_cnt_MAX-1) begin
                        debounce_cnt<='h0;
                        s<=s+1'b1;
                    end
                    else begin
                        debounce_cnt<=debounce_cnt+1'b1;
                    end
                end
                5: begin
                    is_release<=1'b1;
                    s<='h0;
                end
            endcase
        end
    end

endmodule //key
