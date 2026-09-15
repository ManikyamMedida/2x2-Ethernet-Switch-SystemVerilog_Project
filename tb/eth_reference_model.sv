
class eth_reference_model;

  //==================================================
  // Input packet mailboxes
  //==================================================

  mailbox input_A;
  mailbox input_B;


  //==================================================
  // Expected output mailboxes
  //==================================================

  mailbox expected_A;
  mailbox expected_B;


  //==================================================
  // Constructor
  //==================================================

  function new(
    mailbox input_A,
    mailbox input_B,
    mailbox expected_A,
    mailbox expected_B
  );

    this.input_A = input_A;
    this.input_B = input_B;

    this.expected_A = expected_A;
    this.expected_B = expected_B;

  endfunction


  //==================================================
  // Process packets received from INPUT_A
  //==================================================

  task process_input_A();

    eth_packet pkt;

    forever begin

      // Get packet captured by INPUT_A monitor
      input_A.get(pkt);


      $display("");
      $display("--------------------------------------------");
      $display(
        "REFERENCE MODEL: Packet received from INPUT_A"
      );
      $display("--------------------------------------------");


      //============================================
      // Destination 1 -> OUTPUT_A
      //============================================

      if (pkt.da == 32'h1) begin

        $display(
          "REFERENCE MODEL: DA=1 -> expected OUTPUT_A"
        );

        expected_A.put(pkt);

      end


      //============================================
      // Destination 2 -> OUTPUT_B
      //============================================

      else if (pkt.da == 32'h2) begin

        $display(
          "REFERENCE MODEL: DA=2 -> expected OUTPUT_B"
        );

        expected_B.put(pkt);

      end


      //============================================
      // Invalid destination
      //============================================

      else begin

        $display(
          "REFERENCE MODEL ERROR: Invalid destination %h",
          pkt.da
        );

      end

    end

  endtask


  //==================================================
  // Process packets received from INPUT_B
  //==================================================

  task process_input_B();

    eth_packet pkt;

    forever begin

      // Get packet captured by INPUT_B monitor
      input_B.get(pkt);


      $display("");
      $display("--------------------------------------------");
      $display(
        "REFERENCE MODEL: Packet received from INPUT_B"
      );
      $display("--------------------------------------------");


      //============================================
      // Destination 1 -> OUTPUT_A
      //============================================

      if (pkt.da == 32'h1) begin

        $display(
          "REFERENCE MODEL: DA=1 -> expected OUTPUT_A"
        );

        expected_A.put(pkt);

      end


      //============================================
      // Destination 2 -> OUTPUT_B
      //============================================

      else if (pkt.da == 32'h2) begin

        $display(
          "REFERENCE MODEL: DA=2 -> expected OUTPUT_B"
        );

        expected_B.put(pkt);

      end


      //============================================
      // Invalid destination
      //============================================

      else begin

        $display(
          "REFERENCE MODEL ERROR: Invalid destination %h",
          pkt.da
        );

      end

    end

  endtask


  //==================================================
  // Start Reference Model
  //==================================================

  task run();

    fork

      process_input_A();

      process_input_B();

    join_none

  endtask


endclass
