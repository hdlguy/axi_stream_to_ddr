
module adc_emulator(
    input   logic               clk,
    output  logic               dv_out,
    output  logic[3:0][17:0]    d_out
);



    logic[1023:0][17:0] sinrom;
    localparam real pi = 3.141592653589793;
    initial begin
        for (int i=0; i<1024; i++) begin
            sinrom[i] = ((2.0**17.0)-1.0) * $sin(2.0*pi*i/1024.0);
        end
    end
    
    
    logic[2:0] dv_count=6;
    logic[9:0] addr=0;
    always_ff @(posedge clk) begin

        // make the datavalid heartbeat
        if (dv_count == 0) begin
            dv_out <= 1;
            dv_count <= 6;
            addr <= addr + 1;
            d_out[0] <= sinrom[(addr+  0)%1024];
            d_out[1] <= sinrom[(addr+200)%1024];
            d_out[2] <= sinrom[(addr+400)%1024];
            d_out[3] <= sinrom[(addr+600)%1024];
        end else begin
            dv_out <= 0;
            dv_count <= dv_count - 1;
        end

    end


endmodule


