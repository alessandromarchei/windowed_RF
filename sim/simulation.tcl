# Set the working directory
set work_dir "work"
set src_dir "../src"
set tb_dir "../tb"


# Create the work library if it does not exist
if {[file exists $work_dir]} {
    vdel -lib $work_dir -all
}
vlib $work_dir

# Compile the design files
vmap work $work_dir

# compile the vhd file
vcom -work work $src_dir/RF_WINDOWED.vhd

# Compile the testbench
vcom -work work "$tb_dir/tb.vhd"

# Load the testbench
vsim -voptargs="+acc" work.tb

#adding waves
add wave *

run 1000ns
