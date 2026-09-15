# 2×2 Ethernet Switch -- SystemVerilog Design & Verification

A complete **SystemVerilog RTL design and verification project** for a
2×2 Ethernet switch, developed and verified using **Siemens QuestaSim**.

The project implements destination-based packet routing between two
input ports and two output ports. A modular, object-oriented
verification environment was developed using SystemVerilog classes,
constrained-randomization, virtual interfaces, clocking blocks,
mailboxes, monitors, a reference model, and a packet checker.

------------------------------------------------------------------------

## Project Overview

The Ethernet switch contains:

-   2 input ports: `INPUT_A` and `INPUT_B`
-   2 output ports: `OUTPUT_A` and `OUTPUT_B`
-   32-bit data path
-   SOP/EOP packet framing
-   Destination-address-based routing
-   Packet buffering using FIFOs
-   Input backpressure/stall handling
-   Variable-length Ethernet frames

The verification environment generates directed and constrained-random
traffic and automatically checks DUT output against the expected
behavior predicted by a reference model.

------------------------------------------------------------------------

## DUT Architecture

The switch routes packets according to the destination address (`DA`).

  Destination Address   Expected Output
  --------------------- -----------------
  `32'h00000001`        `OUTPUT_A`
  `32'h00000002`        `OUTPUT_B`

Both input ports can generate traffic, and the design supports
concurrent traffic and output contention.

### Packet Format

``` text
+----------------+----------------+----------------+
| Destination    | Source         | CRC            |
| Address (DA)   | Address (SA)   |                |
+----------------+----------------+----------------+
|                 Payload Data                    |
+-------------------------------------------------+
```

The packet is transmitted over a 32-bit data interface.

------------------------------------------------------------------------

## Ethernet Frame Size Support

The verification environment supports Ethernet frame sizes from the
minimum Ethernet frame size to the maximum standard Ethernet frame size.

  Frame Size   32-bit Words
  ------------ --------------
  64 bytes     16 words
  1518 bytes   379 words

The packet structure contains three initial 32-bit words for `DA`, `SA`,
and `CRC`, with the remaining words representing payload data.

------------------------------------------------------------------------

## Verification Environment

The verification environment is implemented using **SystemVerilog OOP
concepts**.

``` text
                         +------------------+
                         |    Generator     |
                         | Directed +       |
                         | Random Packets   |
                         +--------+---------+
                                  |
                             Mailboxes
                                  |
                         +--------v---------+
                         |      Driver      |
                         | Input A / Input B|
                         | Stall Handling   |
                         +--------+---------+
                                  |
                                  v
                    +--------------------------+
                    |           DUT            |
                    |   2×2 Ethernet Switch    |
                    +------------+-------------+
                                 |
                    +------------+-------------+
                    |                          |
             +------v------+           +------v------+
             |   Monitor   |           |   Monitor   |
             | Input/Output|           | Input/Output|
             +------+------+           +------+------+
                    |                          |
                    +------------+-------------+
                                 |
                        +--------v---------+
                        | Reference Model  |
                        | Expected Routing |
                        +--------+---------+
                                 |
                        +--------v---------+
                        |     Checker      |
                        | Packet Compare   |
                        +------------------+
```

------------------------------------------------------------------------

## Verification Components

### 1. Packet

**File:** `tb/eth_packet.sv`

Defines the Ethernet packet object used throughout the verification
environment.

The packet contains:

-   Destination address (`da`)
-   Source address (`sa`)
-   CRC (`crc`)
-   Payload data
-   Payload length
-   Total data length

The packet uses SystemVerilog randomization and constraints to generate
valid stimulus.

Destination addresses are constrained to:

``` systemverilog
32'h00000001
32'h00000002
```

Payload length is constrained between 13 and 376 words, corresponding to
the supported minimum and maximum frame sizes.

The packet class also provides:

-   `post_randomize()`
-   `display()`
-   `copy()`

------------------------------------------------------------------------

### 2. Transaction

**File:** `tb/eth_transaction.sv`

Represents a verification transaction containing:

-   Ethernet packet
-   Input port information

------------------------------------------------------------------------

### 3. Generator

**File:** `tb/eth_generator.sv`

Creates stimulus for the DUT.

Supports:

-   Directed packets
-   Constrained-random packets
-   Destination-directed traffic
-   Different packet sizes
-   Traffic from both input ports

------------------------------------------------------------------------

### 4. Driver

**File:** `tb/eth_driver.sv`

Converts generated transactions into DUT interface activity.

Responsible for:

-   Driving packet data
-   Generating SOP
-   Generating EOP
-   Driving Input A
-   Driving Input B
-   Handling DUT backpressure
-   Supporting concurrent traffic

The driver observes `portAStall` and `portBStall` and waits when the
corresponding input is stalled.

------------------------------------------------------------------------

### 5. Monitor

**File:** `tb/eth_monitor.sv`

Observes DUT activity and reconstructs packets from the interface.

The monitor detects:

``` text
SOP
Packet Data
EOP
```

Separate monitoring is performed for:

``` text
INPUT_A
INPUT_B
OUTPUT_A
OUTPUT_B
```

Captured packets are transferred using mailboxes.

------------------------------------------------------------------------

### 6. Reference Model

**File:** `tb/eth_reference_model.sv`

Predicts where each packet should appear.

``` text
DA = 1  →  OUTPUT_A
DA = 2  →  OUTPUT_B
```

Packets captured from the input monitors are classified into expected
output queues.

------------------------------------------------------------------------

### 7. Checker

**File:** `tb/eth_checker.sv`

Compares packets observed at the DUT outputs against packets predicted
by the reference model.

The checker performs packet-level comparison and supports
order-independent matching using packet information.

It reports:

-   Individual packet PASS/FAIL
-   Total packets passed
-   Total packets failed
-   Overall regression result

------------------------------------------------------------------------

### 8. Functional Coverage

**File:** `tb/eth_coverage.sv`

A functional coverage component is included to track packet and
routing-related scenarios.

The current coverage model is a preliminary implementation. Further
refinement of functional coverage and assertion-based verification are
planned as future enhancements.

------------------------------------------------------------------------

## SystemVerilog Concepts Used

This project demonstrates practical use of:

-   SystemVerilog classes
-   Object-oriented programming
-   Encapsulation
-   Randomization
-   Constraints
-   `post_randomize()`
-   Dynamic arrays
-   Queues
-   Mailboxes
-   Virtual interfaces
-   Modports
-   Clocking blocks
-   Tasks
-   Functions
-   Concurrent processes
-   Packet copying
-   Reference modeling
-   Scoreboard/checker concepts
-   Constrained-random verification
-   Functional coverage

------------------------------------------------------------------------

## Verification Test Plan

The regression consists of 13 test scenarios.

  Test   Scenario                                 Result
  ------ ---------------------------------------- --------
  1      INPUT_A → OUTPUT_A                       PASS
  2      INPUT_A → OUTPUT_B                       PASS
  3      INPUT_B → OUTPUT_A                       PASS
  4      INPUT_B → OUTPUT_B                       PASS
  5      Random packet from INPUT_A               PASS
  6      Random packet from INPUT_B               PASS
  7      Minimum Ethernet frame                   PASS
  8      Maximum Ethernet frame                   PASS
  9      Back-to-back packets                     PASS
  10     Simultaneous INPUT_A + INPUT_B traffic   PASS
  11     Both inputs → OUTPUT_A                   PASS
  12     Both inputs → OUTPUT_B                   PASS
  13     Mixed random traffic                     PASS

------------------------------------------------------------------------

## Regression Results

The complete regression was executed using QuestaSim.

``` text
================================================
              CHECKER REPORT
================================================
Packets Passed   : 26
Packets Failed   : 0
OVERALL RESULT   : PASS
================================================
```

### Final Result

**26 / 26 packets passed**

**0 packet failures**

The regression validates:

-   Destination-based routing
-   Both input ports
-   Both output ports
-   Minimum packet size
-   Maximum packet size
-   Back-to-back traffic
-   Simultaneous traffic
-   Output contention
-   Random traffic
-   Mixed traffic
-   DUT backpressure handling

------------------------------------------------------------------------

## Waveform

The final simulation waveform monitors the major DUT interface signals:

``` text
clk
rstN

inDataA
sopA
eopA

inDataB
sopB
eopB

outDataA
sopOutA
eopOutA

outDataB
sopOutB
eopOutB

portAStall
portBStall
```

The waveform demonstrates reset operation, packet transmission, SOP/EOP
framing, input traffic, output routing, simultaneous traffic, and
backpressure/stall behavior.

Place the final waveform screenshot at:

``` text
docs/waveform_final.png
```

------------------------------------------------------------------------

## Project Structure

``` text
2x2-Ethernet-Switch-SystemVerilog_Project/
│
├── rtl/
│   ├── eth_sw_2x2.sv
│   └── eth_sw_if.sv
│
├── tb/
│   ├── eth_packet.sv
│   ├── eth_transaction.sv
│   ├── eth_generator.sv
│   ├── eth_driver.sv
│   ├── eth_monitor.sv
│   ├── eth_reference_model.sv
│   ├── eth_checker.sv
│   ├── eth_coverage.sv
│   └── tb_eth_sw_2x2.sv
│
├── docs/
│   └── waveform_final.png
│
├── .gitignore
└── README.md
```

QuestaSim-generated files and compiled libraries are excluded from the
repository using `.gitignore`.

------------------------------------------------------------------------

## Simulation Environment

  Item                 Details
  -------------------- --------------------------
  HDL                  SystemVerilog
  Simulator            Siemens QuestaSim
  Platform             Windows
  Verification Style   OOP / Constrained-Random
  Communication        SystemVerilog Mailboxes

------------------------------------------------------------------------

## How to Run

The testbench uses SystemVerilog `` `include `` statements to include
the verification class files.

From the project directory, compile the interface and RTL:

``` tcl
vlib work

vlog -sv -work work rtl/eth_sw_if.sv
vlog -sv -work work rtl/eth_sw_2x2.sv
```

Compile the testbench with the verification source directory in the
include path:

``` tcl
vlog -sv -work work +incdir+tb tb/tb_eth_sw_2x2.sv
```

Start the simulation:

``` tcl
vsim -sv_seed random -voptargs=+acc work.tb_eth_sw_2x2
```

Run the complete regression:

``` tcl
run -all
```

------------------------------------------------------------------------

## Verification Flow

``` text
             Packet Creation
                    |
                    v
        Constrained Randomization
                    |
                    v
               Generator
                    |
                    v
                Mailbox
                    |
                    v
                 Driver
                    |
                    v
                   DUT
                    |
          +---------+---------+
          |                   |
          v                   v
      Output A            Output B
          |                   |
          v                   v
       Monitor             Monitor
          |                   |
          +---------+---------+
                    |
                    v
            Reference Model
                    |
                    v
                Checker
                    |
                    v
               PASS / FAIL
```

------------------------------------------------------------------------

## Key Verification Features

### Constrained-Random Verification

Random packet generation is used while maintaining valid destination
addresses and packet-size constraints.

### Directed Verification

Specific routing paths are explicitly tested to verify all combinations
of input and output ports.

### Concurrent Traffic

Both input ports can generate traffic concurrently.

### Backpressure Verification

The driver respects DUT stall signals and waits when the corresponding
packet queue is full.

### Boundary Testing

The minimum and maximum Ethernet frame sizes are explicitly verified.

### Output Contention

Multiple packets targeting the same output are tested.

### Order-Independent Checking

The checker does not rely solely on a fixed global arrival order.
Packets are matched using packet information to support concurrent and
contention scenarios.

------------------------------------------------------------------------

## Verification Summary

  Category                Status
  ----------------------- ----------------
  Directed Routing        PASS
  Random Traffic          PASS
  Minimum Frame           PASS
  Maximum Frame           PASS
  Back-to-Back Traffic    PASS
  Simultaneous Traffic    PASS
  Output Contention       PASS
  Backpressure Handling   PASS
  Packet Checking         PASS
  Regression              **26/26 PASS**

------------------------------------------------------------------------

## Future Enhancements

Planned improvements include:

-   Refine functional coverage model
-   Add SystemVerilog Assertions (SVA)
-   Increase constrained-random regression depth
-   Add additional corner-case scenarios
-   Add protocol-level Ethernet checks
-   Add stress testing for FIFO boundaries
-   Improve coverage closure
-   Develop a complete UVM-based verification environment

------------------------------------------------------------------------

## Technologies Used

``` text
SystemVerilog
QuestaSim
RTL Design
Object-Oriented Verification
Constrained-Random Verification
Mailboxes
Virtual Interfaces
Clocking Blocks
Reference Model
Scoreboard / Checker
Functional Coverage
```

------------------------------------------------------------------------

## Author

**Manikyam Medida**

GitHub: [ManikyamMedida](https://github.com/ManikyamMedida)

------------------------------------------------------------------------

## Project Highlights

> **Designed and verified a 2×2 Ethernet switch using SystemVerilog and
> QuestaSim, implementing destination-based packet routing between two
> input and two output ports. Developed an object-oriented,
> mailbox-based verification environment with constrained-random packet
> generation, virtual interfaces, clocking blocks, drivers, monitors,
> reference model, and automated packet checking. Verified directed,
> random, back-to-back, simultaneous, contention, minimum/maximum frame,
> and mixed-traffic scenarios with 26/26 packets passing.**
