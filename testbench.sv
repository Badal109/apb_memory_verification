// Code your testbench here
// or browse Examples


interface apb_if();
    logic clk;
   logic[31:0] paddr;
  logic [7:0] pwdata;
  logic penable;
  logic psel;
  logic [7:0]prdata;
  logic pslverr;
  logic pready;
  logic pwrite ;
  logic presetn;
endinterface
class transaction ;
  
  

  rand bit[31:0] paddr;
  rand bit [7:0] pwdata;
  bit penable;
  bit psel;
  bit [7:0]prdata;
  bit pslverr;
  bit pready;
  bit pwrite ;
  bit presetn;
  
  constraint cons_t{
   paddr>=0;
  paddr<=15;
  }
  
  constraint cons1{
  
  pwdata>=0;
  pwdata<=255;
  }
  function void display(input string tag);
    $display("[%0s]: paddr:%0d pwdata:%0d,pwrite:%0b,prdata:%0d,@%0t",tag ,paddr,pwdata,pwrite,prdata,pslverr,$time);
  endfunction
  
endclass 


class generator;
  transaction tr;    ////////////
  mailbox #(transaction)gen2drv;
  int count=0;
  event nextdrv;
  event nextsco;
  event done;
  function new ( mailbox #(transaction)mbx);
    this.gen2drv=mbx;
     tr=new();
  endfunction
  
  task run();
    repeat(count)
      begin
        assert(tr.randomize())else $error("randomization failed");
        gen2drv.put(tr);
        tr.display("GEN");
        @(nextdrv);
        @(nextsco);
        
      
        
      end
    ->done;
  endtask
  
  
endclass 

class driver;
  transaction tr;
  mailbox#(transaction) gen2drv;
  virtual apb_if vif;
  event nextdrv;
  function new(mailbox#(transaction) mbx);
    this.gen2drv=mbx;
  endfunction
  
  
  task reset ();
    vif.presetn<=1'b0;
    vif.psel<=1'b0;
    vif.penable<=1'b0;
    vif.pwdata<=0;
    vif.pwrite<=1'b0;
    vif.paddr<=0;
    repeat(5)@( posedge vif.clk) ;
    vif.presetn<=1'b1;
    $display("[DRV]:reset done ");
    
    $display("------------------------------");
  endtask 
  
  task run();
    forever begin
      
    gen2drv.get(tr);
    repeat (2)@(posedge vif.clk);
    
    if(tr.pwrite==1)      //write operation
      begin
        vif.psel<=1'b1;
      
        vif.penable<=1'b0;
          vif.pwdata<=tr.pwdata;
        vif.paddr<=tr.paddr;
        vif.pwrite<=1'b1;
        @(posedge vif.clk);
        vif.penable<=1'b1;
         @(posedge vif.clk);
        vif.penable<=1'b0;
        vif.pwrite<=1'b0;
        vif.psel<=1'b0;
        tr.display("DRV");
         ->nextdrv;
      end
    
      else if(tr.pwrite==0)      //wread operation
      begin
        vif.psel<=1'b1;
    
        vif.penable<=1'b0;
              vif.pwdata<=0;
        vif.paddr<=tr.paddr;
      vif.pwrite<=1'b0;
        @(posedge vif.clk);
        vif.penable<=1'b1;
         @(posedge vif.clk);
        vif.penable<=1'b0;
        vif.pwrite<=1'b0;
        vif.psel<=1'b0;
        $display("DRV");
         ->nextdrv;
      end
    end
   
  endtask
  
endclass 

  
  
  
  class monitor;
    transaction tr;
    mailbox#(transaction )mon2sco;
    virtual apb_if vif;
    function new ( mailbox#(transaction )mon2sco);
      this.mon2sco=mon2sco;
      
    endfunction
    
    task run();
      tr=new();
      forever begin
        
        repeat(1)@(posedge vif.clk);
        if(vif.pready==1'b1)
          begin
            tr.pwdata  = vif.pwdata;
              tr.paddr   = vif.paddr;
            tr.pwrite  = vif.pwrite;
            tr.prdata  = vif.prdata;
            tr.pslverr = vif.pslverr;
            @(posedge vif.clk);
            tr.display("MON");
            mon2sco.put(tr);
        
          end
              end
    endtask
    
              
    
  endclass 
                   
  
  class scoreboard;
    transaction tr;
    mailbox#(transaction) mon2sco;
   event nextsco;
    bit [7:0]pwdata[16]='{default:0};;
    bit [7:0]rdata;
    int err=0;
    
    
    function new(mailbox#(transaction)mon2sco);
      this.mon2sco=mon2sco;
      
    endfunction
    
    task run();
      forever begin
        mon2sco.get(tr);
        tr.display("SCO");
        if((tr.pwrite==1'b1)&&(tr.pslverr==0))
          begin
            pwdata[tr.paddr]=tr.pwdata;
            $display("[SCO]:DATA STORED DATA:%0d ADDR:%0d",tr.pwdata,tr.paddr);
            
            end
        else if((tr.pwrite==1'b0)&&(tr.pslverr==0))
          begin
            rdata=pwdata[tr.paddr];
            if(tr.prdata==rdata)
              begin
                $display("[sco]:DATA ,MATCHED");
                
              end
            else
              begin
                err++;
                $display("[sco]:DATA not MATCHED");
                
              end
       
            
            end
        else if(tr.pslverr==1'b1)
          begin
            $display("[SCO]:error detected");
            
          end
        $display("------------------------------------------");
            
        ->nextsco;
        
      end
    endtask
    
    
  endclass
  
  class environment;
    generator gen;
    monitor mon;
    driver drv;
    scoreboard sco;
    
     event nextgen2drv;
     event nextmon2sco;
    mailbox #(transaction)gen2drv;
    mailbox#(transaction)mon2sco;
    
    
    
    virtual apb_if vif;
    function new (virtual apb_if vif);
      gen2drv=new();
    mon2sco=new();
      gen=new(gen2drv);
      drv=new(gen2drv);
      
      mon=new(mon2sco);
      sco=new(mon2sco);
      
       this.vif=vif;
      drv.vif=this.vif;
      mon.vif=this.vif;
      
      gen.nextdrv=nextgen2drv;
      drv.nextdrv=nextgen2drv;
      gen.nextsco=nextmon2sco;
      sco.nextsco=nextmon2sco;
    endfunction
    
    task pre_test ();
      drv.reset();
      
    endtask
    task test();
      fork
        gen.run();
        drv.run();
        mon.run();
        sco.run();
        
      join_any
    endtask
    task post_test();
      wait(gen.done.triggered);
       $display("----Total number of Mismatch : %0d------",sco.err);
      $finish();
    endtask
    
    task run();
      pre_test();
      test();
      post_test();
      
    endtask
    
  endclass
  
  
  
  module testbench();
    apb_if vif();
 
   
   APB_ram dut (
   vif.clk,
   vif.presetn,
   vif.pwrite,
   vif.paddr,
   vif.pwdata,
   vif.psel,
   vif.penable,
   vif.prdata,
   vif.pready,
   vif.pslverr
   );
   
    initial begin
      vif.clk <= 0;
    end
    
    always #10 vif.clk <= ~vif.clk;
    
    environment env;
    
    
    
    initial begin
      env = new(vif);
      env.gen.count = 20;
      env.run();
    end
      
    
    initial begin
      $dumpfile("dump.vcd");
      $dumpvars;
    end
   
    
 
  endmodule
    
