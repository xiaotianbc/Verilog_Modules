module uart_tx (
        input               clk,
        input               rst_n,
        input       [7:0]   i_tx_data,
        input               i_tx_en,
        output    reg       o_txp,
        output    reg       o_tx_done
    );

    parameter baud_cycles = 25_000_000/5_000_000;

    //------------<状态机参数定义>------------------------------------------
    localparam ST_IDLE  = 4'b0001;
    localparam ST_START  = 4'b0010;
    localparam ST_DATA  = 4'b0100;
    localparam ST_STOP  = 4'b1000;


    //------------<reg定义>-------------------------------------------------
    reg    [3:0]    state;                            //定义现态寄存器
    reg    [3:0]    next_state;                    //定义次态寄存器

    reg  [7:0]   i_tx_data_r;
    reg [$clog2(baud_cycles+1)-1:0] baud_cnt;
    reg [2:0]   bits_cnt;               // 当前发送位数计数

    wire baud_cnt_willoverflow=(baud_cnt==baud_cycles-1);

    always @(posedge clk) begin
        if(!rst_n) begin
            i_tx_data_r <= 0;
        end
        else begin
            if (state==ST_IDLE && i_tx_en) begin
                i_tx_data_r<=i_tx_data;
            end
            else begin
                i_tx_data_r<=i_tx_data_r;
            end
        end
    end

    always @(posedge clk) begin
        if(!rst_n) begin
            baud_cnt<= 0;
        end
        else begin
            if (state!=ST_IDLE) begin
                baud_cnt<=baud_cnt+1'b1;
                if (baud_cnt_willoverflow) begin
                    baud_cnt<='h0;
                end
            end
        end
    end

    //当前发送位数计数
    always @(posedge clk) begin
        if(!rst_n) begin
            bits_cnt<= 0;
        end
        else begin
            if (state==ST_DATA && baud_cnt_willoverflow) begin
                bits_cnt<=bits_cnt+1'b1;
            end
        end
    end


    //-----------------------------------------------------------------------
    //--状态机第一段：同步时序描述状态转移
    //-----------------------------------------------------------------------
    always@(posedge clk ) begin
        if(!rst_n)
            state <= ST_IDLE;                //复位初始状态
        else
            state <= next_state;        //次态转移到现态
    end

    //-----------------------------------------------------------------------
    //--状态机第二段：组合逻辑判断状态转移条件，描述状态转移规律以及输出
    //-----------------------------------------------------------------------
    always@(*) begin
        case(state)                        //组合逻辑
            //根据当前状态、输入进行状态转换判断
            ST_IDLE: begin
                if (i_tx_en) begin
                    next_state=ST_START;
                end
                else begin
                    next_state=ST_IDLE;
                end
            end
            ST_START: begin
                if (baud_cnt_willoverflow) begin
                    next_state=ST_DATA;
                end
                else begin
                    next_state=ST_START;
                end
            end
            ST_DATA: begin
                if (baud_cnt_willoverflow && bits_cnt=='h7) begin       //发送完最高位
                    next_state=ST_STOP;
                end
                else begin
                    next_state=ST_DATA;
                end
            end
            ST_STOP: begin
                if (baud_cnt_willoverflow ) begin
                    next_state=ST_IDLE;
                end
                else begin
                    next_state=ST_STOP;
                end
            end
            default: begin                    //默认状态同IDLE
                if (i_tx_en) begin
                    next_state=ST_START;
                end
                else begin
                    next_state=ST_IDLE;
                end
            end
        endcase
    end
    //-----------------------------------------------------------------------
    //--状态机第三段：时序逻辑描述输出
    //-----------------------------------------------------------------------
    always@(posedge clk ) begin
        if(!rst_n) begin
            o_txp<=1'b1;
        end
        //复位、初始状态
        else
        case(state)                    //根据当前状态进行输出
            ST_IDLE: begin
                o_txp<=1'b1;
            end
            ST_START: begin
                o_txp<=1'b0;
            end
            ST_DATA: begin
                o_txp<=i_tx_data_r[bits_cnt];
            end
            ST_STOP: begin
                o_txp<=1'b1;
            end
            default: begin
                o_txp<=1'b1;
            end
        endcase
    end

    always@(posedge clk ) begin
        if(!rst_n) begin
            o_tx_done<=1'b0;
        end
        //复位、初始状态
        else
        case(state)                    //根据当前状态进行输出
            ST_STOP: begin
                if (baud_cnt_willoverflow) begin
                    o_tx_done<=1'b1;
                end
            end
            default: begin
                o_tx_done<=1'b0;
            end
        endcase
    end

endmodule



module sync_fifo #(
        parameter DATA_WIDTH = 'd8,     //FIFO 宽度
        parameter DATA_DEPTH = 'd8     //FIFO 深度
    )  (
        input      clk,
        input      rst_n,

        // write signal
        input                         wr_en,         //写入使能，高电平有效
        input       [DATA_WIDTH-1:0]  wr_data,       //要写入的数据
        output                        full,          //写满提示

        // read signal
        input                         rd_en,         //读取使能
        output  reg [DATA_WIDTH-1:0]  rd_data,       //读出数据信号
        output      empty                            //读数据空信号
    );

    reg [DATA_WIDTH-1:0] memory [DATA_DEPTH-1:0];

    wire  [$clog2(DATA_DEPTH)-1:0]  wr_addr_ture;
    wire                            wr_addr_msb;         //写地址最高位
    logic [$clog2(DATA_DEPTH):0]  wr_addr;         //补上最高位后的写地址

    wire  [$clog2(DATA_DEPTH)-1:0]  rd_addr_ture;
    wire                            rd_addr_msb;         //读地址最高位
    logic [$clog2(DATA_DEPTH):0]  rd_addr;         //补上最高位后的读地址

    assign {wr_addr_msb,wr_addr_ture} = wr_addr;
    assign {rd_addr_msb,rd_addr_ture} = rd_addr;

    //最高位不同，低位相同，说明写满了
    assign full= (wr_addr_msb!=rd_addr_msb) && (wr_addr_ture == rd_addr_ture);

    //最高位也相同，说明为空
    assign empty= wr_addr == rd_addr;


    //写入
    always_ff @( posedge clk) begin
        if (!rst_n) begin
            wr_addr<='h0;
        end
        else begin
            if (wr_en && (~full)) begin
                memory[wr_addr_ture]<=wr_data;
                wr_addr<=wr_addr+1'b1;
            end
        end
    end

    //读取
    always_ff @( posedge clk) begin
        if (!rst_n) begin
            rd_addr<='h0;
            rd_data<='h0;
        end
        else begin
            rd_data<=memory[rd_addr_ture];
            if (rd_en && (~empty)) begin
                // rd_data<=memory[rd_addr_ture];
                rd_addr<=rd_addr+1'b1;
            end
        end
    end


endmodule //sync_fifo


module uart_tx_fifo (
        input      clk,
        input      rst_n,
        input      wr_en,
        input   [7:0]  wr_data,
        output      ready,
        output      o_txp
    );

    parameter baud_cycles=25_000_000/5_000_000;

    wire 	full;

    assign  ready=~full;        //FIFO没有满则可以继续写入

    wire [7:0]	rd_data;
    wire 	empty;

    reg         rd_en;

    sync_fifo #(
                  .DATA_WIDTH 		( 'd8 		),
                  .DATA_DEPTH 		( 'd128 	))
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


    wire 	o_tx_done;

    reg i_tx_en;

    uart_tx #(
                .baud_cycles 		( baud_cycles 		))
            u_uart_tx(
                //ports
                .clk       		( clk       		),
                .rst_n     		( rst_n     		),
                .i_tx_data 		( rd_data 		),
                .i_tx_en   		( i_tx_en   		),
                .o_txp     		( o_txp     		),
                .o_tx_done 		( o_tx_done 		)
            );


    enum logic [1:0] { ST_IDLE=2'b00,
                       ST_SEND=2'b01,
                       ST_WAIT=2'b10 } state, next_state;


    always_ff @( posedge clk ) begin
        if (!rst_n) begin
            state<=ST_IDLE;
            rd_en<=1'b0;
            i_tx_en<=1'b0;
        end
        else begin
            case (state)
                ST_IDLE: begin
                    if (!empty) begin
                        rd_en<=1'b1;
                        state<=ST_SEND;
                    end
                    else begin
                        rd_en<=1'b0;
                    end
                end
                ST_SEND: begin
                    rd_en<=1'b0;
                    i_tx_en<=1'b1;
                    state<=ST_WAIT;
                end
                ST_WAIT: begin
                    i_tx_en<=1'b0;
                    if (o_tx_done) begin
                        state<=ST_IDLE;
                    end
                end
            endcase
        end
    end
endmodule //uart_tx_fifo
