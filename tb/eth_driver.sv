class eth_driver;

  //==================================================
  // Virtual interface
  //==================================================

  virtual eth_sw_if.DRIVER vif;


  //==================================================
  // Generator -> Driver mailboxes
  //==================================================

  mailbox gen2drv_A;
  mailbox gen2drv_B;


  //==================================================
  // Constructor
  //==================================================

  function new(
    virtual eth_sw_if.DRIVER vif,
    mailbox gen2drv_A,
    mailbox gen2drv_B
  );

    this.vif = vif;

    this.gen2drv_A = gen2drv_A;
    this.gen2drv_B = gen2drv_B;

  endfunction


  //==================================================
  // DRIVE INPUT A
  //==================================================

  task drive_A(eth_packet pkt);

    int i;


    $display("");
    $display("DRIVER: Packet ready for INPUT_A");


    //================================================
    // Wait while DUT is asserting backpressure
    //================================================

    while (vif.cb.portAStall === 1'b1) begin

      $display(
        "DRIVER: INPUT_A STALL asserted - waiting"
      );

      @(vif.cb);

    end


    $display(
      "DRIVER: Driving packet on INPUT_A"
    );


    //================================================
    // Drive packet
    //================================================

    @(vif.cb);


    for (i = 0;
         i < pkt.data.size();
         i = i + 1) begin


      vif.cb.inDataA <= pkt.data[i];


      // SOP

      if (i == 0)
        vif.cb.sopA <= 1'b1;
      else
        vif.cb.sopA <= 1'b0;


      // EOP

      if (i == pkt.data.size() - 1)
        vif.cb.eopA <= 1'b1;
      else
        vif.cb.eopA <= 1'b0;


      @(vif.cb);

    end


    //================================================
    // Return bus to idle
    //================================================

    vif.cb.inDataA <= 32'h0;

    vif.cb.sopA <= 1'b0;

    vif.cb.eopA <= 1'b0;


    $display(
      "DRIVER: Finished packet on INPUT_A"
    );

  endtask


  //==================================================
  // DRIVE INPUT B
  //==================================================

  task drive_B(eth_packet pkt);

    int i;


    $display("");
    $display("DRIVER: Packet ready for INPUT_B");


    //================================================
    // Wait while DUT is asserting backpressure
    //================================================

    while (vif.cb.portBStall === 1'b1) begin

      $display(
        "DRIVER: INPUT_B STALL asserted - waiting"
      );

      @(vif.cb);

    end


    $display(
      "DRIVER: Driving packet on INPUT_B"
    );


    //================================================
    // Drive packet
    //================================================

    @(vif.cb);


    for (i = 0;
         i < pkt.data.size();
         i = i + 1) begin


      vif.cb.inDataB <= pkt.data[i];


      // SOP

      if (i == 0)
        vif.cb.sopB <= 1'b1;
      else
        vif.cb.sopB <= 1'b0;


      // EOP

      if (i == pkt.data.size() - 1)
        vif.cb.eopB <= 1'b1;
      else
        vif.cb.eopB <= 1'b0;


      @(vif.cb);

    end


    //================================================
    // Return bus to idle
    //================================================

    vif.cb.inDataB <= 32'h0;

    vif.cb.sopB <= 1'b0;

    vif.cb.eopB <= 1'b0;


    $display(
      "DRIVER: Finished packet on INPUT_B"
    );

  endtask


  //==================================================
  // INPUT A DRIVER THREAD
  //==================================================

  task run_A();

    eth_transaction tr;


    forever begin

      gen2drv_A.get(tr);

      drive_A(tr.pkt);

    end

  endtask


  //==================================================
  // INPUT B DRIVER THREAD
  //==================================================

  task run_B();

    eth_transaction tr;


    forever begin

      gen2drv_B.get(tr);

      drive_B(tr.pkt);

    end

  endtask


  //==================================================
  // START BOTH DRIVER THREADS
  //==================================================

  task run();

    fork

      run_A();

      run_B();

    join_none

  endtask


endclass
