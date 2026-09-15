`ifndef ETH_PACKET_SV
`define ETH_PACKET_SV

class eth_packet;

  rand bit [31:0] da;
  rand bit [31:0] sa;
  rand bit [31:0] crc;
  rand bit [31:0] data[];

  rand int unsigned payload_length;

  int unsigned data_length;


  constraint destination_c {
    da inside {32'h1, 32'h2};
  }


  constraint payload_length_c {
    payload_length inside {[13:376]};
  }


  function new();

    data_length = 0;

  endfunction


  function void post_randomize();

    int i;

    data_length = payload_length + 3;

    data = new[data_length];


    data[0] = da;
    data[1] = sa;
    data[2] = crc;


    for (i = 3; i < data_length; i = i + 1)
      data[i] = $urandom();

  endfunction


  function void display(string name = "PACKET");

    $display("----------------------------------------");
    $display("%s", name);
    $display("DA             = %h", da);
    $display("SA             = %h", sa);
    $display("CRC            = %h", crc);
    $display("Data length    = %0d", data_length);
    $display("Payload length = %0d", payload_length);
    $display("----------------------------------------");

  endfunction


  function eth_packet copy();

    eth_packet pkt;

    int i;

    pkt = new();

    pkt.da = this.da;
    pkt.sa = this.sa;
    pkt.crc = this.crc;

    pkt.data_length = this.data_length;
    pkt.payload_length = this.payload_length;

    pkt.data = new[this.data.size()];


    for (i = 0; i < this.data.size(); i = i + 1)
      pkt.data[i] = this.data[i];


    return pkt;

  endfunction

endclass

`endif
