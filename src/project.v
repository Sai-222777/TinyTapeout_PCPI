/*
 * Copyright (c) 2024 Your Name
 * SPDX-License-Identifier: Apache-2.0
 */

`default_nettype none

module tt_um_Sai_222777 (
    input  wire [7:0] ui_in,    // Dedicated inputs
    output wire [7:0] uo_out,   // Dedicated outputs
    input  wire [7:0] uio_in,   // IOs: Input path
    output wire [7:0] uio_out,  // IOs: Output path
    output wire [7:0] uio_oe,   // IOs: Enable path (active high: 0=input, 1=output)
    input  wire       ena,      // always 1 when the design is powered, so you can ignore it
    input  wire       clk,      // clock
    input  wire       rst_n     // reset_n - low to reset
);
    
    assign uio_out = 0;
    assign uio_oe  = 0;

    wire _unused = &{ena, 1'b0};
    wire [7:0] unused;
    assign unused = uio_in;
    
    wire [3:0] instruction_segment;
    wire sending_current,received_current;
    assign instruction_segment = ui_in[4:1];
    assign sending_current = ui_in[0];
    assign uo_out = {7'b0,received_current};
    
    reg pcpi_valid;
    reg [31:0] instruction_latched;
    wire pcpi_ready;

    wire pcpi_wait, pcpi_wr;
    wire [31:0] pcpi_rd;
    
    fused_matrix_mult_pcpi pcpi_unit(
        .clk(clk),
        .resetn(rst_n),
        .pcpi_valid(pcpi_valid),
        .pcpi_insn(instruction_latched),
        .pcpi_ready(pcpi_ready),
        .pcpi_wr(pcpi_wr),
        .pcpi_wait(pcpi_wait),
        .pcpi_rd(pcpi_rd)
    );
    
    
    reg [2:0] count;
    genvar e;
    generate
        for(e=0;e<8;e=e+1)
        begin
            always @(posedge clk)
            begin
                if(received_current && e==count)
                begin
                    instruction_latched[4*(e+1)-1:4*e] <= instruction_segment;
                end
            end
        end
    endgenerate
    
    reg [1:0] state;
    assign received_current = state == 2'b01;
    
    always @(posedge clk)
    begin
        if(!rst_n)
        begin
            count <= 0;
            state <= 2'b00;
            pcpi_valid <= 0;
        end
        else
        begin
            case(state)
                2'b00 :
                begin
                    if(sending_current)
                    begin
                        state <= 1;
                    end
                end
                2'b01 :
                begin
                    if(count < 7)
                    begin
                        count <= count + 1;
                        state <= 0;
                    end
                    else
                    begin
                        count <= 0;
                        state <= 2; //state <= 2; should actually be 2, but changed it for testbench simulation
                        pcpi_valid <= 1;
                    end
                end
                2'b10:
                begin
                    pcpi_valid <= 0;
                    state <= 3;
                end
                2'b11:
                begin
                    if(pcpi_ready)
                    begin
                        state <= 0;
                    end
                end
            endcase
        end
    end
    
endmodule
