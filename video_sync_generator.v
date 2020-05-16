/* 
 * 
 * VGA signal generator, derived from DE-10 example project
 * 
 */

module video_sync_generator(
    in_reset,
    in_vga_clk,
    out_pixel_x,
    out_pixel_y,
    out_blank_n,
    out_h_sync,
    out_v_sync
    );
                            
    input in_reset;
    input in_vga_clk;
    output reg [9:0] out_pixel_x;
    output reg [9:0] out_pixel_y;
    output reg out_blank_n;
    output reg out_h_sync;
    output reg out_v_sync;

    /*
        VGA Timing
        Horizontal:
                        ______________                 _____________
                       |              |               |
        _______________|  VIDEO       |_______________|  VIDEO (next line)

        ___________   _____________________   ______________________
                   |_|                     |_|
                    B <-C-><----D----><-E-> B <-C->
                   <------------A---------><-------
        The Unit used below are pixels;  
          B->sync_cycle                   :h_sync_cycles
          C->back_porch                   :h_back_porch
          D->visible area
          E->front porch                  :h_front_porch
          A->horizontal line total length :h_max_cycles

        Vertical:
                       ______________                 _____________
                      |              |               |          
        ______________|  VIDEO       |_______________|  VIDEO (next frame)
        
        __________   _____________________   ______________________
                  |_|                     |_|
                   P <-Q-><----R----><-S-> P <-Q->
                  <-----------O----------><-------
        The Unit used below are horizontal lines;  
          P->sync_cycle                   :v_sync_cycles
          Q->back_porch                   :v_back_porch
          R->visible area
          S->front porch                  :v_front_porch
          O->vertical line total length   :v_max_cycles
    */

    // Parameters for 640x480 60Hz @ 25 MHz pixel clock
    // Horizontal
    parameter h_active_cycles = 640;
    parameter h_front_porch =   16;
    parameter h_sync_cycles =   96;
    parameter h_back_porch  =   48;
    parameter h_max_cycles =    h_active_cycles + h_front_porch + h_sync_cycles + h_back_porch;
    // Verical
    parameter v_active_cycles = 480;
    parameter v_front_porch =   10;
    parameter v_sync_cycles =   2;
    parameter v_back_porch =    33;
    parameter v_max_cycles =    v_active_cycles + v_front_porch + v_sync_cycles + v_back_porch;

    /*
    // This doesn't really work well - probably a weird format.
    // Parameters for 800x600 72 Hz @ 50 MHz pixel clock
    // Horizontal
    parameter h_max_cycles =    1040;
    parameter h_active_cycles = 800;
    parameter h_front_porch =   56;
    parameter h_sync_cycles =   120;
    parameter h_back_porch  =   64;
    // Verical
    parameter v_max_cycles =    666;
    parameter v_active_cycles = 600;
    parameter v_front_porch =   37;
    parameter v_sync_cycles =   6;
    parameter v_back_porch =    23;
    */

    reg     [10:0] h_count;
    reg     [9:0] v_count;
    wire    [9:0] pixel_x;
    wire    [9:0] pixel_y;
    wire    h_sync, v_sync, blank_n, h_valid, v_valid;

    // h and v counter
    always @ (negedge in_vga_clk, posedge in_reset)
    begin
        if (in_reset)
        begin
            h_count <= 11'd0;
            v_count <= 10'd0;
        end
        else
        begin
            if (h_count == h_max_cycles - 1)
            begin
                h_count <= 11'd0;
                if (v_count == v_max_cycles - 1)
                    v_count <= 10'd0;
                else
                    v_count <= v_count + 1;
            end
            else
                h_count <= h_count + 1;
        end
    end

    // X & Y pixel coordinates
    assign pixel_x = (h_count < h_active_cycles) ? h_count : 10'b0;
    assign pixel_y = (v_count < v_active_cycles) ? v_count : 10'b0;
    // H & V sync
    assign h_sync = (h_count >= (h_active_cycles + h_front_porch)) && (h_count < (h_active_cycles + h_front_porch + h_sync_cycles)) ? 1'b0 : 1'b1;
    assign v_sync = (v_count >= (v_active_cycles + v_front_porch)) && (v_count < (v_active_cycles + v_front_porch + v_sync_cycles)) ? 1'b0 : 1'b1;
    // Blank generation
    assign h_valid = (h_count < h_active_cycles) ? 1'b1 : 1'b0;
    assign v_valid = (v_count < v_active_cycles) ? 1'b1 : 1'b0;
    assign blank_n = h_valid && v_valid;

    always @ (negedge in_vga_clk)
    begin
        out_h_sync <= h_sync;
        out_v_sync <= v_sync;
        out_pixel_x <= pixel_x;
        out_pixel_y <= pixel_y;
        out_blank_n <= blank_n;
    end

endmodule


