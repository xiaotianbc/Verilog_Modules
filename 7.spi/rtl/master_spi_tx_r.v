module master_spi_tx_r (
        input      clk,
        input      rst,     //高电平复位

        //用户程序接口
        input           [7:0]   wdata,              //写数据
        input                   wvalid,             //传输握手信号
        output    reg           wready,          //传输完成信号
        output    reg   [7:0]   rdata,      //读出数据

        //IO接口
        output                  spi_mosi_o,
        output   reg            spi_sck_o,
        input                   spi_miso_i
    );


    parameter CLK_DIV=8;        //分频数
    localparam CLK_CNT_MAX=CLK_DIV-1;        //分频计数
    localparam CLK_CNT_MAX2=CLK_DIV/2-1;        //分频计数


    reg [$clog2(CLK_CNT_MAX)-1:0]   clk_cnt;

    reg tx_flag;        //工作指示

    wire clk_pos=(clk_cnt==CLK_CNT_MAX) && tx_flag;          //上升沿时间指示

    wire clk_neg=(clk_cnt==CLK_CNT_MAX2) && tx_flag;         //下降沿时间指示



    reg [7:0] spi_tx_data_r;

    reg [3:0] bts;      //剩余需要发送的数据位数

    always @(posedge clk ) begin
        if (rst) begin
            tx_flag<=1'b0;
        end
        else begin
            if (~tx_flag && wvalid) begin
                tx_flag<=1'b1;
            end
            else if (bts==0 && clk_neg) begin       //在下降沿给出的时候关闭发送状态
                tx_flag<=1'b0;
            end
        end
    end

    always @(posedge clk ) begin
        if (rst) begin
            clk_cnt<=0;
        end
        else begin
            if (tx_flag)
                if (clk_cnt==CLK_CNT_MAX)
                    clk_cnt<='d0;
                else
                    clk_cnt<=clk_cnt+1'b1;
            else
                clk_cnt<='d0;
        end
    end

    //如果从在非工作状态收到wvalid，就把数据锁存到spi_tx_data_r
    always @(posedge clk ) begin
        if (rst) begin
            spi_tx_data_r<='h00;
        end
        else             if (~tx_flag && wvalid) begin
            spi_tx_data_r<=wdata;
        end
        else if (clk_neg && bts!=8) begin         //SPI在时钟信号下降沿的时候移位
            spi_tx_data_r<={spi_tx_data_r[6:0],spi_tx_data_r[7]};
        end
    end

    always @(posedge clk ) begin
        if (rst) begin
            bts<='d0;
        end
        else if (~tx_flag && wvalid) begin
            bts<='d8;
        end
        else if (bts>0 && clk_pos) begin     //   每个时钟的上升沿，从机采样一次
            bts<=bts-1;
        end

    end

    always @(posedge clk ) begin
        if (rst) begin
            spi_sck_o<=1'b0;
        end
        else begin
            if (~tx_flag) begin
                spi_sck_o<=1'b0;
            end
            else  if (clk_pos) begin
                spi_sck_o<=1'b1;
            end
            else if (clk_neg) begin
                spi_sck_o<=1'b0;
            end
        end
    end

    assign spi_mosi_o=spi_tx_data_r[7];

    always @(posedge clk ) begin
        if (rst) begin
            wready<=1'b0;
        end
        else begin
            if (~wvalid || (wvalid && wready)) begin
                wready<=1'b0;
            end
            else if (bts==0 && wvalid && clk_neg) begin
                wready<=1'b1;
            end
        end
    end

    //rdata

    always @(posedge clk ) begin
        if (rst) begin
            rdata<='d0;
        end
        else begin
            if (clk_pos) begin
                rdata<={rdata[6:0],spi_miso_i};
            end
        end
    end

endmodule //master_spi_tx_r
