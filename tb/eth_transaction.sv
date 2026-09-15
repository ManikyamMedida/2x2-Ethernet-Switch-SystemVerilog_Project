`ifndef ETH_TRANSACTION_SV
`define ETH_TRANSACTION_SV

`include "eth_packet.sv"

class eth_transaction;

  eth_packet pkt;
  int port;


  function new();

    pkt = new();
    port = 0;

  endfunction


  function void display(string name = "TRANSACTION");

    $display("----------------------------------------");
    $display("%s", name);

    if (port == 0)
      $display("Input Port = INPUT_A");
    else
      $display("Input Port = INPUT_B");

    pkt.display("PACKET");

    $display("----------------------------------------");

  endfunction

endclass

`endif
