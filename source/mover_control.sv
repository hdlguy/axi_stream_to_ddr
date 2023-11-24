//
module mover_control (
    input   logic           clk,
    input   logic           reset,
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

    // command and status resets
    logic[15:0] reset_pipe = -1;
    always_ff @(posedge clk) begin
        if (reset) begin
            reset_pipe <= -1;
        end else begin
            reset_pipe <= {reset_pipe[14:0], 1'b0};
        end
    end
    assign m_axis_s2mm_cmdsts_aresetn = ~reset_pipe[15];
    assign m_axis_mm2s_cmdsts_aresetn = ~reset_pipe[15];

    

    // s2mm command interface
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
    
    // s2mm status interface
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

/*
*/
