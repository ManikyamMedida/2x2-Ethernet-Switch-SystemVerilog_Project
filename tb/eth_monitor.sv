
class eth_monitor;

  virtual eth_sw_if.MONITOR vif;

  int port;

  mailbox mon2chk;


  function new(
    virtual eth_sw_if.MONITOR vif,
    int port,
    mailbox mon2chk
  );

    this.vif = vif;
    this.port = port;
    this.mon2chk = mon2chk;

  endfunction


  function string port_name();

    if (port == 0)
      return "INPUT_A";

    else if (port == 1)
      return "INPUT_B";

    else if (port == 2)
      return "OUTPUT_A";

    else
      return "OUTPUT_B";

  endfunction


  task run_once(eth_packet pkt);

    bit [31:0] words[$];
    bit [31:0] word;

    int i;


    words.delete();


    //========================================
    // INPUT A
    //========================================

    if (port == 0) begin

      @(vif.mon_cb);

      while (vif.mon_cb.sopA !== 1'b1)
        @(vif.mon_cb);

      word = vif.mon_cb.inDataA;
      words.push_back(word);


      while (vif.mon_cb.eopA !== 1'b1) begin

        @(vif.mon_cb);

        word = vif.mon_cb.inDataA;
        words.push_back(word);

      end

    end


    //========================================
    // INPUT B
    //========================================

    else if (port == 1) begin

      @(vif.mon_cb);

      while (vif.mon_cb.sopB !== 1'b1)
        @(vif.mon_cb);

      word = vif.mon_cb.inDataB;
      words.push_back(word);


      while (vif.mon_cb.eopB !== 1'b1) begin

        @(vif.mon_cb);

        word = vif.mon_cb.inDataB;
        words.push_back(word);

      end

    end


    //========================================
    // OUTPUT A
    //========================================

    else if (port == 2) begin

      @(vif.mon_cb);

      while (vif.mon_cb.sopOutA !== 1'b1)
        @(vif.mon_cb);

      word = vif.mon_cb.outDataA;
      words.push_back(word);


      while (vif.mon_cb.eopOutA !== 1'b1) begin

        @(vif.mon_cb);

        word = vif.mon_cb.outDataA;
        words.push_back(word);

      end

    end


    //========================================
    // OUTPUT B
    //========================================

    else begin

      @(vif.mon_cb);

      while (vif.mon_cb.sopOutB !== 1'b1)
        @(vif.mon_cb);

      word = vif.mon_cb.outDataB;
      words.push_back(word);


      while (vif.mon_cb.eopOutB !== 1'b1) begin

        @(vif.mon_cb);

        word = vif.mon_cb.outDataB;
        words.push_back(word);

      end

    end


    //========================================
    // Convert captured words into packet
    //========================================

    pkt.data_length = words.size();

    pkt.data = new[words.size()];


    for (i = 0; i < words.size(); i = i + 1)
      pkt.data[i] = words[i];


    if (words.size() >= 1)
      pkt.da = words[0];


    if (words.size() >= 2)
      pkt.sa = words[1];


    if (words.size() >= 3)
      pkt.crc = words[2];


    if (words.size() >= 3)
      pkt.payload_length = words.size() - 3;

    else
      pkt.payload_length = 0;


    //========================================
    // Display
    //========================================

    $display(
      "MONITOR %s captured packet, %0d words",
      port_name(),
      words.size()
    );


    //========================================
    // Send packet to checker
    //========================================

    mon2chk.put(pkt);


    $display(
      "MONITOR %s sent packet to checker mailbox",
      port_name()
    );

  endtask

endclass
