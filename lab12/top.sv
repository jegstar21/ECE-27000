`default_nettype none

module top (
  // I/O ports
  input  logic hz100, reset,
  input  logic [20:0] pb,
  output logic [7:0] left, right,
         ss7, ss6, ss5, ss4, ss3, ss2, ss1, ss0,
  output logic red, green, blue,

  // UART ports
  output logic [7:0] txdata,
  input  logic [7:0] rxdata,
  output logic txclk, rxclk,
  input  logic txready, rxready
);

  // Step 1.5
  // Instantiate the Lunar Lander and set up a slower clock
  
  logic hzX;
  logic [7:0] ctr;
  
  count8du c8_1(.CLK(hz100), .RST(reset), .Q(ctr), .DIR(1'b0), .E(1'b1), .MAX(8'd25));
  
  always_ff @ (posedge hz100, posedge reset) begin
    if (reset == 1)
      hzX <= 0;
    else
      hzX <= (ctr == 8'd25);
  end
   
  lunarlander #(16'h800, 16'h4500, 16'h0, 16'h5) ll (.hz100(hz100), .clk(hzX), .rst(reset), .in(pb[19:0]), .crash(red), .land(green),.ss({ss7, ss6, ss5, ss4, ss3, ss2, ss1, ss0}));

endmodule

module lunarlander #(
  parameter FUEL=16'h800,
  parameter ALTITUDE=16'h4500,
  parameter VELOCITY=16'h0,
  parameter THRUST=16'h5,
  parameter GRAVITY=16'h5
)(
  input logic hz100, clk, rst,
  input logic [19:0] in,
  output logic [63:0] ss,
  output logic crash, land
);

  // Step 1.1
  // Use your bcdaddsub4 module to calculate landing parameters
  
  logic [15:0] alt, vel, fuel, thrust, newalt, newvel, newfuel, manualthrust, intval;

  bcdaddsub4 altitude(.a(alt), .b(vel), .op(1'b0), .s(newalt));
  bcdaddsub4 newval1(.a(vel), .b(GRAVITY), .op(1'b1), .s(intval));
  bcdaddsub4 newval2(.a(intval), .b(thrust), .op(1'b0), .s(newvel));
  bcdaddsub4 fuelnew(.a(fuel), .b(thrust), .op(1'b1), .s(newfuel));
  
  // Step 1.2
  // Set up a modifiable thrust register
  
  logic strobe;
  logic [4:0] keycode;
  
  scankey sk1(.clk(hz100), .rst(rst), .in(in), .strobe(strobe), .out(keycode));

  always_ff @ (posedge strobe, posedge rst)
    if(rst)
      manualthrust <= THRUST;
    else begin
      if (keycode <= 5'd9)
        manualthrust <= {12'b0, keycode[3:0]};
    end
  // Step 1.3
  // Set up the state machine logic for the lander
  
  typedef enum logic [2:0] {INIT = 0, CALC = 1, SET = 2, CHK = 3, HLT = 4} flight_t;
  logic [2:0] flight;
  logic nland, ncrash;

  always_ff @ (posedge clk, posedge rst)
    if (rst) begin
      flight <= INIT;
      crash <= 0;
      land <= 0;
      ncrash <= 0;
      nland <= 0;
      fuel <= FUEL;
      alt <= ALTITUDE;
      vel <= VELOCITY;
      thrust <= THRUST;
    end
    else begin
      case(flight)
        INIT: flight <= CALC;

        CALC: flight <= SET;

        SET: begin
          if(newfuel[15] == 1)
            fuel <= 0;
          else
            fuel <= newfuel;

          alt <= newalt;
          vel <= newvel;
          
          if((newfuel[15] == 1) || (fuel == 0))
            thrust <= 0;
          else
            thrust <= manualthrust;
            
          flight <= CHK;
        end

        CHK: begin
          if(newalt[15] == 1)
            if((thrust <= 16'd5) && (newvel > 16'h9970)) begin
            nland <= 1;
            flight <= HLT;
          end
            else begin
                ncrash <= 1;
                flight <= HLT;
          end
          else
            flight <= CALC;
        end

        HLT: begin
          land <= nland;
          crash <= ncrash;
          alt <= 0;
          vel <= 0;
        end
      endcase
    end

  
  // Step 1.4
  // Set up the display mechanics
  
  logic [23:0] lookupmsg [3:0];
  logic [1:0] sel;
  logic [15:0] val, negval;
  logic [63:0] valdisp, negvaldisp;


  always_comb begin
  
    lookupmsg[0] = 24'b011101110011100001111000;  // alt
    lookupmsg[1] = 24'b001111100111100100111000;  // vel
    lookupmsg[2] = 24'b011011110111011101101101;  // fuel (says gas)
    lookupmsg[3] = 24'b011110000111011001010000;  // thrust

    case(sel)
      0: val = alt;
      1: val = vel;
      2: val = fuel;
      3: val = thrust;
    endcase
  end

  bcdaddsub4 negative(.a(16'b0), .b(val), .op(1'b1), .s(negval));
  
  display_32_bit positive(.in({16'b0, val}), .out(valdisp));
  display_32_bit negativevalue(.in({16'b0, negval}), .out(negvaldisp));

  always_comb begin
    if(val[15] == 1)
      ss = {lookupmsg[sel], 8'b0, 8'b01000000, negvaldisp[23:0]};
    else
      ss = {lookupmsg[sel], 8'b0, valdisp[31:0]};
  end

  always_ff @ (posedge strobe, posedge rst)
    if (rst)
      sel <= 0;
   else begin
      if(keycode == 5'b10000)
        sel <= 3;
      else if(keycode == 5'b10001)
        sel <= 2;
      else if(keycode == 5'b10010)
        sel <= 1;
      else if(keycode == 5'b10011)
        sel <= 0;
    end

endmodule

module bcd9comp1(input logic [3:0] in, output logic [3:0] out);

  always_comb begin
    case(in)
      4'b0000: out = 4'b1001;
      4'b0001: out = 4'b1000;
      4'b0010: out = 4'b0111;
      4'b0011: out = 4'b0110;
      4'b0100: out = 4'b0101;
      4'b0101: out = 4'b0100;
      4'b0110: out = 4'b0011;
      4'b0111: out = 4'b0010;
      4'b1000: out = 4'b0001;
      4'b1001: out = 4'b0000;
      default: out = 4'b0;
    endcase
  end

endmodule

module bcdaddsub4(input logic [15:0] a, b, input logic op, output logic [15:0] s);

  logic [15:0] step10;

  bcd9comp1 d0(b[3:0], step10[3:0]);
  bcd9comp1 d1(b[7:4], step10[7:4]);
  bcd9comp1 d2(b[11:8], step10[11:8]);
  bcd9comp1 d3(b[15:12], step10[15:12]);

  bcdadd4   d4(a[15:0], (op == 1 ? step10[15:0] : b[15:0]), op, s[15:0]);

endmodule

module bcdadd1(input logic [3:0]a, b, input logic ci, output logic [3:0]s, output logic co);

  logic f_correction, carry;
  logic [3:0] z, sum;

  fa4 adder(a[3:0], b[3:0], ci, sum[3:0], carry);

  assign f_correction = carry | (sum[3] & sum[2]) | (sum[3] & sum[1]);

  assign z[0] = 1'b0;
  assign z[1] = f_correction;
  assign z[2] = f_correction;
  assign z[3] = 1'b0;
  
  assign co = f_correction;

  fa4 corrector(z[3:0], sum[3:0], 1'b0, s[3:0]);

endmodule

module bcdadd4 (input logic [15:0]a, b, input logic ci, output logic [15:0]s, output logic co);

  logic carry1, carry2, carry3;

  bcdadd1 s0(a[3:0],   b[3:0],   ci,     s[3:0],   carry1);
  bcdadd1 s1(a[7:4],   b[7:4],   carry1, s[7:4],   carry2);
  bcdadd1 s2(a[11:8],  b[11:8],  carry2, s[11:8],  carry3);
  bcdadd1 s3(a[15:12], b[15:12], carry3, s[15:12], co);


endmodule

module fa(input logic a, b, ci, output logic s, co);

  assign s = (a ^ b) ^ ci;
  assign co = (a & b) | (b & ci) | (a & ci);

endmodule

module fa4(input logic [3:0]a, b, input logic ci, output logic [3:0]s, output logic co);

  logic temp1, temp2, temp3, temp4;

  fa set0(.a(a[0]), .b(b[0]), .ci(ci), .s(s[0]), .co(temp1));
  fa set1(.a(a[1]), .b(b[1]), .ci(temp1), .s(s[1]), .co(temp2));
  fa set2(.a(a[2]), .b(b[2]), .ci(temp2), .s(s[2]), .co(temp3));
  fa set3(.a(a[3]), .b(b[3]), .ci(temp3), .s(s[3]), .co(temp4));
  
  assign co = temp4;

endmodule

module scankey(input logic clk, rst, input logic[19:0]in, output logic strobe, output logic[4:0]out);

  logic delay;

  always_ff @ (posedge clk, posedge rst) begin
    if(rst)
        delay <= 0;
    else begin
    delay <= (|in[19:0]);
    strobe <= delay;
    end
  end

  assign out[4] = {|in[19:16]} ? 1 : 0;
  assign out[3] = {|in[15:8]} ? 1 : 0;
  assign out[2] = {(|in[15:12]) | (|in[7:4])} ? 1 : 0;
  assign out[1] = {(|in[19:18]) | (|in[15:14]) | (|in[11:10]) | (|in[7:6]) | (|in[3:2])} ? 1 : 0;
  assign out[0] = {in[19] | in[17] | in[15] | in[13] | in[11] | in [9] | in[7] | in [5] | in[3] | in[1]} ? 1 : 0;

endmodule

module display_32_bit(input logic [31:0] in, output logic [63:0] out);

    ssdec s0(.in(in[3:0]), .enable(1'b1), .out(out[7:0]));
    ssdec s1(.in(in[7:4]), .enable(|in[31:4] ? 1'b1 : 1'b0), .out(out[15:8]));
    ssdec s2(.in(in[11:8]), .enable(|in[31:8] ? 1'b1 : 1'b0), .out(out[23:16]));
    ssdec s3(.in(in[15:12]), .enable(|in[31:12] ? 1'b1 : 1'b0), .out(out[31:24]));
    ssdec s4(.in(in[19:16]), .enable(|in[31:16] ? 1'b1 : 1'b0), .out(out[39:32]));
    ssdec s5(.in(in[23:20]), .enable(|in[31:20] ? 1'b1 : 1'b0), .out(out[47:40]));
    ssdec s6(.in(in[27:24]), .enable(|in[31:24] ? 1'b1 : 1'b0), .out(out[55:48]));
    ssdec s7(.in(in[31:28]), .enable(|in[31:28] ? 1'b1 : 1'b0), .out(out[63:56]));

endmodule

module ssdec (output logic [7:0] out, input logic enable, input logic [3:0] in);

    logic [7:0] SSD[15:0];

    assign SSD[4'h0] = (enable == 1) ? 8'b00111111 : 8'b0;
    assign SSD[4'h1] = (enable == 1) ? 8'b00000110 : 8'b0;
    assign SSD[4'h2] = (enable == 1) ? 8'b01011011 : 8'b0;
    assign SSD[4'h3] = (enable == 1) ? 8'b01001111 : 8'b0;
    assign SSD[4'h4] = (enable == 1) ? 8'b01100110 : 8'b0;
    assign SSD[4'h5] = (enable == 1) ? 8'b01101101 : 8'b0;
    assign SSD[4'h6] = (enable == 1) ? 8'b01111101 : 8'b0;
    assign SSD[4'h7] = (enable == 1) ? 8'b00000111 : 8'b0;
    assign SSD[4'h8] = (enable == 1) ? 8'b01111111 : 8'b0;
    assign SSD[4'h9] = (enable == 1) ? 8'b01100111 : 8'b0;
    assign SSD[4'ha] = (enable == 1) ? 8'b01110111 : 8'b0;
    assign SSD[4'hb] = (enable == 1) ? 8'b01111100 : 8'b0;
    assign SSD[4'hc] = (enable == 1) ? 8'b00111001 : 8'b0;
    assign SSD[4'hd] = (enable == 1) ? 8'b01011110 : 8'b0;
    assign SSD[4'he] = (enable == 1) ? 8'b01111001 : 8'b0;
    assign SSD[4'hf] = (enable == 1) ? 8'b01110001 : 8'b0;

    assign out = SSD[in];

endmodule

module count8du(output logic [7:0] Q, input logic CLK, RST, DIR, E, input logic [7:0] MAX);

logic [7:0] next_Q;

always_ff @ (posedge CLK, posedge RST) begin
  if (RST == 1) begin
    Q <= 8'b0;
  end
  else if (E == 1) begin
    Q <= next_Q;
  end
end

always_comb begin
  if (DIR == 0) begin
    if (Q == 8'b0)
      next_Q = MAX;
    else begin
      next_Q[0] = ~Q[0];
      next_Q[1] =  Q[1] ^   ~Q[0];
      next_Q[2] =  Q[2] ^ &(~Q[1:0]);
      next_Q[3] =  Q[3] ^ &(~Q[2:0]);
      next_Q[4] =  Q[4] ^ &(~Q[3:0]);
      next_Q[5] =  Q[5] ^ &(~Q[4:0]);
      next_Q[6] =  Q[6] ^ &(~Q[5:0]);
      next_Q[7] =  Q[7] ^ &(~Q[6:0]);
    end
  end
  else begin
    if (Q == MAX)
      next_Q = 8'd0;
    else begin
      next_Q[0] = ~Q[0];
      next_Q[1] =  Q[1] ^   Q[0];
      next_Q[2] =  Q[2] ^ (&Q[1:0]);
      next_Q[3] =  Q[3] ^ (&Q[2:0]);
      next_Q[4] =  Q[4] ^ (&Q[3:0]);
      next_Q[5] =  Q[5] ^ (&Q[4:0]);
      next_Q[6] =  Q[6] ^ (&Q[5:0]);
      next_Q[7] =  Q[7] ^ (&Q[6:0]);
    end
  end
end

endmodule
