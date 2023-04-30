module clk_1us_gen (
        input      clk,
        output        clk_out
    );
    parameter CLK_IN = 25;

    reg [$clog2(CLK_IN+1)-1:0] cnt;
    initial begin
        cnt=0;
    end

    always @(posedge clk ) begin
        if (cnt==CLK_IN-1) 
            cnt<=0;
        else 
            cnt<=cnt+1'b1;
    end
    assign clk_out = (cnt<CLK_IN/2)?1'b1:1'b0;
endmodule //clk_1us_gen


