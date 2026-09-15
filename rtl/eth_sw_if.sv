interface eth_sw_if(input logic clk);

  timeunit 1ns;
  timeprecision 1ps;


  // ============================================================
  // RESET
  // ============================================================

  logic rstN;


  // ============================================================
  // INPUT A
  // ============================================================

  logic [31:0] inDataA;
  logic sopA;
  logic eopA;


  // ============================================================
  // INPUT B
  // ============================================================

  logic [31:0] inDataB;
  logic sopB;
  logic eopB;


  // ============================================================
  // OUTPUT A
  // ============================================================

  logic [31:0] outDataA;
  logic sopOutA;
  logic eopOutA;


  // ============================================================
  // OUTPUT B
  // ============================================================

  logic [31:0] outDataB;
  logic sopOutB;
  logic eopOutB;


  // ============================================================
  // STALL SIGNALS
  // ============================================================

  logic portAStall;
  logic portBStall;


  // ============================================================
  // DRIVER CLOCKING BLOCK
  // ============================================================

  clocking cb @(posedge clk);

    default input #2ns output #2ns;


    output rstN;


    output inDataA;
    output sopA;
    output eopA;


    output inDataB;
    output sopB;
    output eopB;


    input outDataA;
    input sopOutA;
    input eopOutA;


    input outDataB;
    input sopOutB;
    input eopOutB;


    input portAStall;
    input portBStall;

  endclocking


  // ============================================================
  // MONITOR CLOCKING BLOCK
  // ============================================================

  clocking mon_cb @(posedge clk);

    default input #2ns;


    input rstN;


    input inDataA;
    input sopA;
    input eopA;


    input inDataB;
    input sopB;
    input eopB;


    input outDataA;
    input sopOutA;
    input eopOutA;


    input outDataB;
    input sopOutB;
    input eopOutB;


    input portAStall;
    input portBStall;

  endclocking


  // ============================================================
  // DRIVER MODPORT
  // ============================================================

  modport DRIVER(
    clocking cb
  );


  // ============================================================
  // MONITOR MODPORT
  // ============================================================

  modport MONITOR(
    clocking mon_cb
  );


  // ============================================================
  // DUT MODPORT
  // ============================================================

  modport DUT(

    input clk,
    input rstN,


    input inDataA,
    input sopA,
    input eopA,


    input inDataB,
    input sopB,
    input eopB,


    output outDataA,
    output sopOutA,
    output eopOutA,


    output outDataB,
    output sopOutB,
    output eopOutB,


    output portAStall,
    output portBStall

  );

endinterface
