// This module is an experiment to see how to stream ADC data to a DDR3 memory and then read it back.
module top(
    input   logic   clkin
);

    logic clk;
    assign clk = clkin;   

    logic           reset_n;
    logic           m_axis_s2mm_cmdsts_aresetn;
    logic [7:0]     M_AXIS_S2MM_STS_tdata;
    logic [0:0]     M_AXIS_S2MM_STS_tkeep;
    logic           M_AXIS_S2MM_STS_tlast;
    logic           M_AXIS_S2MM_STS_tready;
    logic           M_AXIS_S2MM_STS_tvalid;
    
    logic [71:0]    S_AXIS_S2MM_CMD_tdata;
    logic           S_AXIS_S2MM_CMD_tready;
    logic           S_AXIS_S2MM_CMD_tvalid;
    logic           s2mm_err;
    
    logic [63:0]    S_AXIS_S2MM_tdata;
    logic [3:0]     S_AXIS_S2MM_tkeep;
    logic           S_AXIS_S2MM_tlast;
    logic           S_AXIS_S2MM_tready;
    logic           S_AXIS_S2MM_tvalid;
    
    logic [27:0]    bram0_addr;
    logic           bram0_clk;
    logic [31:0]    bram0_din;
    logic [31:0]    bram0_dout;
    logic           bram0_en;
    logic           bram0_rst;
    logic [3:0]     bram0_we;
    

    // IPI Block Diagram, contains datamover and axi bram controller
    system system_i (
        .clk(clk),
        .reset_n(reset_n),
        // mover status
        .m_axis_s2mm_cmdsts_aresetn(m_axis_s2mm_cmdsts_aresetn),
        .M_AXIS_S2MM_STS_tdata  (M_AXIS_S2MM_STS_tdata),
        .M_AXIS_S2MM_STS_tkeep  (M_AXIS_S2MM_STS_tkeep),
        .M_AXIS_S2MM_STS_tlast  (M_AXIS_S2MM_STS_tlast),
        .M_AXIS_S2MM_STS_tready (M_AXIS_S2MM_STS_tready),
        .M_AXIS_S2MM_STS_tvalid (M_AXIS_S2MM_STS_tvalid),
        // mover command
        .S_AXIS_S2MM_CMD_tdata  (S_AXIS_S2MM_CMD_tdata),
        .S_AXIS_S2MM_CMD_tready (S_AXIS_S2MM_CMD_tready),
        .S_AXIS_S2MM_CMD_tvalid (S_AXIS_S2MM_CMD_tvalid),
        .s2mm_err(s2mm_err),
        // mover stream in
        .S_AXIS_S2MM_tdata      (S_AXIS_S2MM_tdata),
        .S_AXIS_S2MM_tkeep      (S_AXIS_S2MM_tkeep),
        .S_AXIS_S2MM_tlast      (S_AXIS_S2MM_tlast),
        .S_AXIS_S2MM_tready     (S_AXIS_S2MM_tready),
        .S_AXIS_S2MM_tvalid     (S_AXIS_S2MM_tvalid),
        //
        .bram0_addr             (bram0_addr),
        .bram0_clk              (bram0_clk),
        .bram0_din              (bram0_din),
        .bram0_dout             (bram0_dout),
        .bram0_en               (bram0_en),
        .bram0_rst              (bram0_rst),
        .bram0_we               (bram0_we)
    );
    
    //test_bram bram_inst (.clka(bram0_clk), .rsta(bram0_rst), .ena(bram0_en), .wea(bram0_we), .addra(bram0_addr[13:2]), .dina(bram0_din), .douta(bram0_dout), .rsta_busy());

    
    // system reset
    logic[15:0] reset_pipe = -1;
    always_ff @(posedge clk) reset_pipe <= {reset_pipe[14:0], 1'b0};
    logic reset;
    assign reset = reset_pipe[7];
    assign reset_n = ~reset;
    assign m_axis_s2mm_cmdsts_aresetn = ~reset_pipe[15];

    
    // data generator for write memory
    // the adc will produce data once per seven cycles
    logic data_fifo_empty, data_fifo_wr, data_fifo_full;
    logic[63:0] wdata = -1;
    logic[2:0] fifo_wr_count=6;
    always_ff @(posedge clk) begin
        fifo_wr_count <= fifo_wr_count - 1;
        if (fifo_wr_count == 0) begin
            data_fifo_wr <= 1;
            wdata <= wdata + 1;
        end else begin
            data_fifo_wr <= 0;
        end
    end
    assign S_AXIS_S2MM_tkeep = 4'b1111;
    assign S_AXIS_S2MM_tlast = 0;

    // buffer the write data in a fifo
    xpm_sync_fifo #(.W(64), .D(512)) data_fifo_inst (
        .clk(clk), .srst(1'b0), .din(wdata), .wr_en(data_fifo_wr), .full(data_fifo_full),
        .rd_en(S_AXIS_S2MM_tready), .dout(S_AXIS_S2MM_tdata), .empty(data_fifo_empty)
    );
    assign S_AXIS_S2MM_tvalid = ~data_fifo_empty;
    
    
    
    // command interface
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
    
    // status interface
    assign M_AXIS_S2MM_STS_tready = 1;
    
    top_ila ila_inst (.clk(clk), .probe0({M_AXIS_S2MM_STS_tready, M_AXIS_S2MM_STS_tvalid, S_AXIS_S2MM_CMD_tready, S_AXIS_S2MM_CMD_tvalid, bram0_en, bram0_rst, bram0_we, bram0_addr, bram0_din})); // 70
    
        
endmodule

/*
module xpm_sync_fifo #(
    parameter int W = 16,   // width
    parameter int D = 64   // depth
) (
    input   logic           clk,
    input   logic           srst,
    input   logic[W-1:0]    din,
    input   logic           wr_en,
    output  logic           full,
        
    input   logic           rd_en,
    output  logic[W-1:0]    dout,
    output  logic           empty
);
*/
