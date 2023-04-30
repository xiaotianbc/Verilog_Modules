module sdram_atref (
        input      clk,             //输入时钟：100M
        input      rst_n,

        //SDRAM PHY
        output      reg [3:0] sdr_cmds,
        output      wire [10:0] sdr_addr,                        //addr
        output      wire [1:0] sdr_ba,                           //bank addr

        //User interface
        input      wire         init_done,                       //初始化完成信号
        input      wire         atref_en,                       //刷新使能信号
        output      wire         atref_req,                       //刷新请求信号
        output      reg         atref_done                       //刷新完成信号
    );


    localparam AUTO_REF_CYCLES = 64_000*100/4096;           //64ms 刷新4096次
    //等效时钟周期参数
    parameter   tRP=3;              //预充电到刷新的间隔
    parameter   tRFC=7;             //Refresh cycle time, 两次刷新的间隔
    parameter   tMRD=2;             //Mode Register Set cycle time, 设置模式寄存器所需的周期数


    localparam CMD_NOP = 4'b0111;
    localparam CMD_ACTIVE = 4'b0011;        //激活，选中一个Bank,并激活某一Row
    localparam CMD_PRECHARGE = 4'b0010;        //预充电，其实就是取消选中Row
    localparam CMD_LOAD_MODE_REGISTER = 4'b0000;        //配置模式寄存器
    localparam CMD_AUTO_REFRESH = 4'b0001;        //自动刷新


    //ba 刷新模块不需要关心
    assign sdr_ba = 2'b00;
    assign sdr_addr= {11{1'b1}};



    enum logic [3:0] { ST_INIT=4'b0001,
                       ST_REF_CNT=4'b0010,
                       ST_REF=4'b0100,
                       ST_REF_DONE=4'b1000 } state, next_state;



    logic [$clog2(AUTO_REF_CYCLES)-1:0]     ref_cycles_cnt;

    //刷新时的线性序列机
    logic [$clog2(tRP+tRFC<<1)-1:0]     line_cnt;

    wire ref_end=(line_cnt==(tRP+tRFC<<1));          //刷新完成的判断依据


    always_ff @( posedge clk ) begin
        if (!rst_n) begin
            state<=ST_INIT;
        end
        else begin
            state<=next_state;
        end
    end

    always_comb begin
        case (state)
            ST_INIT:
                next_state=init_done?ST_REF_CNT:ST_INIT;
            ST_REF_CNT:
                next_state=atref_en?ST_REF:ST_REF_CNT;
            ST_REF:
                next_state=ref_end?ST_REF_DONE:ST_REF;
            ST_REF_DONE:
                next_state=ST_REF_CNT;
        endcase
    end


    //ref_cycles_cnt
    always_ff @( posedge clk ) begin
        if (!rst_n) begin
            ref_cycles_cnt<=0;
        end
        else begin
            if (state==ST_REF_CNT) begin
                ref_cycles_cnt<=ref_cycles_cnt+1'b1;
            end
            else begin
                ref_cycles_cnt<=0;
            end
        end
    end

    //什么时候发出刷新请求, 这里留出20%的时间余量
    assign atref_req = state==ST_REF_CNT && (ref_cycles_cnt>AUTO_REF_CYCLES*0.8);

    //line_cnt

    always_ff @( posedge clk) begin
        if (!rst_n) begin
            line_cnt<=0;
        end
        else begin
            if (state==ST_REF) begin
                line_cnt<=line_cnt+1'b1;
            end
            else begin
                line_cnt<=0;
            end
        end
    end

    //atref_done ，刷新完成后，上升1个周期
    always_ff @( posedge clk) begin
        if (!rst_n) begin
            atref_done<=1'b0;
        end
        else begin
            if (state==ST_REF && ref_end) begin
                atref_done<=1'b1;
            end
            else begin
                atref_done<=1'b0;
            end
        end
    end

    always_ff @( posedge clk) begin
        if (!rst_n) begin
            atref_done<=1'b0;
        end
        else begin
            if (state==ST_REF && ref_end) begin
                atref_done<=1'b1;
            end
            else begin
                atref_done<=1'b0;
            end
        end
    end


    always_ff @( posedge clk) begin
        if (!rst_n) begin
            sdr_cmds<=CMD_NOP;
        end
        else begin
            if (state==ST_REF ) begin
                case (line_cnt)
                    (0): sdr_cmds<=CMD_PRECHARGE;
                    (0+tRP): sdr_cmds<=CMD_AUTO_REFRESH;
                    (0+tRP+tRFC): sdr_cmds<=CMD_AUTO_REFRESH;
                    default:
                        sdr_cmds<=CMD_NOP;
                endcase
            end
            else begin
                sdr_cmds<=CMD_NOP;
            end
        end
    end


endmodule //sdram_atref

