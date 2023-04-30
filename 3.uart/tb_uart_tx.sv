`timescale 1ns/1ps

module testbench();


    parameter MAIN_FRE   = 100; //unit MHz
    reg                   clk;
    reg                   rst_n ;        //低电平复位

    always begin
        #(500/MAIN_FRE) clk = ~clk;
    end


    reg [7:0]   i_tx_data;
    reg         i_tx_en;

    //Instance
    wire    o_txp;
    wire    o_tx_done;


    initial begin
        rst_n = 0;
        clk = 0;
        i_tx_data=0;
        i_tx_en=1'b0;
        @(posedge clk);
        @(posedge clk);

        rst_n = 1;
        @(posedge clk);
        @(posedge clk);
        @(posedge clk);

        i_tx_data=8'h55;
        i_tx_en=1'b1;
        @(posedge clk);
        i_tx_en=1'b0;

        @(posedge o_tx_done);       //等上一个字节发送完成
        @(posedge clk);
        i_tx_data=8'hAA;
        i_tx_en=1'b1;
        @(posedge clk);
        i_tx_en=1'b0;

        @(posedge o_tx_done);       //等上一个字节发送完成
        @(posedge clk);
        i_tx_data=8'h12;
        i_tx_en=1'b1;
        @(posedge clk);
        i_tx_en=1'b0;


        @(posedge o_tx_done);       //等上一个字节发送完成
        @(posedge clk);
        i_tx_data=8'h34;
        i_tx_en=1'b1;
        @(posedge clk);
        i_tx_en=1'b0;


    end





    uart_tx #(
                .baud_cycles        ( 100_000_000/20_000_000        ))
            u_uart_tx(
                //ports
                .clk            ( clk               ),
                .rst_n          ( rst_n             ),
                .i_tx_data      ( i_tx_data         ),
                .i_tx_en        ( i_tx_en           ),
                .o_txp          ( o_txp             ),
                .o_tx_done      ( o_tx_done         )
            );


    //------------------------------------------------
    //--    状态机名称查看器
    //------------------------------------------------
    reg [39:0]    state_name_cur;                //每字符8位宽，这里最多5个字符40位宽（THREE）
    reg [39:0]    state_name_next;            //每字符8位宽，这里最多5个字符40位宽（THREE）

    always @(*) begin
        case(u_uart_tx.state)    //这里写你例化的状态机模块里你想查看的参数
            4'b0001:
                state_name_cur = "ST_IDLE";    //编码对应你的状态机的编码
            4'b0010:
                state_name_cur = "ST_START";
            4'b0100:
                state_name_cur = "ST_DATA";
            4'b1000:
                state_name_cur = "ST_STOP";
            default:
                state_name_cur = "ST_IDLE";
        endcase
    end

    always @(*) begin
        case(u_uart_tx.next_state)
            4'b0001:
                state_name_next = "ST_IDLE";
            4'b0010:
                state_name_next = "ST_START";
            4'b0100:
                state_name_next = "ST_DATA";
            4'b1000:
                state_name_next = "ST_STOP";
            default:
                state_name_next = "ST_IDLE";
        endcase
    end

endmodule  //TOP
