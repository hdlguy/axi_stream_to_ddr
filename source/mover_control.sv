//
module mover_control (
    input   logic           clk,
    input   logic           reset,
    //
    input   logic           start,
    output  logic           done,
    //
    output  logic           m_axis_s2mm_cmdsts_aresetn,
    output  logic [71:0]    S_AXIS_S2MM_CMD_tdata,
    output  logic           S_AXIS_S2MM_CMD_tvalid,
    input   logic           S_AXIS_S2MM_CMD_tready,
    //
    input   logic [7:0]     M_AXIS_S2MM_STS_tdata,
    input   logic [0:0]     M_AXIS_S2MM_STS_tkeep,
    input   logic           M_AXIS_S2MM_STS_tlast,
    output  logic           M_AXIS_S2MM_STS_tready,
    input   logic           M_AXIS_S2MM_STS_tvalid,
    //
    output  logic           m_axis_mm2s_cmdsts_aresetn,
    output  logic [71:0]    S_AXIS_MM2S_CMD_tdata,
    output  logic           S_AXIS_MM2S_CMD_tvalid,   
    input   logic           S_AXIS_MM2S_CMD_tready,
    //
    input   logic [7:0]     M_AXIS_MM2S_STS_tdata,
    input   logic [0:0]     M_AXIS_MM2S_STS_tkeep,
    input   logic           M_AXIS_MM2S_STS_tlast,
    output  logic           M_AXIS_MM2S_STS_tready,
    input   logic           M_AXIS_MM2S_STS_tvalid
);

    localparam int transfer_start = 32'h8000_0000;
    localparam int transfer_size = 2**28;
    localparam logic[22:0] btt = 23'h00_1000;
    localparam int Ncommand = transfer_size/btt;

    localparam logic[3:0] s2mm_tag = 4'hA;
    localparam logic[3:0] mm2s_tag = 4'hB;
    logic[31:0] mm_start;
    assign S_AXIS_S2MM_CMD_tdata = {4'b0000, s2mm_tag, mm_start, 8'b0000_0000, 1'b1, btt};
    assign S_AXIS_MM2S_CMD_tdata = {4'b0000, mm2s_tag, mm_start, 8'b0000_0000, 1'b1, btt};


    // resets
    logic[31:0] reset_pipe = -1;
    always_ff @(posedge clk) begin
        if (reset) begin
            reset_pipe <= -1;
        end else begin
            reset_pipe <= {reset_pipe[$bits(reset_pipe)-2:0], 1'b0};
        end
    end
    logic aresetn;
    assign aresetn = ~reset_pipe[15];
    assign m_axis_s2mm_cmdsts_aresetn = aresetn;
    assign m_axis_mm2s_cmdsts_aresetn = aresetn;
    logic control_reset;
    assign control_reset = reset_pipe[31];
 
   
    // state machine
    logic[3:0] state=0, next_state;
    always_ff @(posedge clk) begin
        if (control_reset) begin
            state <= 0;
        end else begin
            state <= next_state;
        end
    end
    
    logic inc_cmd_count, clr_cmd_count;
    logic[22:0] cmd_count;
    always_comb begin

        // defaults
        next_state = state;
        S_AXIS_S2MM_CMD_tvalid = 0;
        S_AXIS_MM2S_CMD_tvalid = 0;
        inc_cmd_count = 0;
        clr_cmd_count = 0;
        done = 0;
        
        case (state)

            0: begin
                done = 1;
                clr_cmd_count <= 1;
                if (start) begin
                    next_state = 1;
                end
            end 
            
            // stream to memory mapped
            1: begin
                S_AXIS_S2MM_CMD_tvalid = 1;
                if (S_AXIS_S2MM_CMD_tready) begin
                    next_state = 2;
                end
            end 
            
            2: begin
                if (M_AXIS_S2MM_STS_tvalid) begin
                    inc_cmd_count = 1;
                    if (cmd_count == (Ncommand-1)) begin
                        next_state = 3;
                    end else begin
                        next_state = 1;
                    end
                end
            end 
            
            3: begin
                clr_cmd_count <= 1;
                next_state = 4;
            end 
            
            // memory mapped to stream
            4: begin
                S_AXIS_MM2S_CMD_tvalid = 1;
                if (S_AXIS_MM2S_CMD_tready) begin
                    next_state = 5;
                end
            end 
            
            5: begin
                if (M_AXIS_MM2S_STS_tvalid) begin
                    inc_cmd_count = 1;
                    if (cmd_count == (Ncommand-1)) begin
                        next_state = 6;
                    end else begin
                        next_state = 4;
                    end
                end
            end 
            
            6: begin
                next_state = 0;
            end 
            
            default: begin
                next_state = 0;
            end
            
        endcase

    end
    
    
    assign M_AXIS_S2MM_STS_tready = 1;
    assign M_AXIS_MM2S_STS_tready = 1;
        

    always_ff @(posedge clk) begin
        if (clr_cmd_count) begin
            cmd_count <= 0;
            mm_start <= transfer_start;
        end else begin
            if (inc_cmd_count) begin
                cmd_count <= cmd_count + 1;
                mm_start <= mm_start + btt;
            end
        end
    end
    

endmodule
    

/*
    // s2mm command
    localparam logic[22:0] s2mm_btt = 23'h00_1000;
    localparam logic s2mm_type = 1'b1;
    localparam logic[3:0] s2mm_tag = 4'hA;
    logic[31:0] s2mm_start = 32'h0000_0000;
    assign S_AXIS_S2MM_CMD_tdata = {4'b0000, s2mm_tag, s2mm_start, 8'b0000_0000, s2mm_type, s2mm_btt};
    always_ff @(posedge clk) begin
        if (reset) begin
            S_AXIS_S2MM_CMD_tvalid <= 1;
        end else begin
            if (S_AXIS_S2MM_CMD_tready) begin
                S_AXIS_S2MM_CMD_tvalid <= 0;
            end
            if ((S_AXIS_S2MM_CMD_tready) & (S_AXIS_S2MM_CMD_tvalid)) begin
                s2mm_start <= s2mm_start + s2mm_btt; // increment the start address.
            end
            if (M_AXIS_S2MM_STS_tvalid) S_AXIS_S2MM_CMD_tvalid <= 1; // if the command is complete, run it again            
        end
    end
    
    // s2mm status
    assign M_AXIS_S2MM_STS_tready = 1;



    
    // mm2s command
    localparam logic[22:0] mm2s_btt = 23'h00_1000;
    localparam logic mm2s_type = 1'b1;
    localparam logic[3:0] mm2s_tag = 4'hA;
    logic[31:0] mm2s_start = 32'h0000_0000;
    assign S_AXIS_MM2S_CMD_tdata = {4'b0000, mm2s_tag, mm2s_start, 8'b0000_0000, mm2s_type, mm2s_btt};
    assign S_AXIS_MM2S_CMD_tvalid = 0;
    
    // mm2s status
    assign M_AXIS_MM2S_STS_tready = 1;


endmodule

*/
