// Code your design here
module APB_ram(input clk,
               input presetn,
               input pwrite,
               input [31:0]paddr,
               input [7:0]pwdata,
               input psel,
               input penable,
               output reg [7:0]prdata,
               output  reg pready,
               output reg pslverr);
  
  reg [2:0]state;
  reg [2:0]next_state;
  
  localparam [2:0]idle=0;
  localparam [2:0]write=1;
  localparam  [2:0]read=2;
  reg [7:0]mem[16];
  bit addr_err,addv_err,data_err,setup_apb_err;
  
  always@(posedge clk or negedge presetn)
    begin
      if(presetn==1'b0)
        begin
          state<=idle ;
        end
      else
        begin
          state<=next_state;
          
        end
     
    end
  
  
  always@(*)
    begin
      case(state)
        idle:begin
          prdata=8'h00;
          pready=1'b0;
          if(psel==1&& pwrite==1'b1)
            begin
              next_state=write;
              
            end
          else if(psel==1'b1&&pwrite==1'b0)
            begin
              next_state=read;
              
            end
          else
            next_state=idle;
        end
        write:
          begin
            
          if(psel==1'b1&&penable==1'b1)
          begin
            if(!addr_err&&!addv_err&&!data_err)
              begin
                pready=1'b1;
                mem[paddr]=pwdata;
                next_state=idle;
              end
            else
              begin
                  pready=1'b1;
                    next_state=idle;
                
              end
            
          end
              end
        read:
         begin
            
          if(psel==1'b1&&penable==1'b1)
          begin
            if(!addr_err&&!addv_err&&!data_err)
              begin
                pready=1'b1;
                prdata=mem[paddr];
                next_state=idle;
              end
            else
              begin
                  pready=1'b1;
                prdata=8'h00;
                    next_state=idle;
                
              end
            
          end
              end
        default:
          begin
           pready=1'b0;
                prdata=8'h00;
                    next_state=idle;
          end
      endcase
    end
  //////checking valid values of adress
  
  reg av_t=0;
  reg dv_t=0;
  
  always@(*)
    begin
      if(paddr>=0)
        av_t=1'b0;
     
  else
    begin
      av_t=1'b1;
    end
    end
  
    
  always@(*)
    begin
      if(pwdata>=0)
        dv_t=1'b0;
     
  else
    begin
      dv_t=1'b1;
    end
    end
  
  assign addr_err=((next_state==write||read)&&(paddr>15))?1'b1:1'b0;
  assign addv_err=(next_state==write||read)?av_t:1'b0;
  assign data_err=(next_state==write||read)?dv_t:1'b0;
  assign pslverr=(psel==1'b1&&penable==1'b1)?(addr_err||data_err||data_err):1'b0;
endmodule
  
  
  
  
  
  
