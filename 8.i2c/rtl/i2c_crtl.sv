module i2c_ctrl (
    input      clk,     //below with 200KHz
    input      rst,     //active when high

    output      i2c_scl,
    inout       i2c_sda,

    input       cmd,        // 0 = write, 1 = read
    input       cmd_en,     // 1 = enable,   0 = NOP

    input     [6:0]  slave_addr      

    
);
    


enum logic [2:0] { ST_IDLE =3'b000,ST_START =3'b001,ST_SEND_BITS=3'd2,ST_WAIT_ACK=3'd3,ST_STOP=3'd4 } state, next_state;


always_ff @( posedge clk ) begin 
    if (rst) begin
        state<=ST_IDLE;
    end
    else begin
        state<=next_state;
    end
end

always_comb begin 
    case (state)
        ST_IDLE:next_state=cmd_en? ST_START:ST_IDLE;
        ST_WORK:next_state=cmd_en? ST_WORK:ST_IDLE;
        
    endcase
end



endmodule //i2c_ctrl
