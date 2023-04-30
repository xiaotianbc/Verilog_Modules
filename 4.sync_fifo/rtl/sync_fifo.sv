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
