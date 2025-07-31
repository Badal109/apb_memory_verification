
// Code your design here
module APB_ram(
  input pclk,
  input presetn,
  input psel,
  input penable,
  input [31:0]paddr,
  input [7:0]pwdata,
  output [7:0]prdata,
  output pready,
  output slverr);
  reg  [1:0]state,n_state;
  localparam [1:0]idle=0;
  localparam [1:0]write=1;
  localparam [1:0]read=2;
  
  always@(posedge pclk or negedge presetn)
    begin
      if(presetn==1)
    end
  
