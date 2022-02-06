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

  // Your code goes here...
  
  logic enable;
  
  ssdec sd(.in(right[3:0]), .enable(1'b1), .out(ss0[6:0]));
  prienc16to4 u1(.in(pb[15:0]), .out(right[3:0]), .strobe(enable));
  
endmodule

// Add your submodules below.

module ssdec (output logic [6:0] out, input logic enable, input logic [3:0] in);

    logic [6:0] SSD[15:0];
    
    assign SSD[4'h0] = (enable == 1) ? 7'b0111111 : 7'b0;
    assign SSD[4'h1] = (enable == 1) ? 7'b0000110 : 7'b0;
    assign SSD[4'h2] = (enable == 1) ? 7'b1011011 : 7'b0;
    assign SSD[4'h3] = (enable == 1) ? 7'b1001111 : 7'b0;
    assign SSD[4'h4] = (enable == 1) ? 7'b1100110 : 7'b0;
    assign SSD[4'h5] = (enable == 1) ? 7'b1101101 : 7'b0;
    assign SSD[4'h6] = (enable == 1) ? 7'b1111101 : 7'b0;
    assign SSD[4'h7] = (enable == 1) ? 7'b0000111 : 7'b0;
    assign SSD[4'h8] = (enable == 1) ? 7'b1111111 : 7'b0;
    assign SSD[4'h9] = (enable == 1) ? 7'b1100111 : 7'b0;
    assign SSD[4'ha] = (enable == 1) ? 7'b1110111 : 7'b0;
    assign SSD[4'hb] = (enable == 1) ? 7'b1111100 : 7'b0;
    assign SSD[4'hc] = (enable == 1) ? 7'b0111001 : 7'b0;
    assign SSD[4'hd] = (enable == 1) ? 7'b1011110 : 7'b0;
    assign SSD[4'he] = (enable == 1) ? 7'b1111001 : 7'b0;
    assign SSD[4'hf] = (enable == 1) ? 7'b1110001 : 7'b0;
    
    assign out = SSD[in];
    
endmodule

module prienc16to4(output logic strobe, output logic [3:0]out, input logic [15:0]in);

  assign {out, strobe} = in[15] == 1 ? 5'b11111 :
                         in[14] == 1 ? 5'b11101 :
                         in[13] == 1 ? 5'b11011 :
                         in[12] == 1 ? 5'b11001 :
                         in[11] == 1 ? 5'b10111 :
                         in[10] == 1 ? 5'b10101 :
                         in[9] == 1 ? 5'b10011 :
                         in[8] == 1 ? 5'b10001 :
                         in[7] == 1 ? 5'b01111 :
                         in[6] == 1 ? 5'b01101 :
                         in[5] == 1 ? 5'b01011 :
                         in[4] == 1 ? 5'b01001 :
                         in[3] == 1 ? 5'b00111 :
                         in[2] == 1 ? 5'b00101 :
                         in[1] == 1 ? 5'b00011 :
                         in[0] == 1 ? 5'b00001 : 5'b0000;
               
endmodule
