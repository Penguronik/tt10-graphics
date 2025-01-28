/*
AUTHORS: Elias, Roni, Darius
DATE: 1/27/2025
# REG BITS: 26
*/

`default_nettype none
module graphics_top (clk, reset, o_hsync, o_vsync, o_display_on, o_hpos, o_vpos);
    output clk;
    output reset;
    output o_display_on;

    // Rendering 
    input i_color_obstacle;
    input i_color_player;
    input i_color_background;
    input i_color_score;
    output reg [8:0] o_hpos;
    output reg [8:0] o_vpos;

    // VGA out
    output reg o_vsync;
    output reg o_hsync;
    output reg [1:0] o_blue;
    output reg [1:0] o_red;
    output reg [1:0] o_green;

    // GAME LOGIC
    output reg o_game_tick;
    output reg o_game_tick_r;

    parameter V_DISPLAY       = 480; // vertical display height
    parameter H_DISPLAY       = 640; // horizontal display width

    // ============== HVSYNC =============
    // TODO can change hpos to increment by 2 to reduce bits
    reg [9:0] hpos;
    reg [9:0] vpos;
    reg display_on;
    // TODO can remove this pipeline stage if we don't need it
    reg hsync;
    reg vsync;
    reg hsync_r;
    reg vsync_r;
    // TODO might be able to set display_on to always be on / cordinated with
    // only vsync
    reg display_on_r;

    // TODO create custom hsync
    hvsync_generator hvsync_gen (.clk(clk), .reset(reset), .hsync(hsync), .vsync(vsync), 
                                    .vpos(vpos), .hpos(hpos), .display_on(display_on)); 

    always @(posedge clk or posedge reset) begin
        if (reset) begin
            hsync_r <= 1'b0;
            vsync_r <= 1'b0;
            display_on_r <= 1'b0;
        end else begin
            vsync_r <= vsync;
            hsync_r <= hsync;
            display_on_r <= display_on;
        end
    end
    always @(*) begin
       o_hsync = hsync_r;
       o_display_on = display_on_r;
       o_vsync = vsync_r;
    end

    // ============== COMPARE =============
    reg is_colored;
    always @(*) begin
        is_colored = i_color_obstacle ||
                     i_color_player ||
                     i_color_background ||
                     i_color_score;
    end
    
    // ============ CONVOLUTION ============
    reg is_colored_r;
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            is_colored_r <= 1'b0;
        end else begin
            if (hpos[0] == 0) begin
                is_colored_r <= is_colored;
            end else begin
                is_colored_r <= is_colored_r;
            end
        end
    end

    // ============ GENERATE RGB / TRANSFORM ============
    // TODO stage can be merged with "CONVOLUTION" stage
    always @(*) begin
        o_blue = 2'b00;
        o_red  = 2'b00;
        o_green = 2'b00;
        if (is_colored_r) begin
            o_blue = 2'b11;
            o_red = 2'b11;
            o_green = 2'b11;
        end 
    end

    // ============ GAME TICK ============
    reg game_tick_r;
    always @(*) begin
        o_game_tick = (vpos == V_DISPLAY && hpos == H_DISPLAY);
        o_game_tick_r = game_tick_r;
    end
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            game_tick_r <= 1'b0;
        end else begin
            if (o_game_tick) begin
                game_tick_r <= 1'b1;
            end else begin
                game_tick_r <= 1'b0;
            end

        end 
    end

endmodule
