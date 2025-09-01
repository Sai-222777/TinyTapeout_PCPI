`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 08/31/2025 02:29:28 PM
// Design Name: 
// Module Name: pe
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module pe(
    input clk,
    input rst,
    input signed [15:0] a_in,
    input signed [15:0] b_in,
    input signed [31:0] c_in,
    output reg signed [15:0] a_out,
    output reg signed [15:0] b_out,
    output reg signed [31:0] c_out
);
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            c_out <= 0;
            a_out <= 0;
            b_out <= 0;
        end else begin
            c_out <= c_in + a_in * b_in;
            a_out <= a_in;
            b_out <= b_in;
        end
    end
endmodule
