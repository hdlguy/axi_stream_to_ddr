# This file sets up the simulation environment.
create_project -force proj 
create_project -part xc7a100tcsg324-2 -force proj 
set_property target_language Verilog [current_project]
set_property "default_lib" "work" [current_project]
create_fileset -simset simset

read_ip ../xpm_ref_fifo/xpm_ref_fifo.xci
generate_target {simulation} [get_ips *]

read_verilog -sv ../xpm_sync_fifo.sv
read_verilog -sv ../xpm_sync_fifo_tb.sv

add_files -fileset sim_1 -norecurse ./xpm_sync_fifo_tb_behav.wcfg

close_project


