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

    //  For Audio CODEC
    wire    AUD_CTRL_CLK;    //  For Audio Controller

    //  For VGA Controller
    wire    VGA_CTRL_CLK;
    wire    [9:0] mVGA_R;
    wire    [9:0] mVGA_G;
    wire    [9:0] mVGA_B;
    wire    [19:0] mVGA_ADDR;
    wire    [12:0] TEXT_VRAM_ADDRESS;
    wire    [15:0] TEXT_VRAM_DATA;

    wire    mVGA_CLK;
    wire    [9:0] mRed;
    wire    [9:0] mGreen;
    wire    [9:0] mBlue;
    wire    VGA_Read;   //  VGA data request

    wire    [9:0] recon_VGA_R;
    wire    [9:0] recon_VGA_G;
    wire    [9:0] recon_VGA_B;

    wire    DLY_RST;
    reg     [31:0] Cont;
    wire    [23:0] mSEG7_DIG;

    wire    mDVAL;

    //audio count
    reg     [31:0] audio_count;
    reg     key1_reg;

    //=======================================================
    //  Structural coding
    //=======================================================

    // initial //  
                 
    assign DRAM_DQ          = 16'hzzzz;

    assign AUD_ADCLRCK      = 1'bz;                         
    assign AUD_DACLRCK      = 1'bz;                         
    assign AUD_DACDAT       = 1'bz;                         
    assign AUD_BCLK         = 1'bz;                          
    assign AUD_XCK          = 1'bz;                          
                            
    assign FPGA_I2C_SDAT    = 1'bz;                             
    assign FPGA_I2C_SCLK    = 1'bz; 


    assign GPIO_B           = 36'hzzzzzzzz;
    assign GPIO_A           = 36'hzzzzzzzz;

    assign AUD_XCK          = AUD_CTRL_CLK;
    assign AUD_ADCLRCK      =  AUD_DACLRCK;

    //  Enable TV Decoder
    assign  TD_RESET_N  =   KEY[0];


    always@(posedge CLOCK_50 or negedge KEY[0])
        begin
            if(!KEY[0])
                 Cont   <=  0;
            else
                 Cont   <=  Cont+1;
        end

    always@(posedge CLOCK_50)
        begin
                 key1_reg   <=  KEY[1];
            if(key1_reg & (!KEY[1]))
                audio_count = audio_count + 1;
        end  


    assign LEDR         = KEY[0] ? {Cont[25:24], Cont[25:24], Cont[25:24], Cont[25:24], Cont[25:24]} : 10'h3ff;
    assign mSEG7_DIG    = KEY[0] ? {Cont[27:24], Cont[27:24], Cont[27:24], Cont[27:24], Cont[27:24], Cont[27:24]} : {6{4'b1000}};

    // 7 segment LUT
    SEG7_LUT_6 u0  (
        .oSEG0(HEX0),
        .oSEG1(HEX1),
        .oSEG2(HEX2),
        .oSEG3(HEX3),
        .oSEG4(HEX4),
        .oSEG5(HEX5),
        .iDIG(mSEG7_DIG) );

    // Reset Delay Timer
    Reset_Delay r0  (
        .iCLK(CLOCK_50),
        .oRESET(DLY_RST)
        );

    // Audio and VGA PLL clock
    VGA_Audio u1(
        .refclk(CLOCK_50),          // refclk.clk
        .rst(~DLY_RST),             //  reset.reset
        .outclk_0(VGA_CTRL_CLK),    // outclk0.clk
        .outclk_1(AUD_CTRL_CLK),    // outclk1.clk
        .outclk_2(mVGA_CLK),        // outclk2.clk
        .locked()                   // locked.export
        );

    text_vram m0(
        .out_text_vmem_data(TEXT_VRAM_DATA),
        .in_text_vmem_address(TEXT_VRAM_ADDRESS),
        );

    assign VGA_CLK = VGA_CTRL_CLK;
    vga_controller vga_ins(
        .in_reset_n(DLY_RST),
        .in_vga_clock(VGA_CTRL_CLK),
        .in_text_vmem_data(TEXT_VRAM_DATA),
        .out_blank_n(VGA_BLANK_N),
        .out_h_sync(VGA_HS),
        .out_v_sync(VGA_VS),
        .out_b_data(VGA_B),
        .out_g_data(VGA_G),
        .out_r_data(VGA_R),
        .out_text_vmem_address(TEXT_VRAM_ADDRESS),
        );  
        
    AUDIO_DAC u2 (
        // Audio Side
        .oAUD_BCK(AUD_BCLK),
        .oAUD_DATA(AUD_DACDAT),
        .oAUD_LRCK(AUD_DACLRCK),
        // Control Signals
        .iSrc_Select(2'b0),
        .iCLK_18_4(AUD_CTRL_CLK),
        .iRST_N( DLY_RST &(!key1_reg))
        ); 
                                  
                                  
    I2C_AV_Config u3 (
        // Host Side
        .iCLK(CLOCK_50),
        .iRST_N(KEY[0]),
        // I2C Side
        .I2C_SCLK(FPGA_I2C_SCLK),
        .I2C_SDAT(FPGA_I2C_SDAT)
        );

endmodule
