// `timescale 1ns / 1ps

module fused_matrix_mult_pcpi (
    input         clk,
    input         resetn,
    input         pcpi_valid,
    input  [31:0] pcpi_insn,
    output        pcpi_wr,
    output [31:0] pcpi_rd,
    output        pcpi_wait,
    output        pcpi_ready
);

    wire [6:0] opcode;
    assign opcode = pcpi_insn[6:0];
    wire [2:0] funct3;
    assign funct3 = pcpi_insn[14:12];
    wire [4:0] address;
    assign address = pcpi_insn[11:7];
    wire signed [15:0] value;
    assign value = pcpi_insn[30:15];

    reg signed [15:0] A [0:2][0:2];
    reg signed [15:0] B [0:2][0:2];
    // (*DONT_TOUCH="yes"*) 
    reg C [0:2][0:2];
    reg signed [15:0] bias [0:2][0:2];
    

    // Wires between PEs
    wire signed [15:0] a_wire [0:2][0:3];  // a_out to right
    wire signed [15:0] b_wire [0:3][0:2];  // b_out down
    wire signed [31:0] c_wire [0:2][0:2];  // result matrix

    reg [2:0] cycle_count;
    reg result_latched;

    reg [31:0] result;
    reg        ready;
    reg start;
    
    integer i,j;
    integer signed threshold;
    integer count;
    reg resetdd;
    
    always @(posedge clk) 
    begin
        if(!resetn) 
        begin
            cycle_count <= 3'd0;
            result_latched <= 0;
            threshold <= -70;
            count <= 0;
            resetdd <= 0;
        end 
        else if(start)
        begin
            if(cycle_count < 7)
                cycle_count <= cycle_count + 1;
            
            if(count < 9) count <= count + 1;
            
        //     if (cycle_count == 7 && !result_latched) begin
        //         result_latched <= 1;
        //         resetdd <= 0;
        //         for (i = 0; i < 3; i = i + 1)
        //             for (j = 0; j < 3; j = j + 1)
        //                 C[i][j] <= c_wire[i][j] >= threshold;
        //     end
        // end
        else if(!resetdd)
        begin
            resetdd <= 1;
            cycle_count <= 0;
            count <= 0;
            result_latched <= 0;
        end
    end

    always @(posedge clk) 
        begin
        if (!resetn) begin
            ready <= 1;
            start <= 0;
            result <= 0;
        end 
        // else begin

        //     if (pcpi_valid && opcode == 7'b0001011) begin
        //         case (funct3)
        //             3'b000: begin
        //                 if(address < 9)
        //                 begin
        //                     A[address / 3][address % 3] <= value;
        //                 end
        //                 else if(address < 18)
        //                 begin
        //                     B[(address-9) / 3][address % 3] <= value;
        //                 end
        //                 else if(address < 27)
        //                 begin
        //                     bias[(address-18) / 3][address % 3] <= value;
        //                 end
        //                 else if(address == 27)
        //                 begin
        //                     threshold <= value;
        //                 end
        //                 ready <= 1;
        //                 result <= 0;
        //                 start <= 0;
        //             end
        //             3'b101: begin
        //                 start <= 0;
        //                 ready <= 1;
        //                 result <= 0;
        //             end
        //             3'b111: begin
        //                 start <= 1;
        //                 ready <= 0;
        //             end
        //         endcase
        //     end
        // end
    end

    assign pcpi_rd = result;
    assign pcpi_wr = ready;
    assign pcpi_ready = ready | (count == 8);
    assign pcpi_wait = start & (count < 8);
    
    generate
        genvar r;
        for (r = 0; r < 3; r = r + 1) begin : input_feeds
            assign a_wire[r][0] = ((cycle_count >= r) && (cycle_count - r < 3)) ? A[r][cycle_count - r] : 0;
            assign b_wire[0][r] = ((cycle_count >= r) && (cycle_count - r < 3)) ? B[cycle_count - r][r] : 0;
        end
    endgenerate
    
    // genvar i_g, j_g;
    // generate
    //     for (i_g = 0; i_g < 3; i_g = i_g + 1) begin : row
    //         for (j_g = 0; j_g < 3; j_g = j_g + 1) begin : col
    //             pe pe_inst(
    //                 .clk((clk & !resetn) | (clk & start)),
    //                 .rst(!resetn),
    //                 .a_in(a_wire[i_g][j_g]),
    //                 .b_in(b_wire[i_g][j_g]),
    //                 .c_in((cycle_count == 0) ? bias[i_g][j_g] : c_wire[i_g][j_g]),
    //                 .a_out(a_wire[i_g][j_g+1]),
    //                 .b_out(b_wire[i_g+1][j_g]),
    //                 .c_out(c_wire[i_g][j_g])
    //             );
    //         end
    //     end
    // endgenerate
    
endmodule
