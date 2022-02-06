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

  simon game(.clk(hz100), .reset(reset), .in(pb[19:0]), .left(left), .right(right), .ss({ss7, ss6, ss5, ss4, ss3, ss2, ss1, ss0}), .win(green), .lose(red));
   

   typedef enum logic { RDY, ENT } simonstate_t;
endmodule

module clock_1hz(input hz100, reset, output logic hz1);

  logic [7:0] count, next_count;
  logic clk;

  always_ff @ (posedge hz100, posedge reset) begin
    if (reset)
      clk <= 0;
    else begin
      clk <= (count == 8'd49);
    end
  end

  always_ff @ (posedge clk, posedge reset) begin
    if (reset)
      hz1 <= 0;
    else begin
      hz1 <= ~hz1;
    end
  end

  always_ff @ (posedge hz100, posedge reset) begin
    if (reset)
      count <= 8'b0;
    else begin
      count <= next_count;
    end
  end

  always_comb begin
    if (count == 8'd49)
      next_count = 8'd0;
    else begin
      next_count[0] = ~count[0];
      next_count[1] =  count[1] ^   count[0];
      next_count[2] =  count[2] ^ (&count[1:0]);
      next_count[3] =  count[3] ^ (&count[2:0]);
      next_count[4] =  count[4] ^ (&count[3:0]);
      next_count[5] =  count[5] ^ (&count[4:0]);
      next_count[6] =  count[6] ^ (&count[5:0]);
      next_count[7] =  count[7] ^ (&count[6:0]);
    end
  end
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

module numentry (input logic clk ,rst, en, clr, input logic [4:0] in, output logic [31:0] out);

  logic [31:0] next_out;

  always_ff @ (posedge clk, posedge rst) begin
    if(rst)
      out <= 32'b0;
    else if (clr)
      out <= 32'b0;
    else begin
      if(en)
        out <= next_out;
    end
  end

  always_comb begin
      if (in < 5'd9 || in == 5'd9)
        if(out == 32'b0)
          next_out = {out[27:0], in[3:0]};
        else begin
          next_out = {out[27:0],4'b0}  | {28'b0, in[3:0]};
        end
      else begin
        next_out = out;
      end
  end

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

module simonctl(input logic clk, rst, lvlmax, win, lose, output logic state);

logic next_state;

typedef enum logic { RDY, ENT } simonstate_t;

always_ff @ (posedge clk, posedge rst) begin
  if (rst)
    state <= RDY;
  else begin
    state <= next_state;
  end
end

always_comb begin
  if (lose | (~lvlmax & win)) begin
    next_state = RDY;
  end

  else if (~lvlmax) begin  
    next_state = ENT;
  end
  else begin
    next_state = state;
  end
end

endmodule

module count8du_init(output logic [7:0] Q, input logic CLK, RST, DIR, E, input logic [7:0] INIT);

logic [7:0] next_Q;

always_ff @ (posedge CLK, posedge RST) begin
  if (RST == 1) begin
    Q <= INIT;
  end
  else if (E == 1) begin
    Q <= next_Q;
  end
end

always_comb begin
  if (DIR == 0) begin
    if (Q == 8'b0)
      next_Q = INIT;
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
    if (Q == INIT)
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
