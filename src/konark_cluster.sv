// Copyright 2024 ETH Zurich and University of Bologna.
// Solderpad Hardware License, Version 0.51, see LICENSE for details.
// SPDX-License-Identifier: SHL-0.51

// Konark Cluster Top-Level Module
// This module integrates the Snitch cluster as the main compute element

module konark_cluster #(
  parameter realtime ClkPeriod = 1ns
) (
  input  logic clk_i,
  input  logic rst_ni
);

  // For now, this is a placeholder module that will be extended
  // to instantiate snitch_cluster_wrapper once the build system is working
  
  // Future: instantiate snitch_cluster_wrapper here
  // snitch_cluster_wrapper i_snitch_cluster (
  //   .clk_i (clk_i),
  //   .rst_ni (rst_ni),
  //   // ... other ports
  // );

endmodule