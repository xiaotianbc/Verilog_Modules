module sdram_wr (
        input      clk,             //输入时钟：100M
        input      rst_n,

        //SDRAM PHY
        output      reg [3:0]       sdr_cmds,
        output      reg [10:0]      sdr_addr,                        //addr
        output      reg [1:0]       sdr_ba,                           //bank addr
        output      wire  [31:0]    sdr_dq,
        output      wire    [3:0]   sdr_dqm,


        //User interface
        input                       i_wr_en,                //写使能信号
        input           [20:0]      i_wr_addr,              //写地址信号，Bank地址(2)+Row地址(11)+Column地址(8)
        input           [31:0]      i_wr_data,              //写数据信号
        input           [ 7:0]      i_burst_len,            //突发写长度，每次突发写必须在一个Row里，所以长度小于Cloumn数量
        output                      o_wr_ack,               //写响应信号，拉高说明此时正在写数据
        output            reg          o_wr_end,               //写结束信号，写入完成后拉高一个周期
        output            reg          o_wr_output_en          //写入输出使能信号，拉高说明正在从DQ往外写数据
    );


    //等效时钟周期参数
    parameter   tRP=3;              //预充电到刷新的间隔
    parameter   tRFC=7;             //Refresh cycle time, 两次刷新的间隔
    parameter   tMRD=2;             //Mode Register Set cycle time, 设置模式寄存器所需的周期数
    parameter   tRCD=2;             //RAS# to CAS# delay (same bank), 激活完成Row后，写入/读取之前需要等待的周期数
    parameter   tWR=2;             //Write recovery time, 写入后，可以预充电 or 读取的周期



    localparam CMD_NOP = 4'b0111;
    localparam CMD_ACTIVE = 4'b0011;        //激活，选中一个Bank,并激活某一Row
    localparam CMD_PRECHARGE = 4'b0010;        //预充电，其实就是取消选中Row
    localparam CMD_LOAD_MODE_REGISTER = 4'b0000;        //配置模式寄存器
    localparam CMD_AUTO_REFRESH = 4'b0001;        //自动刷新
    localparam CMD_WRITE=4'b0100;               //WRITE (select bank and column, and start WRITE burst)
    localparam CMD_BURST_TERMINATE=4'b0110;               //WRITE (select bank and column, and start WRITE burst)


    //状态机，位数较多，使用格雷码编码，降低亚稳态
    enum logic [3:0] { ST_IDLE=4'b0000,
                       ST_ACT=4'b0001,
                       ST_WAIT_TRCD=4'b0011,
                       ST_START_WR=4'b0010,
                       ST_WR_ING=4'b0110,
                       ST_BURST_TERM=4'b0111,
                       ST_WAIT_TWR=4'b0101,
                       ST_PRE=4'b0100,
                       ST_WAIT_PRE=4'b1100,
                       ST_WR_END=4'b1101
                     } state, next_state;

    logic   [7:0]   fsm_cnt;                //各种状态机公用的计数器


    reg [20:0]      i_wr_addr_r;

    always_ff @( posedge clk ) begin
        if (!rst_n) begin
            state<=ST_IDLE;
        end
        else begin
            state<=next_state;
        end
    end

    always_comb begin
        case (state)
            ST_IDLE:
                next_state=i_wr_en?ST_ACT:ST_IDLE;                 //如果wr_en就进入工作状态
            ST_ACT:
                next_state=ST_WAIT_TRCD;
            ST_WAIT_TRCD:                                         //发送ACT占用一个周期，跳转到WR也需要一个周期，所以是-2
                next_state=(fsm_cnt==tRCD-2)?ST_START_WR:ST_WAIT_TRCD;
            ST_START_WR:                                         //如果i_burst_len为0，则直接终止写入，否则继续写入
                next_state=(fsm_cnt<i_burst_len)?ST_WR_ING:ST_BURST_TERM;
            ST_WR_ING:
                next_state=(fsm_cnt<i_burst_len-1)?ST_WR_ING:ST_BURST_TERM;
            ST_BURST_TERM:
                next_state=ST_WAIT_TWR;
            ST_WAIT_TWR:
                next_state=(fsm_cnt==tWR-2)?ST_PRE:ST_WAIT_TWR;
            ST_PRE:
                next_state=ST_WAIT_PRE;
            ST_WAIT_PRE:
                next_state=(fsm_cnt==tRP-2)?ST_WR_END:ST_WAIT_PRE;
            ST_WR_END:
                next_state=ST_IDLE;
            default:
                next_state=ST_IDLE;
        endcase
    end


    always_ff @( posedge clk ) begin
        if (!rst_n) begin
            fsm_cnt<=0;
        end
        else begin
            //切换状态时，清零
            if (state!=next_state) begin
                fsm_cnt<=0;
            end
            else begin
                fsm_cnt<=fsm_cnt+1'b1;          //如果不切换状态，就自动增加
            end
        end
    end

    //o_wr_ack, 使用组合逻辑，提前一个周期，否则会延迟
    assign o_wr_ack=state==ST_START_WR ||state==ST_WR_ING ;

    always_ff @( posedge clk ) begin
        if (!rst_n) begin
            o_wr_output_en<=1'b0;
        end
        else begin
            o_wr_output_en<=o_wr_ack;
        end
    end


    assign sdr_dq=o_wr_output_en?i_wr_data:'h0;


    always_ff @( posedge clk ) begin
        if (!rst_n) begin
            sdr_cmds<=CMD_NOP;
        end
        else begin
            case (state)
                ST_IDLE:
                    sdr_cmds<=CMD_NOP;
                ST_ACT:
                    sdr_cmds<=CMD_ACTIVE;
                ST_WAIT_TRCD:
                    sdr_cmds<=CMD_NOP;
                ST_START_WR:
                    sdr_cmds<=CMD_WRITE;
                ST_WR_ING:
                    sdr_cmds<=CMD_NOP;
                ST_BURST_TERM:
                    sdr_cmds<=CMD_BURST_TERMINATE;
                ST_WAIT_TWR:
                    sdr_cmds<=CMD_NOP;
                ST_PRE:
                    sdr_cmds<=CMD_PRECHARGE;
                ST_WAIT_PRE,ST_WR_END:
                    sdr_cmds<=CMD_NOP;
                default:
                    sdr_cmds<=CMD_NOP;
            endcase
        end
    end


    //写地址信号，Bank地址(2)+Row地址(11)+Column地址(8)
    always_ff @( posedge clk ) begin
        if (!rst_n) begin
            i_wr_addr_r<='h0;
        end
        else begin
            if (i_wr_en) begin
                i_wr_addr_r<=i_wr_addr;
            end
            else begin
                i_wr_addr_r<=i_wr_addr_r;
            end
        end
    end

    //output      reg [10:0] sdr_addr,                        //addr
    always_ff @( posedge clk ) begin
        if (!rst_n) begin
            sdr_addr<={11{1'b1}};
            sdr_ba<=2'b00;
        end
        else begin
            case (state)
                ST_IDLE: begin
                    sdr_addr<=11'h0;
                    sdr_ba<=2'b00;
                end
                ST_ACT,ST_WAIT_TRCD: begin
                    sdr_addr<=i_wr_addr_r[18:8];    //激活行，输入行地址
                    sdr_ba<=i_wr_addr_r[20:19];     //Bank地址
                end

                ST_START_WR,ST_WR_ING,ST_BURST_TERM,ST_WAIT_TWR: begin
                    sdr_addr<={3'b000,i_wr_addr_r[7:0]} ;    //写入列地址
                    sdr_ba<=i_wr_addr_r[20:19];              //Bank地址
                end

                ST_PRE,ST_WAIT_PRE,ST_WR_END: begin
                    sdr_addr<={11{1'b1}} ;    //所有Bank预充电
                    sdr_ba<=i_wr_addr_r[20:19];     //Bank地址
                end
                default: begin
                    sdr_addr<={11{1'b1}};
                    sdr_ba<=2'b00;
                end
            endcase
        end
    end


    //o_wr_end
    always_ff @( posedge clk ) begin
        if (!rst_n) begin
            o_wr_end<=1'b0;
        end
        else begin
            case (state)
                ST_WR_END: begin
                    o_wr_end<=1'b1;
                end
                default: begin
                    o_wr_end<=1'b0;
                end
            endcase
        end
    end

endmodule //sdram_wr
