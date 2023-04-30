module sdram_ctrl_top (
        input      clk,             //输入时钟：100M
        input      rst_n,

        output      wire  sdr_ck,
        output      wire  sdr_cke,
        output      reg  sdr_csn,sdr_rasn,sdr_casn,sdr_wen,     //cmds
        output      reg [10:0] sdr_addr,                        //addr
        output      reg [1:0] sdr_ba
    );


    assign sdr_cke = 1'b1;          //一直拉高
    assign sdr_ck = ~clk;           //时钟，180度偏移

    //传递给子模块的时候，直接使用cmds
    // logic [3:0] sdr_cmds;

    // assign {sdr_csn,sdr_rasn,sdr_casn,sdr_wen} = sdr_cmds;



    wire [3:0]	init_sdr_cmds;
    wire [10:0]	init_sdr_addr;
    wire [1:0]	init_sdr_ba;
    wire 	init_done;

    wire [3:0]	atref_sdr_cmds;
    wire [10:0]	atref_sdr_addr;
    wire [1:0]	atref_sdr_ba;
    wire 	atref_req;
    wire 	atref_done;
    reg atref_en;

    always_ff @( posedge clk ) begin
        if (!rst_n) begin
            atref_en<=1'b0;
        end
        else begin
            if (atref_req) begin
                atref_en<=1'b1;
            end
            else if (atref_done) begin
                atref_en<=1'b0;
            end
        end
    end


    always_comb begin
        if (!init_done) begin
            {sdr_csn,sdr_rasn,sdr_casn,sdr_wen} = init_sdr_cmds;
            sdr_addr=init_sdr_addr;
            sdr_ba=init_sdr_ba;
        end
        else begin
            {sdr_csn,sdr_rasn,sdr_casn,sdr_wen} = atref_sdr_cmds;
            sdr_addr=atref_sdr_addr;
            sdr_ba=atref_sdr_ba;
        end
    end

    sdram_init #(
                   .INIT_US 		( 200 		),
                   .tRP     		( 3   		),
                   .tRFC    		( 7   		),
                   .tMRD    		( 2   		))
               u_sdram_init(
                   //ports
                   .clk       		( clk       		),
                   .rst_n     		( rst_n     		),
                   .sdr_cmds  		( init_sdr_cmds  		),
                   .sdr_addr  		( init_sdr_addr  		),
                   .sdr_ba    		( init_sdr_ba    		),
                   .init_done 		( init_done 		)
               );




    sdram_atref #(
                    .tRP  		( 3 		),
                    .tRFC 		( 7 		),
                    .tMRD 		( 2 		))
                u_sdram_atref(
                    //ports
                    .clk       		( clk       		),
                    .rst_n     		( rst_n     		),
                    .sdr_cmds  		( atref_sdr_cmds  		),
                    .sdr_addr  		( atref_sdr_addr  		),
                    .sdr_ba    		(atref_sdr_ba    		),
                    .init_done 		( init_done 		),
                    .atref_en   		( atref_en   		),
                    .atref_req  		( atref_req  		),
                    .atref_done 		( atref_done 		)
                );





endmodule //sdram_ctrl_top
