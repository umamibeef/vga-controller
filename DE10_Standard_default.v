module text_vram(
    out_text_vmem_data,
    in_text_vmem_address,
    );


    //=======================================================
    // I/O
    //=======================================================
    output  [15:0] out_text_vmem_data;
    input  [12:0] in_text_vmem_address;


    //=======================================================
    // Reg/wire declarations
    //=======================================================
    
    // Text VRAM is 2^13 16-bit words
    reg     [15:0] text_vram [0:8191];

    initial
    begin
        $readmemb("text_vram.mem", text_vram);
    end

    //=======================================================
    // Structural coding
    //=======================================================
    
    assign out_text_vmem_data = text_vram[in_text_vmem_address];

endmodule

module reset_delay(in_clock,out_reset);
input       in_clock;
output reg  out_reset;
reg [19:0]  Cont;

always@(posedge in_clock)
begin
    if(Cont!=20'hFFFFF)
    begin
        Cont    <=  Cont+1;
        out_reset  <=  1'b0;
    end
    else
    out_reset  <=  1'b1;
end

endmodule

module DE10_Standard_default(

    //////////// CLOCK //////////
    input                       CLOCK2_50,
    input                       CLOCK3_50,
    input                       CLOCK4_50,
    input                       CLOCK_50,

    //////////// KEY //////////
    input            [3:0]      KEY,

    //////////// SW //////////
    input            [9:0]      SW,

    //////////// LED //////////
    output           [9:0]      LEDR,

    //////////// Seg7 //////////
    output           [6:0]      HEX0,
    output           [6:0]      HEX1,
    output           [6:0]      HEX2,
    output           [6:0]      HEX3,
    output           [6:0]      HEX4,
    output           [6:0]      HEX5,

    //////////// SDRAM //////////
    output          [12:0]      DRAM_ADDR,
    output           [1:0]      DRAM_BA,
    output                      DRAM_CAS_N,
    output                      DRAM_CKE,
    output                      DRAM_CLK,
    output                      DRAM_CS_N,
    inout           [15:0]      DRAM_DQ,
    output                      DRAM_LDQM,
    output                      DRAM_RAS_N,
    output                      DRAM_UDQM,
    output                      DRAM_WE_N,

    //////////// Video-In //////////
    input                       TD_CLK27,
    input            [7:0]      TD_DATA,
    input                       TD_HS,
    output                      TD_RESET_N,
    input                       TD_VS,

    //////////// VGA //////////
    output                      VGA_BLANK_N,
    output           [7:0]      VGA_B,
    output                      VGA_CLK,
    output           [7:0]      VGA_G,
    output                      VGA_HS,
    output           [7:0]      VGA_R,
    output                      VGA_SYNC_N,
    output                      VGA_VS,

    //////////// Audio //////////
    input                       AUD_ADCDAT,
    inout                       AUD_ADCLRCK,
    inout                       AUD_BCLK,
    output                      AUD_DACDAT,
    inout                       AUD_DACLRCK,
    output                      AUD_XCK,

    //////////// PS2 //////////
    inout                       PS2_CLK,
    inout                       PS2_CLK2,
    inout                       PS2_DAT,
    inout                       PS2_DAT2,

    //////////// ADC //////////
    output                      ADC_CONVST,
    output                      ADC_DIN,
    input                       ADC_DOUT,
    output                      ADC_SCLK,

    //////////// I2C for Audio and Video-In //////////
    output                      FPGA_I2C_SCLK,
    inout                       FPGA_I2C_SDAT,

    //////////// IR //////////
    input                       IRDA_RXD,
    output                      IRDA_TXD,

    //////////// GPIO, GPIO connect to GPIO Default //////////
    input           [35:0]      GPIO
    );

    //=======================================================
    //  REG/WIRE declarations
    //=======================================================

    //  For VGA Controller
    wire    [12:0] text_vram_address;
    reg     [12:0] offset_text_vram_address;
    wire    [15:0] text_vram_data;
    wire    delayed_reset;

    //=======================================================
    //  Structural coding
    //=======================================================

    // Generate a 25 MHz clock for VGA and assign 50 MHz source to wire
    reg [31:0] clock_div_count;
    reg [31:0] offset_count;
    reg vga_clock_25;
    wire vga_clock_50;

    assign vga_clock_50 = CLOCK_50;
    always @ (posedge CLOCK_50)
    begin
        if (!delayed_reset)
             offset_count <= 0;
        else
             offset_count <= offset_count + 1;

        {vga_clock_25, clock_div_count} <= clock_div_count + 32'h80000000;  // divide by 2: (2^32)/2 = 0x80000000
        
        offset_text_vram_address <= text_vram_address ^ SW;
    end

    // Reset Delay Timer
    reset_delay r0(
        .in_clock(CLOCK_50),
        .out_reset(delayed_reset),
        );

    // Text VRAM
    text_vram m0(
        .out_text_vmem_data(text_vram_data),
        .in_text_vmem_address(offset_text_vram_address),
        );

    assign VGA_CLK = vga_clock_50;
    vga_controller vga_ins(
        .in_reset_n(delayed_reset),
        .in_vga_clock(vga_clock_50),
        .in_text_vmem_data(text_vram_data),
        .out_blank_n(VGA_BLANK_N),
        .out_h_sync(VGA_HS),
        .out_v_sync(VGA_VS),
        .out_b_data(VGA_B),
        .out_g_data(VGA_G),
        .out_r_data(VGA_R),
        .out_text_vmem_address(text_vram_address),
        );

endmodule
