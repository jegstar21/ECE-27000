`default_nettype none

// Empty top module

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

  logic [7:0] Q, MAX, ctr;
  logic DIR, E, flash, hz1;

  count8du c8_1(.CLK(hz100), .RST(reset), .Q(ctr), .DIR(1'b0), .E(1'b1), .MAX(8'd49));
  hangman hg(.hz100(hz100), .reset(pb[19]), .hex(pb[15:10]), .ctrdisp(ss7[6:0]), .letterdisp({ss3[6:0], ss2[6:0], ss1[6:0], ss0[6:0]}), .win(green), .lose(red), .flash(flash));

  always_ff @ (posedge hz100, posedge reset) begin
    if (reset == 1)
      hz1 <= 1'b0;
    else
      hz1 <= ctr == 8'd49;
  end

  always_ff @ (posedge hz1, posedge reset) begin
    if (reset == 1)
      flash <= 0;
    else
      flash <= ~flash;
  end

  assign blue = flash; 

endmodule

// Add more modules down here...

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
