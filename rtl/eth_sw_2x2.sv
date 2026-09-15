module eth_sw_2x2 (

    // ============================================================
    // CLOCK AND RESET
    // ============================================================

    input  logic        clk,
    input  logic        rstN,


    // ============================================================
    // INPUT PORT A
    // ============================================================

    input  logic [31:0] inDataA,
    input  logic        sopA,
    input  logic        eopA,


    // ============================================================
    // INPUT PORT B
    // ============================================================

    input  logic [31:0] inDataB,
    input  logic        sopB,
    input  logic        eopB,


    // ============================================================
    // OUTPUT PORT A
    // ============================================================

    output logic [31:0] outDataA,
    output logic        sopOutA,
    output logic        eopOutA,


    // ============================================================
    // OUTPUT PORT B
    // ============================================================

    output logic [31:0] outDataB,
    output logic        sopOutB,
    output logic        eopOutB,


    // ============================================================
    // STALL
    // ============================================================

    output logic        portAStall,
    output logic        portBStall

);


    // ============================================================
    // DESTINATION ADDRESSES
    // ============================================================

    localparam logic [31:0] PORTA_ADDR = 32'h00000001;
    localparam logic [31:0] PORTB_ADDR = 32'h00000002;


    // ============================================================
    // FIFO PARAMETERS
    // ============================================================

    // Maximum number of 32-bit words in one packet.
    //
    // The exercise specifies Ethernet packets from 64 to
    // 1518 bytes. We use a word-oriented model here.
    //
    // 512 words is sufficient for the educational model.

    localparam integer MAX_WORDS = 512;


    // Number of complete packets that can wait in each input FIFO.

    localparam integer PACKET_QUEUE_DEPTH = 4;


    // ============================================================
    // PACKET MEMORY
    //
    // Input A FIFO
    // packet_mem_A[packet_number][word_number]
    //
    // Input B FIFO
    // packet_mem_B[packet_number][word_number]
    // ============================================================

    logic [31:0] packet_mem_A
        [0:PACKET_QUEUE_DEPTH-1]
        [0:MAX_WORDS-1];

    logic [31:0] packet_mem_B
        [0:PACKET_QUEUE_DEPTH-1]
        [0:MAX_WORDS-1];


    // ============================================================
    // PACKET INFORMATION
    // ============================================================

    integer packet_length_A [0:PACKET_QUEUE_DEPTH-1];
    integer packet_length_B [0:PACKET_QUEUE_DEPTH-1];

    logic [31:0] packet_dest_A [0:PACKET_QUEUE_DEPTH-1];
    logic [31:0] packet_dest_B [0:PACKET_QUEUE_DEPTH-1];


    // ============================================================
    // PACKET FIFO POINTERS
    // ============================================================

    integer wr_packet_A;
    integer rd_packet_A;

    integer wr_packet_B;
    integer rd_packet_B;


    // ============================================================
    // NUMBER OF COMPLETE PACKETS IN EACH INPUT FIFO
    // ============================================================

    integer packet_count_A;
    integer packet_count_B;


    // ============================================================
    // RECEIVE CONTROL
    // ============================================================

    integer rx_word_count_A;
    integer rx_word_count_B;

    logic rx_active_A;
    logic rx_active_B;


    // ============================================================
    // OUTPUT STATE
    // ============================================================

    typedef enum logic {
        OUTPUT_IDLE,
        OUTPUT_SEND
    } output_state_t;


    output_state_t output_state_A;
    output_state_t output_state_B;


    // ============================================================
    // OUTPUT SOURCE
    //
    // 0 = Input A
    // 1 = Input B
    // ============================================================

    logic output_source_A;
    logic output_source_B;


    // ============================================================
    // TRANSMIT WORD POINTER
    // ============================================================

    integer tx_word_A;
    integer tx_word_B;


    // ============================================================
    // MAIN SEQUENTIAL BLOCK
    // ============================================================

    always_ff @(posedge clk or negedge rstN) begin

        if (!rstN) begin

            // ====================================================
            // RESET INPUT A
            // ====================================================

            wr_packet_A     <= 0;
            rd_packet_A     <= 0;
            packet_count_A  <= 0;

            rx_word_count_A <= 0;
            rx_active_A     <= 1'b0;


            // ====================================================
            // RESET INPUT B
            // ====================================================

            wr_packet_B     <= 0;
            rd_packet_B     <= 0;
            packet_count_B  <= 0;

            rx_word_count_B <= 0;
            rx_active_B     <= 1'b0;


            // ====================================================
            // RESET OUTPUT A
            // ====================================================

            output_state_A  <= OUTPUT_IDLE;
            output_source_A <= 1'b0;
            tx_word_A       <= 0;


            // ====================================================
            // RESET OUTPUT B
            // ====================================================

            output_state_B  <= OUTPUT_IDLE;
            output_source_B <= 1'b0;
            tx_word_B       <= 0;


            // ====================================================
            // RESET OUTPUT SIGNALS
            // ====================================================

            outDataA <= 32'b0;
            sopOutA  <= 1'b0;
            eopOutA  <= 1'b0;

            outDataB <= 32'b0;
            sopOutB  <= 1'b0;
            eopOutB  <= 1'b0;

        end


        else begin

            // ====================================================
            // DEFAULT SOP/EOP
            //
            // SOP and EOP are pulses.
            // ====================================================

            sopOutA <= 1'b0;
            eopOutA <= 1'b0;

            sopOutB <= 1'b0;
            eopOutB <= 1'b0;


            // ====================================================
            // RECEIVE PACKET ON INPUT A
            // ====================================================

            if (sopA && !rx_active_A) begin

                // First word is Destination Address
                packet_mem_A[wr_packet_A][0] <= inDataA;

                packet_dest_A[wr_packet_A] <= inDataA;

                rx_word_count_A <= 1;

                rx_active_A <= 1'b1;


                // Single-word packet
                if (eopA) begin

                    packet_length_A[wr_packet_A] <= 1;

                    packet_count_A <= packet_count_A + 1;

                    wr_packet_A <=
                        (wr_packet_A + 1)
                        % PACKET_QUEUE_DEPTH;

                    rx_active_A <= 1'b0;

                end

            end


            else if (rx_active_A) begin

                // Store current packet word
                packet_mem_A[wr_packet_A][rx_word_count_A]
                    <= inDataA;

                rx_word_count_A <= rx_word_count_A + 1;


                // End of packet
                if (eopA) begin

                    packet_length_A[wr_packet_A]
                        <= rx_word_count_A + 1;

                    packet_count_A <= packet_count_A + 1;

                    wr_packet_A <=
                        (wr_packet_A + 1)
                        % PACKET_QUEUE_DEPTH;

                    rx_active_A <= 1'b0;

                end

            end


            // ====================================================
            // RECEIVE PACKET ON INPUT B
            // ====================================================

            if (sopB && !rx_active_B) begin

                // Destination Address
                packet_mem_B[wr_packet_B][0] <= inDataB;

                packet_dest_B[wr_packet_B] <= inDataB;

                rx_word_count_B <= 1;

                rx_active_B <= 1'b1;


                // Single-word packet
                if (eopB) begin

                    packet_length_B[wr_packet_B] <= 1;

                    packet_count_B <= packet_count_B + 1;

                    wr_packet_B <=
                        (wr_packet_B + 1)
                        % PACKET_QUEUE_DEPTH;

                    rx_active_B <= 1'b0;

                end

            end


            else if (rx_active_B) begin

                packet_mem_B[wr_packet_B][rx_word_count_B]
                    <= inDataB;

                rx_word_count_B <= rx_word_count_B + 1;


                // End of packet
                if (eopB) begin

                    packet_length_B[wr_packet_B]
                        <= rx_word_count_B + 1;

                    packet_count_B <= packet_count_B + 1;

                    wr_packet_B <=
                        (wr_packet_B + 1)
                        % PACKET_QUEUE_DEPTH;

                    rx_active_B <= 1'b0;

                end

            end


            // ====================================================
            // OUTPUT PORT A
            //
            // Destination = PORTA_ADDR
            // ====================================================

            case (output_state_A)


                // ------------------------------------------------
                // OUTPUT A IDLE
                // ------------------------------------------------

                OUTPUT_IDLE: begin

                    outDataA <= 32'b0;


                    // --------------------------------------------
                    // Input A packet destined for Output A
                    // --------------------------------------------

                    if ((packet_count_A > 0) &&
                        (packet_dest_A[rd_packet_A]
                         == PORTA_ADDR)) begin

                        output_source_A <= 1'b0;

                        tx_word_A <= 0;

                        output_state_A <= OUTPUT_SEND;

                    end


                    // --------------------------------------------
                    // Input B packet destined for Output A
                    // --------------------------------------------

                    else if ((packet_count_B > 0) &&
                             (packet_dest_B[rd_packet_B]
                              == PORTA_ADDR)) begin

                        output_source_A <= 1'b1;

                        tx_word_A <= 0;

                        output_state_A <= OUTPUT_SEND;

                    end

                end


                // ------------------------------------------------
                // OUTPUT A SEND
                // ------------------------------------------------

                OUTPUT_SEND: begin


                    // ============================================
                    // Packet came from Input A
                    // ============================================

                    if (output_source_A == 1'b0) begin

                        outDataA <=
                            packet_mem_A
                            [rd_packet_A]
                            [tx_word_A];


                        // First word
                        if (tx_word_A == 0)
                            sopOutA <= 1'b1;


                        // Last word
                        if (tx_word_A ==
                            packet_length_A[rd_packet_A] - 1) begin

                            eopOutA <= 1'b1;

                            packet_count_A <=
                                packet_count_A - 1;

                            rd_packet_A <=
                                (rd_packet_A + 1)
                                % PACKET_QUEUE_DEPTH;

                            tx_word_A <= 0;

                            output_state_A <= OUTPUT_IDLE;

                        end

                        else begin

                            tx_word_A <= tx_word_A + 1;

                        end

                    end


                    // ============================================
                    // Packet came from Input B
                    // ============================================

                    else begin

                        outDataA <=
                            packet_mem_B
                            [rd_packet_B]
                            [tx_word_A];


                        // First word
                        if (tx_word_A == 0)
                            sopOutA <= 1'b1;


                        // Last word
                        if (tx_word_A ==
                            packet_length_B[rd_packet_B] - 1) begin

                            eopOutA <= 1'b1;

                            packet_count_B <=
                                packet_count_B - 1;

                            rd_packet_B <=
                                (rd_packet_B + 1)
                                % PACKET_QUEUE_DEPTH;

                            tx_word_A <= 0;

                            output_state_A <= OUTPUT_IDLE;

                        end

                        else begin

                            tx_word_A <= tx_word_A + 1;

                        end

                    end

                end

            endcase


            // ====================================================
            // OUTPUT PORT B
            //
            // Destination = PORTB_ADDR
            // ====================================================

            case (output_state_B)


                // ------------------------------------------------
                // OUTPUT B IDLE
                // ------------------------------------------------

                OUTPUT_IDLE: begin

                    outDataB <= 32'b0;


                    // --------------------------------------------
                    // Input A packet destined for Output B
                    // --------------------------------------------

                    if ((packet_count_A > 0) &&
                        (packet_dest_A[rd_packet_A]
                         == PORTB_ADDR)) begin

                        output_source_B <= 1'b0;

                        tx_word_B <= 0;

                        output_state_B <= OUTPUT_SEND;

                    end


                    // --------------------------------------------
                    // Input B packet destined for Output B
                    // --------------------------------------------

                    else if ((packet_count_B > 0) &&
                             (packet_dest_B[rd_packet_B]
                              == PORTB_ADDR)) begin

                        output_source_B <= 1'b1;

                        tx_word_B <= 0;

                        output_state_B <= OUTPUT_SEND;

                    end

                end


                // ------------------------------------------------
                // OUTPUT B SEND
                // ------------------------------------------------

                OUTPUT_SEND: begin


                    // ============================================
                    // Packet came from Input A
                    // ============================================

                    if (output_source_B == 1'b0) begin

                        outDataB <=
                            packet_mem_A
                            [rd_packet_A]
                            [tx_word_B];


                        if (tx_word_B == 0)
                            sopOutB <= 1'b1;


                        if (tx_word_B ==
                            packet_length_A[rd_packet_A] - 1) begin

                            eopOutB <= 1'b1;

                            packet_count_A <=
                                packet_count_A - 1;

                            rd_packet_A <=
                                (rd_packet_A + 1)
                                % PACKET_QUEUE_DEPTH;

                            tx_word_B <= 0;

                            output_state_B <= OUTPUT_IDLE;

                        end

                        else begin

                            tx_word_B <= tx_word_B + 1;

                        end

                    end


                    // ============================================
                    // Packet came from Input B
                    // ============================================

                    else begin

                        outDataB <=
                            packet_mem_B
                            [rd_packet_B]
                            [tx_word_B];


                        if (tx_word_B == 0)
                            sopOutB <= 1'b1;


                        if (tx_word_B ==
                            packet_length_B[rd_packet_B] - 1) begin

                            eopOutB <= 1'b1;

                            packet_count_B <=
                                packet_count_B - 1;

                            rd_packet_B <=
                                (rd_packet_B + 1)
                                % PACKET_QUEUE_DEPTH;

                            tx_word_B <= 0;

                            output_state_B <= OUTPUT_IDLE;

                        end

                        else begin

                            tx_word_B <= tx_word_B + 1;

                        end

                    end

                end

            endcase

        end

    end


    // ============================================================
    // STALL
    //
    // Assert when the corresponding input packet FIFO is full.
    // ============================================================

    assign portAStall =
        (packet_count_A >= PACKET_QUEUE_DEPTH);

    assign portBStall =
        (packet_count_B >= PACKET_QUEUE_DEPTH);


endmodule