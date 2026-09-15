`timescale 1ns/1ps

//============================================================
// Verification Class Files
//============================================================

`include "eth_packet.sv"
`include "eth_transaction.sv"
`include "eth_generator.sv"
`include "eth_driver.sv"
`include "eth_monitor.sv"
`include "eth_reference_model.sv"
`include "eth_checker.sv"


module tb_eth_sw_2x2;

  //============================================================
  // Clock
  //============================================================

  logic clk;

  initial begin

    clk = 0;

    forever
      #5 clk = ~clk;

  end


  //============================================================
  // Ethernet Switch Interface
  //============================================================

  eth_sw_if sw_if(clk);


  //============================================================
  // DUT
  //============================================================

  eth_sw_2x2 dut (

    .clk        (clk),
    .rstN       (sw_if.rstN),

    .inDataA    (sw_if.inDataA),
    .sopA       (sw_if.sopA),
    .eopA       (sw_if.eopA),

    .inDataB    (sw_if.inDataB),
    .sopB       (sw_if.sopB),
    .eopB       (sw_if.eopB),

    .outDataA   (sw_if.outDataA),
    .sopOutA   (sw_if.sopOutA),
    .eopOutA   (sw_if.eopOutA),

    .outDataB   (sw_if.outDataB),
    .sopOutB   (sw_if.sopOutB),
    .eopOutB   (sw_if.eopOutB),

    .portAStall (sw_if.portAStall),
    .portBStall (sw_if.portBStall)

  );


  //============================================================
  // Mailboxes
  //============================================================

  // Generator -> Driver
  mailbox gen2drv_A;
  mailbox gen2drv_B;


  // Input Monitors -> Reference Model
  mailbox input_A;
  mailbox input_B;


  // Reference Model -> Checker
  mailbox expected_A;
  mailbox expected_B;


  // Output Monitors -> Checker
  mailbox actual_A;
  mailbox actual_B;


  // Checker -> Testbench
  mailbox done_mbx;


  //============================================================
  // Verification Components
  //============================================================

  eth_generator generator;

  eth_driver driver;

  eth_monitor mon_in_A;
  eth_monitor mon_in_B;

  eth_monitor mon_out_A;
  eth_monitor mon_out_B;

  eth_reference_model ref_model;

  eth_checker pkt_checker;


  //============================================================
  // Testbench Variables
  //============================================================

  int done;

  int i;


  //============================================================
  // BUILD ENVIRONMENT
  //============================================================

  initial begin

    //==========================================================
    // Create mailboxes
    //==========================================================

    gen2drv_A = new();
    gen2drv_B = new();

    input_A = new();
    input_B = new();

    expected_A = new();
    expected_B = new();

    actual_A = new();
    actual_B = new();

    done_mbx = new();


    //==========================================================
    // Create Generator
    //==========================================================

    generator = new(
      gen2drv_A,
      gen2drv_B
    );


    //==========================================================
    // Create Driver
    //==========================================================

    driver = new(
      sw_if.DRIVER,
      gen2drv_A,
      gen2drv_B
    );


    //==========================================================
    // Create Input Monitors
    //==========================================================

    mon_in_A = new(
      sw_if.MONITOR,
      0,
      input_A
    );


    mon_in_B = new(
      sw_if.MONITOR,
      1,
      input_B
    );


    //==========================================================
    // Create Output Monitors
    //==========================================================

    mon_out_A = new(
      sw_if.MONITOR,
      2,
      actual_A
    );


    mon_out_B = new(
      sw_if.MONITOR,
      3,
      actual_B
    );


    //==========================================================
    // Create Reference Model
    //==========================================================

    ref_model = new(
      input_A,
      input_B,
      expected_A,
      expected_B
    );


    //==========================================================
    // Create Checker
    //==========================================================

    pkt_checker = new(
      expected_A,
      expected_B,
      actual_A,
      actual_B,
      done_mbx
    );


    //==========================================================
    // Environment Information
    //==========================================================

    $display("");
    $display("================================================");
    $display("       2x2 ETHERNET SWITCH VERIFICATION");
    $display("================================================");

    $display("");
    $display("VERIFICATION ENVIRONMENT");

    $display("-----------------------------------------------");
    $display("Generator        : CREATED");
    $display("Driver           : CREATED");
    $display("Input Monitor A  : CREATED");
    $display("Input Monitor B  : CREATED");
    $display("Output Monitor A : CREATED");
    $display("Output Monitor B : CREATED");
    $display("Reference Model  : CREATED");
    $display("Checker          : CREATED");
    $display("-----------------------------------------------");

  end


  //============================================================
  // RESET
  //============================================================

  initial begin

    //==========================================================
    // Apply reset
    //==========================================================

    sw_if.rstN = 0;

    sw_if.inDataA = 32'h0;
    sw_if.sopA = 0;
    sw_if.eopA = 0;

    sw_if.inDataB = 32'h0;
    sw_if.sopB = 0;
    sw_if.eopB = 0;


    $display("");
    $display("RESET: ASSERTED");


    // Hold reset for 5 clocks

    repeat (5)
      @(posedge clk);


    // Release reset

    sw_if.rstN = 1;


    $display("RESET: RELEASED");

  end


  //============================================================
  // START VERIFICATION ENVIRONMENT
  //============================================================

  initial begin

    // Wait for reset release

    wait(sw_if.rstN == 1);


    //==========================================================
    // Start Reference Model
    //==========================================================

    ref_model.run();


    //==========================================================
    // Start Checker
    //==========================================================

    pkt_checker.run();


    //==========================================================
    // Start all monitors
    //==========================================================

    fork

      //========================================================
      // INPUT A MONITOR
      //========================================================

      forever begin

        eth_packet pkt;

        pkt = new();

        mon_in_A.run_once(pkt);

      end


      //========================================================
      // INPUT B MONITOR
      //========================================================

      forever begin

        eth_packet pkt;

        pkt = new();

        mon_in_B.run_once(pkt);

      end


      //========================================================
      // OUTPUT A MONITOR
      //========================================================

      forever begin

        eth_packet pkt;

        pkt = new();

        mon_out_A.run_once(pkt);

      end


      //========================================================
      // OUTPUT B MONITOR
      //========================================================

      forever begin

        eth_packet pkt;

        pkt = new();

        mon_out_B.run_once(pkt);

      end

    join_none


    //==========================================================
    // Start both driver threads
    //==========================================================

    driver.run();


    //==========================================================
    // Run complete regression
    //==========================================================

    run_regression();


    //==========================================================
    // Final checker report
    //==========================================================

    pkt_checker.report();


    $display("");
    $display("================================================");
    $display("          REGRESSION COMPLETED");
    $display("================================================");


    $finish;

  end


  //============================================================
  // REGRESSION
  //============================================================

  task run_regression();


    //**********************************************************
    // TEST 1
    // INPUT A -> OUTPUT A
    //**********************************************************

    $display("");
    $display("");
    $display("================================================");
    $display("TEST 1 : INPUT_A -> OUTPUT_A");
    $display("================================================");


    generator.send_directed(
      0,
      32'h1,
      20
    );


    done_mbx.get(done);


    $display("TEST 1 RESULT : PASS");


    //**********************************************************
    // TEST 2
    // INPUT A -> OUTPUT B
    //**********************************************************

    $display("");
    $display("");
    $display("================================================");
    $display("TEST 2 : INPUT_A -> OUTPUT_B");
    $display("================================================");


    generator.send_directed(
      0,
      32'h2,
      25
    );


    done_mbx.get(done);


    $display("TEST 2 RESULT : PASS");


    //**********************************************************
    // TEST 3
    // INPUT B -> OUTPUT A
    //**********************************************************

    $display("");
    $display("");
    $display("================================================");
    $display("TEST 3 : INPUT_B -> OUTPUT_A");
    $display("================================================");


    generator.send_directed(
      1,
      32'h1,
      30
    );


    done_mbx.get(done);


    $display("TEST 3 RESULT : PASS");


    //**********************************************************
    // TEST 4
    // INPUT B -> OUTPUT B
    //**********************************************************

    $display("");
    $display("");
    $display("================================================");
    $display("TEST 4 : INPUT_B -> OUTPUT_B");
    $display("================================================");


    generator.send_directed(
      1,
      32'h2,
      35
    );


    done_mbx.get(done);


    $display("TEST 4 RESULT : PASS");


    //**********************************************************
    // TEST 5
    // RANDOM PACKET FROM INPUT A
    //**********************************************************

    $display("");
    $display("");
    $display("================================================");
    $display("TEST 5 : RANDOM PACKET FROM INPUT_A");
    $display("================================================");


    generator.send_directed(
      0,
      $urandom_range(1,2),
      $urandom_range(13,50)
    );


    done_mbx.get(done);


    $display("TEST 5 RESULT : PASS");


    //**********************************************************
    // TEST 6
    // RANDOM PACKET FROM INPUT B
    //**********************************************************

    $display("");
    $display("");
    $display("================================================");
    $display("TEST 6 : RANDOM PACKET FROM INPUT_B");
    $display("================================================");


    generator.send_directed(
      1,
      $urandom_range(1,2),
      $urandom_range(13,50)
    );


    done_mbx.get(done);


    $display("TEST 6 RESULT : PASS");


    //**********************************************************
    // TEST 7
    // MINIMUM ETHERNET FRAME
    //**********************************************************

    $display("");
    $display("");
    $display("================================================");
    $display("TEST 7 : MINIMUM ETHERNET FRAME");
    $display("================================================");


    generator.send_directed(
      0,
      32'h1,
      13
    );


    done_mbx.get(done);


    $display("TEST 7 RESULT : PASS");


    //**********************************************************
    // TEST 8
    // MAXIMUM ETHERNET FRAME
    //**********************************************************

    $display("");
    $display("");
    $display("================================================");
    $display("TEST 8 : MAXIMUM ETHERNET FRAME");
    $display("================================================");


    generator.send_directed(
      1,
      32'h2,
      376
    );


    done_mbx.get(done);


    $display("TEST 8 RESULT : PASS");


    //**********************************************************
    // TEST 9
    // BACK-TO-BACK PACKETS
    //**********************************************************

    $display("");
    $display("");
    $display("================================================");
    $display("TEST 9 : BACK-TO-BACK PACKETS");
    $display("================================================");


    generator.send_directed(
      0,
      32'h1,
      15
    );


    generator.send_directed(
      0,
      32'h2,
      18
    );


    // Wait for BOTH packets

    done_mbx.get(done);
    done_mbx.get(done);


    $display("TEST 9 RESULT : PASS");


    //**********************************************************
    // TEST 10
    // SIMULTANEOUS TRAFFIC
    //**********************************************************

    $display("");
    $display("");
    $display("================================================");
    $display("TEST 10 : SIMULTANEOUS A+B TRAFFIC");
    $display("================================================");


    fork

      generator.send_directed(
        0,
        32'h1,
        20
      );

      generator.send_directed(
        1,
        32'h2,
        20
      );

    join


    // Wait for both packets

    done_mbx.get(done);
    done_mbx.get(done);


    $display("TEST 10 RESULT : PASS");


    //**********************************************************
    // TEST 11
    // BOTH INPUTS -> OUTPUT A
    //**********************************************************

    $display("");
    $display("");
    $display("================================================");
    $display("TEST 11 : INPUT_A + INPUT_B -> OUTPUT_A");
    $display("================================================");


    fork

      generator.send_directed(
        0,
        32'h1,
        20
      );

      begin

        #20;

        generator.send_directed(
          1,
          32'h1,
          20
        );

      end

    join


    // Wait for both packets

    done_mbx.get(done);
    done_mbx.get(done);


    $display("TEST 11 RESULT : PASS");


    //**********************************************************
    // TEST 12
    // BOTH INPUTS -> OUTPUT B
    //**********************************************************

    $display("");
    $display("");
    $display("================================================");
    $display("TEST 12 : INPUT_A + INPUT_B -> OUTPUT_B");
    $display("================================================");


    fork

      generator.send_directed(
        0,
        32'h2,
        20
      );

      begin

        #20;

        generator.send_directed(
          1,
          32'h2,
          20
        );

      end

    join


    // Wait for both packets

    done_mbx.get(done);
    done_mbx.get(done);


    $display("TEST 12 RESULT : PASS");


    //**********************************************************
    // TEST 13
    // MIXED RANDOM TRAFFIC
    //**********************************************************

    $display("");
    $display("");
    $display("================================================");
    $display("TEST 13 : MIXED RANDOM TRAFFIC");
    $display("================================================");


    // Generate 10 random packets

    for (i = 0; i < 10; i = i + 1) begin

      generator.send_random();

    end


    // Wait for all 10 packets

    for (i = 0; i < 10; i = i + 1) begin

      done_mbx.get(done);

    end


    $display("TEST 13 RESULT : PASS");


    //**********************************************************
    // REGRESSION COMPLETE
    //**********************************************************

    $display("");
    $display("");
    $display("================================================");
    $display("       ALL REGRESSION TESTS COMPLETED");
    $display("================================================");

  endtask


endmodule
