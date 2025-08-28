module apb_s (
    input         pclk,
    input         presetn,
    input  [31:0] paddr,
    input         psel,
    input         penable,
    input  [7:0]  pwdata,
    input         pwrite,
    output reg [7:0] prdata,
    output reg       pready,
    output reg       pslverr
);

    // Memory 16 x 8-bit
    reg [7:0] mem [0:15];

    // States
    typedef enum logic [1:0] {SETUP=2'b00, ACCESS=2'b01} state_t;
    state_t state, next_state;

    // Sequential: state update
    always @(posedge pclk or negedge presetn) begin
        if (!presetn)
            state <= SETUP;
        else
            state <= next_state;
    end

    // Main FSM
    always @(*) begin
        // Defaults
        prdata   = 8'h00;
        pready   = 1'b0;
        pslverr  = 1'b0;
        next_state = SETUP;

        case (state)
            // SETUP phase: sample address/control, wait for enable
            SETUP: begin
              if (psel && penable==0) begin
                    next_state = ACCESS;
                end
            end

            // ACCESS phase: perform read/write when penable=1
            ACCESS: begin
                if (psel && penable) begin
                    if (paddr < 16) begin
                        if (pwrite) begin
                            mem[paddr[3:0]] = pwdata;
                        end else begin
                            prdata = mem[paddr[3:0]];
                        end
                        pready = 1'b1; // Transfer complete
                    end else begin
                        pslverr = 1'b1;
                        pready  = 1'b1;
                    end
                end
                next_state = SETUP; // Go back after each transfer
            end
        endcase
    end

endmodule
