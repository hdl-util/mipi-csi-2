action = "simulation"
sim_tool = "modelsim"
sim_top = "d_phy_receiver_tb"

sim_post_cmd = "vsim -novopt -do ../vsim.do -c d_phy_receiver_tb"

modules = {
  "local" : [ "../../test/" ],
}
