`timescale 1ns / 1ps

module top_tb ();

    logic reset_in_n;

    localparam time clk_period=10; logic clkin=0; always #(clk_period/2) clkin=~clkin;

    top uut (.*);
    
    initial begin
        reset_in_n = 1;
        #(clk_period*40);
        reset_in_n = 1;
    end

endmodule
