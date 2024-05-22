// This module is a working example of how to stream data to a ddr4 memory and then read it back.
module top(
    //    
    input  logic       sysclk_n,
    input  logic       sysclk_p,
    //
    input   logic   reset_in_n,
    //
    output  logic[1:0]  led,
    // 
    output logic        ddr4_act_n,
    output logic [16:0] ddr4_adr,
    output logic [1:0]  ddr4_ba,
    output logic [0:0]  ddr4_bg,
    output logic [0:0]  ddr4_ck_c,
    output logic [0:0]  ddr4_ck_t,
    output logic [0:0]  ddr4_cke,
    output logic [0:0]  ddr4_cs_n,
    inout  logic [1:0]  ddr4_dm_n,
    inout  logic [15:0] ddr4_dq,
    inout  logic [1:0]  ddr4_dqs_c,
    inout  logic [1:0]  ddr4_dqs_t,
    output logic [0:0]  ddr4_odt,
    output logic        ddr4_reset_n
);

//    logic clk, sysclk;
//    IBUFDS IBUFDS_sysclk (.O(sysclk), .I(sysclk_p), .IB(sysclk_n));
//    BUFG BUFG_sysclk (.O(clk), .I(sysclk));

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
    
    logic           m_axis_mm2s_cmdsts_aresetn;
    logic [7:0]     M_AXIS_MM2S_STS_tdata;
    logic [0:0]     M_AXIS_MM2S_STS_tkeep;
    logic           M_AXIS_MM2S_STS_tlast;
    logic           M_AXIS_MM2S_STS_tready;
    logic           M_AXIS_MM2S_STS_tvalid;
    
    logic [71:0]    S_AXIS_MM2S_CMD_tdata;
    logic           S_AXIS_MM2S_CMD_tready;
    logic           S_AXIS_MM2S_CMD_tvalid;   
    logic           mm2s_err;
         
    logic [63:0]    M_AXIS_MM2S_tdata;
    logic [7:0]     M_AXIS_MM2S_tkeep;
    logic           M_AXIS_MM2S_tlast;
    logic           M_AXIS_MM2S_tready;
    logic           M_AXIS_MM2S_tvalid;
    
    logic [27:0]    bram0_addr;
    logic           bram0_clk;
    logic [31:0]    bram0_din;
    logic [31:0]    bram0_dout;
    logic           bram0_en;
    logic           bram0_rst;
    logic [3:0]     bram0_we;
    
    logic           axi_aclk;


    // IPI Block Diagram, contains datamover and axi bram controller
    system system_i (
        //
        .sysclk_clk_p           (sysclk_p),
        .sysclk_clk_n           (sysclk_n),
        .reset_n                (reset_n),
        //
        .axi_aclk               (axi_aclk),
        //
        // s2mm status
        .m_axis_s2mm_cmdsts_aresetn(m_axis_s2mm_cmdsts_aresetn),
        .M_AXIS_S2MM_STS_tdata  (M_AXIS_S2MM_STS_tdata),
        .M_AXIS_S2MM_STS_tkeep  (M_AXIS_S2MM_STS_tkeep),
        .M_AXIS_S2MM_STS_tlast  (M_AXIS_S2MM_STS_tlast),
        .M_AXIS_S2MM_STS_tready (M_AXIS_S2MM_STS_tready),
        .M_AXIS_S2MM_STS_tvalid (M_AXIS_S2MM_STS_tvalid),
        //
        // s2mm command
        .S_AXIS_S2MM_CMD_tdata  (S_AXIS_S2MM_CMD_tdata),
        .S_AXIS_S2MM_CMD_tready (S_AXIS_S2MM_CMD_tready),
        .S_AXIS_S2MM_CMD_tvalid (S_AXIS_S2MM_CMD_tvalid),
        .s2mm_err               (s2mm_err),
        //
        // s2mm stream in
        .S_AXIS_S2MM_tdata      (S_AXIS_S2MM_tdata),
        .S_AXIS_S2MM_tkeep      (S_AXIS_S2MM_tkeep),
        .S_AXIS_S2MM_tlast      (S_AXIS_S2MM_tlast),
        .S_AXIS_S2MM_tready     (S_AXIS_S2MM_tready),
        .S_AXIS_S2MM_tvalid     (S_AXIS_S2MM_tvalid),
        //
        // mm2s status
        .m_axis_mm2s_cmdsts_aresetn(m_axis_mm2s_cmdsts_aresetn),
        .M_AXIS_MM2S_STS_tdata  (M_AXIS_MM2S_STS_tdata),
        .M_AXIS_MM2S_STS_tkeep  (M_AXIS_MM2S_STS_tkeep),
        .M_AXIS_MM2S_STS_tlast  (M_AXIS_MM2S_STS_tlast),
        .M_AXIS_MM2S_STS_tready (M_AXIS_MM2S_STS_tready),
        .M_AXIS_MM2S_STS_tvalid (M_AXIS_MM2S_STS_tvalid),
        //
        // mm2s command
        .S_AXIS_MM2S_CMD_tdata  (S_AXIS_MM2S_CMD_tdata),
        .S_AXIS_MM2S_CMD_tready (S_AXIS_MM2S_CMD_tready),
        .S_AXIS_MM2S_CMD_tvalid (S_AXIS_MM2S_CMD_tvalid),  
        .mm2s_err               (mm2s_err),      
        //
        // mm2s stream out
        .M_AXIS_MM2S_tdata      (M_AXIS_MM2S_tdata),
        .M_AXIS_MM2S_tkeep      (M_AXIS_MM2S_tkeep),
        .M_AXIS_MM2S_tlast      (M_AXIS_MM2S_tlast),
        .M_AXIS_MM2S_tready     (M_AXIS_MM2S_tready),
        .M_AXIS_MM2S_tvalid     (M_AXIS_MM2S_tvalid),
        //
        // bram control
        .bram0_addr             (bram0_addr),
        .bram0_clk              (bram0_clk),
        .bram0_din              (bram0_din),
        .bram0_dout             (bram0_dout),
        .bram0_en               (bram0_en),
        .bram0_rst              (bram0_rst),
        .bram0_we               (bram0_we),
        //
        .ddr4_act_n     (ddr4_act_n),
        .ddr4_adr       (ddr4_adr),
        .ddr4_ba        (ddr4_ba),
        .ddr4_bg        (ddr4_bg),
        .ddr4_ck_c      (ddr4_ck_c),
        .ddr4_ck_t      (ddr4_ck_t),
        .ddr4_cke       (ddr4_cke),
        .ddr4_cs_n      (ddr4_cs_n),
        .ddr4_dm_n      (ddr4_dm_n),
        .ddr4_dq        (ddr4_dq),
        .ddr4_dqs_c     (ddr4_dqs_c),
        .ddr4_dqs_t     (ddr4_dqs_t),
        .ddr4_odt       (ddr4_odt),
        .ddr4_reset_n   (ddr4_reset_n)
    );
    
    test_bram bram_inst (.clka(bram0_clk), .rsta(bram0_rst), .ena(bram0_en), .wea(bram0_we), .addra(bram0_addr[13:2]), .dina(bram0_din), .douta(bram0_dout), .rsta_busy());

    
    // system reset
    logic[15:0] reset_pipe = -1;
    always_ff @(posedge axi_aclk) begin 
        if (~reset_in_n) begin
            reset_pipe <= -1;
        end else begin
            reset_pipe <= {reset_pipe[14:0], 1'b0};
        end
    end
    logic reset;
    assign reset = reset_pipe[7];
    assign reset_n = ~reset;
    

    
    // s2mm data generator
    // the adc will produce data once per seven cycles
    logic data_fifo_empty, data_fifo_wr, data_fifo_full;
    logic[63:0] wdata = -1;
    logic[2:0] fifo_wr_count=6;
    always_ff @(posedge axi_aclk) begin
        if (fifo_wr_count == 0) begin
            data_fifo_wr <= 1;
            wdata <= wdata + 1;
            fifo_wr_count <= 6;
        end else begin
            data_fifo_wr <= 0;
            fifo_wr_count <= fifo_wr_count - 1;
        end
    end
    assign S_AXIS_S2MM_tkeep = 4'b1111;
    assign S_AXIS_S2MM_tlast = 0;

    // buffer the s2mm data in a fifo
    logic fifo_srst;
    xpm_sync_fifo #(.W(64), .D(512)) data_fifo_inst (
        .clk(axi_aclk), .srst(fifo_srst), .din(wdata), .wr_en(data_fifo_wr), .full(data_fifo_full),
        .rd_en(S_AXIS_S2MM_tready), .dout(S_AXIS_S2MM_tdata), .empty(data_fifo_empty)
    );
    assign S_AXIS_S2MM_tvalid = ~data_fifo_empty;


    // mm2s data
    // will go out on 100Mbps Ethernet link so 1 read every few clock cycles.
    logic[2:0] mm2s_rd_div=-1;
    always_ff @(posedge axi_aclk) begin
        mm2s_rd_div <= mm2s_rd_div - 1;
        if (mm2s_rd_div == 0) M_AXIS_MM2S_tready <= 1; else  M_AXIS_MM2S_tready <= 0;
    end
    
    
    // datamover control
    logic mover_start=0, mover_done;
    assign fifo_srst = mover_done;
    mover_control control_inst (
        //
        .clk                        (axi_aclk),
        .reset                      (reset),
        //
        .start                      (mover_start),
        .done                       (mover_done),
        //
        .m_axis_s2mm_cmdsts_aresetn (m_axis_s2mm_cmdsts_aresetn ),
        .S_AXIS_S2MM_CMD_tdata      (S_AXIS_S2MM_CMD_tdata),
        .S_AXIS_S2MM_CMD_tvalid     (S_AXIS_S2MM_CMD_tvalid),
        .S_AXIS_S2MM_CMD_tready     (S_AXIS_S2MM_CMD_tready),
        //
        .M_AXIS_S2MM_STS_tdata      (M_AXIS_S2MM_STS_tdata),
        .M_AXIS_S2MM_STS_tkeep      (M_AXIS_S2MM_STS_tkeep),
        .M_AXIS_S2MM_STS_tlast      (M_AXIS_S2MM_STS_tlast),
        .M_AXIS_S2MM_STS_tready     (M_AXIS_S2MM_STS_tready),
        .M_AXIS_S2MM_STS_tvalid     (M_AXIS_S2MM_STS_tvalid),
        //
        .m_axis_mm2s_cmdsts_aresetn (m_axis_mm2s_cmdsts_aresetn),
        .S_AXIS_MM2S_CMD_tdata      (S_AXIS_MM2S_CMD_tdata),
        .S_AXIS_MM2S_CMD_tvalid     (S_AXIS_MM2S_CMD_tvalid),   
        .S_AXIS_MM2S_CMD_tready     (S_AXIS_MM2S_CMD_tready),
        //
        .M_AXIS_MM2S_STS_tdata      (M_AXIS_MM2S_STS_tdata),
        .M_AXIS_MM2S_STS_tkeep      (M_AXIS_MM2S_STS_tkeep),
        .M_AXIS_MM2S_STS_tlast      (M_AXIS_MM2S_STS_tlast),
        .M_AXIS_MM2S_STS_tready     (M_AXIS_MM2S_STS_tready),
        .M_AXIS_MM2S_STS_tvalid     (M_AXIS_MM2S_STS_tvalid)
    );

    // restart the machine after a delay on done.
    logic[4:0] mover_delay=-1;
    always_ff @(posedge axi_aclk) begin
        if (~mover_done) begin
            mover_delay <= -1;
        end else begin
            mover_delay <= mover_delay - 1;
            mover_start <= (mover_delay == 0);
        end
    end

    // increment a count each time a transfer starts and drive the LEDs with it.
    logic mover_start_q=0;
    logic[1:0] led_count=0;
    always_ff @(posedge axi_aclk) begin
        mover_start_q <= mover_start;
        if ((mover_start) && (~mover_start_q)) led_count <= led_count + 1;
    end
    assign led = led_count;
    
    // debug
    top_ila ila_inst (.clk(axi_aclk), .probe0({S_AXIS_MM2S_CMD_tready, M_AXIS_MM2S_STS_tvalid, M_AXIS_S2MM_STS_tvalid, S_AXIS_S2MM_CMD_tready, S_AXIS_S2MM_CMD_tvalid, mover_start, mover_done})); // 7
        
endmodule

/*
*/
