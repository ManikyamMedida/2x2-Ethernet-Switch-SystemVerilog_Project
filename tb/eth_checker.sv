class eth_checker;

  //==================================================
  // Mailboxes
  //==================================================

  mailbox expected_A;
  mailbox expected_B;

  mailbox actual_A;
  mailbox actual_B;

  mailbox done_mbx;


  //==================================================
  // Statistics
  //==================================================

  int pass_count;
  int fail_count;


  //==================================================
  // Internal queues
  //==================================================

  eth_packet expected_queue_A[$];
  eth_packet expected_queue_B[$];

  eth_packet actual_queue_A[$];
  eth_packet actual_queue_B[$];


  //==================================================
  // Constructor
  //==================================================

  function new(
    mailbox expected_A,
    mailbox expected_B,
    mailbox actual_A,
    mailbox actual_B,
    mailbox done_mbx
  );

    this.expected_A = expected_A;
    this.expected_B = expected_B;

    this.actual_A = actual_A;
    this.actual_B = actual_B;

    this.done_mbx = done_mbx;

    pass_count = 0;
    fail_count = 0;

  endfunction


  //==================================================
  // Compare complete packets
  //==================================================

  function bit compare_packets(
    eth_packet expected,
    eth_packet actual
  );

    int i;

    compare_packets = 1;


    // Check packet length

    if (expected.data.size() !=
        actual.data.size()) begin

      $display(
        "CHECKER ERROR: Packet size mismatch"
      );

      $display(
        "Expected = %0d words",
        expected.data.size()
      );

      $display(
        "Actual   = %0d words",
        actual.data.size()
      );

      compare_packets = 0;

    end


    // Check complete packet data

    if (expected.data.size() ==
        actual.data.size()) begin

      for (i = 0;
           i < expected.data.size();
           i = i + 1) begin

        if (expected.data[i] !==
            actual.data[i]) begin

          $display(
            "CHECKER ERROR: Data mismatch at word %0d",
            i
          );

          $display(
            "Expected = %h",
            expected.data[i]
          );

          $display(
            "Actual   = %h",
            actual.data[i]
          );

          compare_packets = 0;

        end

      end

    end

  endfunction


  //==================================================
  // Find packet using Source Address
  //==================================================

  function int find_packet_by_sa(
    eth_packet queue[$],
    bit [31:0] sa
  );

    int i;

    find_packet_by_sa = -1;

    for (i = 0; i < queue.size(); i = i + 1) begin

      if (queue[i].sa == sa) begin

        find_packet_by_sa = i;

        return find_packet_by_sa;

      end

    end

  endfunction


  //==================================================
  // Check OUTPUT A
  //==================================================

  task check_A();

    eth_packet pkt;
    eth_packet actual_pkt;
    eth_packet expected_pkt;

    int index;
    bit passed;


    forever begin

      //================================================
      // Get expected packet
      //================================================

      fork

        begin
          expected_A.get(pkt);
          expected_queue_A.push_back(pkt);
        end

        begin
          actual_A.get(pkt);
          actual_queue_A.push_back(pkt);
        end

      join


      //================================================
      // Try matching packets
      //================================================

      while (
        expected_queue_A.size() > 0 &&
        actual_queue_A.size() > 0
      ) begin

        actual_pkt = actual_queue_A.pop_front();


        index = find_packet_by_sa(
          expected_queue_A,
          actual_pkt.sa
        );


        if (index >= 0) begin

          expected_pkt =
            expected_queue_A[index];

          expected_queue_A.delete(index);


          $display("");
          $display("============================================");
          $display("CHECKER: OUTPUT_A");
          $display("============================================");

          $display(
            "Expected DA = %h",
            expected_pkt.da
          );

          $display(
            "Actual DA   = %h",
            actual_pkt.da
          );

          $display(
            "Source      = %h",
            actual_pkt.sa
          );


          passed = compare_packets(
            expected_pkt,
            actual_pkt
          );


          if (passed) begin

            pass_count++;

            $display(
              "RESULT = PASS"
            );

          end
          else begin

            fail_count++;

            $display(
              "RESULT = FAIL"
            );

          end


          // One packet completed

          done_mbx.put(1);

        end
        else begin

          // No expected packet yet.
          // Put actual packet back.

          actual_queue_A.push_front(actual_pkt);

          break;

        end

      end

    end

  endtask


  //==================================================
  // Check OUTPUT B
  //==================================================

  task check_B();

    eth_packet pkt;
    eth_packet actual_pkt;
    eth_packet expected_pkt;

    int index;
    bit passed;


    forever begin

      //================================================
      // Get expected or actual packet
      //================================================

      fork

        begin
          expected_B.get(pkt);
          expected_queue_B.push_back(pkt);
        end

        begin
          actual_B.get(pkt);
          actual_queue_B.push_back(pkt);
        end

      join


      //================================================
      // Match packets
      //================================================

      while (
        expected_queue_B.size() > 0 &&
        actual_queue_B.size() > 0
      ) begin

        actual_pkt = actual_queue_B.pop_front();


        index = find_packet_by_sa(
          expected_queue_B,
          actual_pkt.sa
        );


        if (index >= 0) begin

          expected_pkt =
            expected_queue_B[index];

          expected_queue_B.delete(index);


          $display("");
          $display("============================================");
          $display("CHECKER: OUTPUT_B");
          $display("============================================");

          $display(
            "Expected DA = %h",
            expected_pkt.da
          );

          $display(
            "Actual DA   = %h",
            actual_pkt.da
          );

          $display(
            "Source      = %h",
            actual_pkt.sa
          );


          passed = compare_packets(
            expected_pkt,
            actual_pkt
          );


          if (passed) begin

            pass_count++;

            $display(
              "RESULT = PASS"
            );

          end
          else begin

            fail_count++;

            $display(
              "RESULT = FAIL"
            );

          end


          // One packet completed

          done_mbx.put(1);

        end
        else begin

          actual_queue_B.push_front(actual_pkt);

          break;

        end

      end

    end

  endtask


  //==================================================
  // Start checker
  //==================================================

  task run();

    fork

      check_A();

      check_B();

    join_none

  endtask


  //==================================================
  // Final report
  //==================================================

  task report();

    $display("");
    $display("================================================");
    $display("              CHECKER REPORT");
    $display("================================================");

    $display(
      "Packets Passed   : %0d",
      pass_count
    );

    $display(
      "Packets Failed   : %0d",
      fail_count
    );


    if (fail_count == 0)

      $display(
        "OVERALL RESULT   : PASS"
      );

    else

      $display(
        "OVERALL RESULT   : FAIL"
      );


    $display("================================================");

  endtask

endclass
