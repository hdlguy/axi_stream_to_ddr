`timescale 1ns / 1ps

module top_tb ();

    localparam time clk_period=10; logic clkin=0; always #(clk_period/2) clkin=~clkin;

    top uut (.*);

endmodule
