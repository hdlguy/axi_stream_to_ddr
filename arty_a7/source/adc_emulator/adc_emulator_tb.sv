`timescale 1ns / 1ps

module adc_emulator_tb ();

    logic               dv_out;
    logic[3:0][17:0]    d_out;

    localparam time clk_period=10; logic clk=0; always #(clk_period/2) clk=~clk;

    adc_emulator uut (.*);
    

endmodule

/*
module adc_emulator(
    input   logic               clk,
    output  logic               dv_out,
    output  logic[3:0][17:0]    d_out
);
*/

