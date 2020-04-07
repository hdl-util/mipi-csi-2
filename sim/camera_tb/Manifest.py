action = "simulation"
sim_tool = "modelsim"
sim_top = "camera_tb"

sim_post_cmd = "vsim -novopt -do ../vsim.do -c camera_tb"

modules = {
  "local" : [ "../../test/" ],
}
