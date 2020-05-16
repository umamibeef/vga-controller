/* 
 * 
 * VGA signal generator, from DE-10 example project
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
        Horizontal :
                        ______________                 _____________
                       |              |               |
        _______________|  VIDEO       |_______________|  VIDEO (next line)

        ___________   _____________________   ______________________
                   |_|                     |_|
                    B <-C-><----D----><-E->
                   <------------A--------->
        The Unit used below are pixels;  
          B->sync_cycle                   :hori_sync
          C->back_porch                   :hori_back
          D->visible area
          E->front porch                  :hori_front
          A->horizontal line total length :hori_line

        Vertical :
                       ______________                 _____________
                      |              |               |          
        ______________|  VIDEO       |_______________|  VIDEO (next frame)
        
        __________   _____________________   ______________________
                  |_|                     |_|
                   P <-Q-><----R----><-S->
                  <-----------O---------->
        The Unit used below are horizontal lines;  
          P->sync_cycle                   :vert_sync
          Q->back_porch                   :vert_back
          R->visible area
          S->front porch                  :vert_front
          O->vertical line total length   :vert_line
    */

    // Parameters
    parameter hori_line  = 800;
    parameter hori_sync  = 96;
    parameter hori_back  = 144;
    parameter hori_front = 16;
    parameter vert_line  = 525;
    parameter vert_back  = 34;
    parameter vert_front = 11;
    parameter vert_sync  = 2;

    reg     [10:0] h_count;
    reg     [9:0] v_count;
    wire    [9:0] pixel_x;
    wire    [9:0] pixel_y;
    wire    h_sync, v_sync, blank_n, hori_valid, vert_valid;

    always @ (negedge in_vga_clk, posedge in_reset)
        begin
            if (in_reset)
                begin
                    h_count <= 11'd0;
                    v_count <= 10'd0;
                end
            else
                begin
                    if (h_count == hori_line - 1)
                        begin
                            h_count <= 11'd0;
                            if (v_count == vert_line - 1)
                                v_count <= 10'd0;
                            else
                                v_count <= v_count + 1;
                        end
                    else
                        h_count <= h_count + 1;
                end
        end

    // X & Y pixel coordinates
    assign pixel_x = (h_count < hori_back) ? 0 : (h_count - hori_back);
    assign pixel_y = (v_count < vert_back) ? 0 : (v_count - vert_back);
    // H & V sync
    assign h_sync = (h_count < hori_sync) ? 1'b0 : 1'b1;
    assign v_sync = (v_count < vert_sync) ? 1'b0 : 1'b1;
    // active display
    assign hori_valid = (h_count < (hori_line - hori_front) && (h_count >= hori_back)) ? 1'b1 : 1'b0;
    assign vert_valid = (v_count < (vert_line - vert_front) && (v_count >= vert_back)) ? 1'b1 : 1'b0;
    assign blank_n = hori_valid && vert_valid;

    always @ (negedge in_vga_clk)
    begin
        out_h_sync <= h_sync;
        out_v_sync <= v_sync;
        out_pixel_x <= pixel_x;
        out_pixel_y <= pixel_y;
        out_blank_n <= blank_n;
    end

endmodule


