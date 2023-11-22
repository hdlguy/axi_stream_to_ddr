`timescale 1ns/1ps
//
module xpm_sync_fifo_tb ();

    localparam int W = 16;
    localparam int D = 1024;

    logic[W-1:0]    din = 0;
    logic           wr_en=0;
    logic           full, ref_full;
    logic           rd_en=0;
    logic[W-1:0]    dout, ref_dout;
    logic           empty, ref_empty;
    logic           srst;
    logic   reset;
    logic clk=0; localparam clk_period=10; always #(clk_period/2)  clk=~clk;
    
    assign srst = reset;

    xpm_sync_fifo #(.W(W), .D(D)) uut (.*);
    
    xpm_ref_fifo ref_fifo (.clk(clk), .srst(srst), .din(din), .wr_en(wr_en), .rd_en(rd_en), .dout(ref_dout), .full(ref_full), .empty(ref_empty));

    
    logic[15:0] read_rand=0, write_rand=0;
    always_ff @(posedge clk) begin
        read_rand  <= #1 $random();
        write_rand <= #1 $random();
        if ((wr_en==1) && (full==0)) din <= #1 din + 1;
        wr_en <= write_rand[0];
        rd_en <= read_rand[0];
    end
    
    initial begin
        reset = 1;
        #(clk_period*100);
        reset = 0;
    end
    

endmodule


/*
module xpm_sync_fifo #(
    parameter int W = 16,   // width
    parameter int D = 64,   // depth
    parameter int R = 0     // additional read pipeline registers
) (
    input   logic           clk,
    input   logic[W-1:0]    din,
    input   logic           wr_en,
    output  logic           full,
        
    input   logic           rd_en,
    output  logic[W-1:0]    dout,
    output  logic           empty
);
*/
