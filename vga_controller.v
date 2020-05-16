/* 
 * 
 * VGA controller module, from DE-10 example project
 * 
 */

// VGA 4-bit palette to 24-bit DAC {R,G,B}
`define VGA_BLACK       24'h000000
`define VGA_BLUE        24'h0000AA
`define VGA_GREEN       24'h00AA00
`define VGA_CYAN        24'hAAAA00
`define VGA_RED         24'hAA0000
`define VGA_MAGENTA     24'hAA00AA
`define VGA_BROWN       24'hAA5500
`define VGA_WHITE       24'hAAAAAA
`define VGA_GRAY        24'h555555
`define VGA_LT_BLUE     24'h5555FF
`define VGA_LT_GREEN    24'h55FF55
`define VGA_LT_CYAN     24'h55FFFF
`define VGA_LT_RED      24'hFF5555
`define VGA_LT_MAGENTA  24'hFF55FF
`define VGA_YELLOW      24'hFFFF55
`define VGA_BT_WHITE    24'hFFFFFF

module font_rom(
    in_char,
    in_pixel_x,
    in_pixel_y,
    out_pixel,
    );

    //=======================================================
    // I/O
    //=======================================================
    input   [7:0] in_char;
    input   [2:0] in_pixel_x;
    input   [3:0] in_pixel_y;
    output  out_pixel;

    //=======================================================
    // Reg/wire declarations
    //=======================================================
    
    // Font ROM is organized by rows of pixel data. Recall that characters are
    // 8x16 pixels in dimension. Since there are 256 total characters, then the
    // ROM will have (256 * 16) by 8 entries.
    reg     [7:0] font_rom [0:4095];
     
    initial
    begin
        $readmemb("font_rom.mem", font_rom);
    end


    //=======================================================
    // Structural coding
    //=======================================================
    
    assign out_pixel = font_rom[{in_char, in_pixel_y}][in_pixel_x];

endmodule



module vga_controller(
    in_reset_n,
    in_vga_clock,
    in_text_vmem_data,
    out_blank_n,
    out_h_sync,
    out_v_sync,
    out_b_data,
    out_g_data,
    out_r_data,
    out_text_vmem_address,
    );

    //=======================================================
    // I/O
    //=======================================================
    input   in_reset_n;
    input   in_vga_clock;
    input   [15:0] in_text_vmem_data;
    output  reg out_blank_n;
    output  reg out_h_sync;
    output  reg out_v_sync;
    output  [7:0] out_r_data;
    output  [7:0] out_g_data;
    output  [7:0] out_b_data;
    output  [12:0] out_text_vmem_address;

    //=======================================================
    // Reg/wire declarations
    //=======================================================
    wire    [9:0] pixel_y;
    wire    [9:0] pixel_x;
    wire    [6:0] text_vram_col;
    wire    [5:0] text_vram_row;
    wire    [12:0] text_vram_offset;
    wire    [4:0] vga_color;
    reg     [23:0] rgb_data;
    wire    vga_clock_n;
    wire    current_pixel;
    wire    [7:0] index;
    reg     [23:0] rgb_data_raw;
    wire    h_sync;
    wire    blank_n;
    wire    v_sync;
    wire    reset;
    wire    [3:0] text_vmem_data_foreground;
    wire    [3:0] text_vmem_data_background;

    //=======================================================
    // Structural coding
    //=======================================================
    
    // 640 x 480 in 8-bit color:
    // We need 307,200 pixels * 8 bits of memory for a full screen
    // 19 bits can address 2^19 = 524,288‬ total pixels which is > 307,200
    // 
    // 800 x 600 in 8-bit color:
    // We need 480,000 pixels * 8 bits of memory for a full screen
    // 19 bits can address 2^19 = 524,288 total pixels which is > 480,000

    // Internal reset signal
    assign reset = ~in_reset_n;

    // Instantiate the video sync generator
    // Will generate all of the requisite VGA signals (blank, h-sync, v-sync) from the VGA clock
    video_sync_generator video_sync_generator_instance (
        .in_vga_clk(in_vga_clock),
        .in_reset(reset),
        .out_pixel_x(pixel_x),
        .out_pixel_y(pixel_y),
        .out_blank_n(blank_n),
        .out_h_sync(h_sync),
        .out_v_sync(v_sync),
        );

    // Text VRAM address generator. Character size is 8x16, so lower 3 and 4
    // bits of pixel's x and y coordinates are for addressing the col/row of the
    // character ROM. This configuration supports 10-bits in either direction
    // which provides 1024x1024 of available screen real estate. The video sync
    // generator determines the resolution that will displayed from this
    // maximum.
    assign text_vram_col = pixel_x[9:3]; // 7 bits
    assign text_vram_row = pixel_y[9:4]; // 6 bits
    assign text_vram_offset = {text_vram_row, text_vram_col}; // 13 bits
    assign out_text_vmem_address = text_vram_offset;

    // Font ROM
    font_rom font_rom_instance (
        .in_char(in_text_vmem_data[7:0]),
        .in_pixel_x(pixel_x[2:0]),
        .in_pixel_y(pixel_y[3:0]),
        .out_pixel(current_pixel),
        );

    // VGA color LUT
    always @ (vga_color)
        begin
            case (vga_color)
                4'h0 : rgb_data_raw <= `VGA_BLACK;
                4'h1 : rgb_data_raw <= `VGA_BLUE;
                4'h2 : rgb_data_raw <= `VGA_GREEN;
                4'h3 : rgb_data_raw <= `VGA_CYAN;
                4'h4 : rgb_data_raw <= `VGA_RED;
                4'h5 : rgb_data_raw <= `VGA_MAGENTA;
                4'h6 : rgb_data_raw <= `VGA_BROWN;
                4'h7 : rgb_data_raw <= `VGA_WHITE;
                4'h8 : rgb_data_raw <= `VGA_GRAY;
                4'h9 : rgb_data_raw <= `VGA_LT_BLUE;
                4'hA : rgb_data_raw <= `VGA_LT_GREEN;
                4'hB : rgb_data_raw <= `VGA_LT_CYAN;
                4'hC : rgb_data_raw <= `VGA_LT_RED;
                4'hD : rgb_data_raw <= `VGA_LT_MAGENTA;
                4'hE : rgb_data_raw <= `VGA_YELLOW;
                4'hF : rgb_data_raw <= `VGA_BT_WHITE;
                default : rgb_data_raw <= `VGA_BLACK;
            endcase
        end

    // Assign background and foreground signals
    assign text_vmem_data_foreground = in_text_vmem_data[11:8];
    assign text_vmem_data_background = in_text_vmem_data[15:12];
    assign vga_color = (current_pixel == 1'b0) ? text_vmem_data_background : text_vmem_data_foreground;

    // Latch valid data at falling edge;
    assign vga_clock_n = ~in_vga_clock;
    always @ (posedge vga_clock_n)
        begin
            rgb_data <= rgb_data_raw;
        end
        assign out_r_data = rgb_data[23:16];
        assign out_g_data = rgb_data[15:8];
        assign out_b_data = rgb_data[7:0];

    // Delay the sync signals for one clock cycle;
    always @ (negedge in_vga_clock)
        begin
            out_h_sync <= h_sync;
            out_v_sync <= v_sync;
            out_blank_n <= blank_n;
        end

endmodule