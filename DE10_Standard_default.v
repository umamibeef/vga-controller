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
    wire    VGA_CTRL_CLK;
    wire    [12:0] TEXT_VRAM_ADDRESS;
    wire    [15:0] TEXT_VRAM_DATA;

    wire    DLY_RST;

    //=======================================================
    //  Structural coding
    //=======================================================

    // initial //  
    // Generate a 25 MHz pixel clock for VGA
    reg [15:0] count;
    reg vga_clock;
    always @ (posedge CLOCK_50)
        {vga_clock, count} <= count + 16'h8000;  // divide by 2: (2^16)/2 = 0x8000

    // Reset Delay Timer
    Reset_Delay r0  (
        .iCLK(CLOCK_50),
        .oRESET(DLY_RST)
        );

    text_vram m0(
        .out_text_vmem_data(TEXT_VRAM_DATA),
        .in_text_vmem_address(TEXT_VRAM_ADDRESS),
        );

    assign VGA_CLK = vga_clock;
    // assign VGA_CLK = CLOCK_50;
    vga_controller vga_ins(
        .in_reset_n(DLY_RST),
        .in_vga_clock(vga_clock),
        // .in_vga_clock(CLOCK_50),
        .in_text_vmem_data(TEXT_VRAM_DATA),
        .out_blank_n(VGA_BLANK_N),
        .out_h_sync(VGA_HS),
        .out_v_sync(VGA_VS),
        .out_b_data(VGA_B),
        .out_g_data(VGA_G),
        .out_r_data(VGA_R),
        .out_text_vmem_address(TEXT_VRAM_ADDRESS),
        );

endmodule
