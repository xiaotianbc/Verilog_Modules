module sdram_init (
        input      clk,             //输入时钟：100M
        input      rst_n,

        output      reg [3:0] sdr_cmds,
        output      reg [10:0] sdr_addr,                        //addr
        output      reg [1:0] sdr_ba,                           //bank addr
        output      wire         init_done                       //初始化完成信号
    );


    parameter INIT_US = 200;        //初始化前的等待时间
    localparam  INIT_CNTS= INIT_US*1000/10;        //初始化前的等待时钟数


    //等效时钟周期参数
    parameter   tRP=3;              //预充电到刷新的间隔
    parameter   tRFC=7;             //Refresh cycle time, 两次刷新的间隔
    parameter   tMRD=2;             //Mode Register Set cycle time, 设置模式寄存器所需的周期数



    assign sdr_cke = 1'b1;          //一直拉高
    assign sdr_ck = ~clk;           //时钟，180度偏移




    localparam CMD_NOP = 4'b0111;
    localparam CMD_ACTIVE = 4'b0011;        //激活，选中一个Bank,并激活某一Row
    localparam CMD_PRECHARGE = 4'b0010;        //预充电，其实就是取消选中Row
    localparam CMD_LOAD_MODE_REGISTER = 4'b0000;        //配置模式寄存器
    localparam CMD_AUTO_REFRESH = 4'b0001;        //自动刷新


    assign sdr_ba = 2'b00;          //默认对所有bank初始化


    logic [$clog2(INIT_CNTS)-1:0] line_cnt;

    logic       wait_done;              //上电等待信号


    always_ff @( posedge clk    ) begin
        if (!rst_n) begin
            line_cnt<='h0;
        end
        else begin
            if (!wait_done) begin
                line_cnt<=line_cnt+1'b1;
                if (line_cnt==INIT_CNTS-1) begin
                    line_cnt<=0;
                end
            end
            else begin
                if (line_cnt<(1+tRP+tRFC+tRFC+tMRD)) begin
                    line_cnt<=line_cnt+1'b1;
                end
            end
        end
    end

    always_ff @( posedge clk ) begin
        if (!rst_n) begin
            wait_done<=1'b0;
        end
        else begin
            if (!wait_done) begin
                if (line_cnt==INIT_CNTS-1) begin
                    wait_done<=1'b1;
                end
            end
        end
    end

    always_ff @( posedge clk ) begin
        if (!rst_n) begin
            sdr_cmds<=CMD_NOP;
        end
        else begin
            if (!wait_done) begin
                sdr_cmds<=CMD_NOP;
            end
            else begin
                case (line_cnt)
                    (0):sdr_cmds<=CMD_NOP;
                    (1):sdr_cmds<=CMD_PRECHARGE;                       //预充电
                    (1+tRP):sdr_cmds<=CMD_AUTO_REFRESH;              //第一次自动刷新
                    (1+tRP+tRFC):sdr_cmds<=CMD_AUTO_REFRESH;         //第二次自动刷新
                    (1+tRP+tRFC+tRFC):sdr_cmds<=CMD_LOAD_MODE_REGISTER;     //配置模式寄存器
                    default:
                        sdr_cmds<=CMD_NOP;      //默认是NOP
                endcase
            end
        end
    end

    always_ff @( posedge clk ) begin
        if (!rst_n) begin
            sdr_addr<={11{1'b1}};
        end
        else begin
            if (!wait_done) begin
                sdr_addr<={11{1'b1}};
            end
            else begin
                case (line_cnt)
                    (1):sdr_addr<={11{1'b1}};                       //全Bank预充电
                    (1+tRP+tRFC+tRFC):sdr_addr<={1'b0,1'b0,2'b00,3'b011,1'b0,3'b111};     //配置模式寄存器, CL=2,全页突发写
                    default:
                        sdr_addr<={11{1'b1}};
                endcase
            end
        end
    end


    assign init_done = wait_done && (line_cnt==(1+tRP+tRFC+tRFC+tMRD));


endmodule //sdram_init
