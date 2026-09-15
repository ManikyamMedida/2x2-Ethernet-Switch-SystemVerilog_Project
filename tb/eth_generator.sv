class eth_generator;

  mailbox gen2drv_A;
  mailbox gen2drv_B;


  function new(
    mailbox gen2drv_A,
    mailbox gen2drv_B
  );

    this.gen2drv_A = gen2drv_A;
    this.gen2drv_B = gen2drv_B;

  endfunction


  //==================================================
  // Generate directed packet
  //==================================================

  task send_directed(
    int port,
    bit [31:0] destination,
    int unsigned payload_words
  );

    eth_transaction tr;


    tr = new();

    tr.port = port;


    if (!tr.pkt.randomize() with {
      da == destination;
      payload_length == payload_words;
    }) begin

      $display("GENERATOR ERROR: Directed randomization failed");
      return;

    end


    $display("");
    $display("------------------------------------------------");
    $display("GENERATED DIRECTED PACKET");
    $display("Input Port       : %s",
             (port == 0) ? "INPUT_A" : "INPUT_B");

    $display("Destination      : %h", tr.pkt.da);
    $display("Source           : %h", tr.pkt.sa);
    $display("Packet Size      : %0d words",
             tr.pkt.data_length);
    $display("Payload Size     : %0d words",
             tr.pkt.payload_length);

    if (port == 0)
      $display("Expected Output  : OUTPUT_A if DA=1 / OUTPUT_B if DA=2");
    else
      $display("Expected Output  : OUTPUT_A if DA=1 / OUTPUT_B if DA=2");

    $display("------------------------------------------------");


    if (port == 0)
      gen2drv_A.put(tr);
    else
      gen2drv_B.put(tr);

  endtask


  //==================================================
  // Generate random packet
  //==================================================

  task send_random();

    eth_transaction tr;


    tr = new();


    if (!tr.pkt.randomize()) begin

      $display("GENERATOR ERROR: Randomization failed");
      return;

    end


    tr.port = $urandom_range(0,1);


    $display("");
    $display("------------------------------------------------");
    $display("GENERATED RANDOM PACKET");
    $display("Input Port       : %s",
             (tr.port == 0) ? "INPUT_A" : "INPUT_B");
    $display("Destination      : %h", tr.pkt.da);
    $display("Source           : %h", tr.pkt.sa);
    $display("Packet Size      : %0d words",
             tr.pkt.data_length);
    $display("Payload Size     : %0d words",
             tr.pkt.payload_length);
    $display("------------------------------------------------");


    if (tr.port == 0)
      gen2drv_A.put(tr);
    else
      gen2drv_B.put(tr);

  endtask

endclass
