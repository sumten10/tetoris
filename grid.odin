#+feature dynamic-literals
package TETORIS
import "core:mem"
import "core:fmt"
import "core:strings"
import "core:strconv"
import "core:math"
import "core:math/rand"
import rl "vendor:raylib"

Color :: rl.Color
vec2f :: [2]f32


BLOCK_ROUNDNESS : f32 : 0.1

Grid :: struct
{
    n_rows,
    n_cols,
    cell_size: i32,
    position: vec2f,
    grid: [20][10]u8,
    glowing_cells: [20][10]f32,
    colors: [dynamic]Color,
}

init_grid :: proc(using g: ^Grid) 
{
    n_rows = 20; n_cols = 10;
    cell_size = 30

    mem.set(&grid, 0, len(grid))

    g.colors = get_cell_colors()

}

draw_grid :: proc()
{
    using State.grid
    rl.DrawRectangleRec({position.y, position.x, f32(cell_size*n_cols)+1, f32(f32(cell_size*n_rows))}, {50,20,20,255})

    for row in 0..<n_rows
    {
        for col in 0..<n_cols
        {
            cell_value := grid[row][col]
            
            if cell_value == 0
            {
                rl.DrawRectangle(i32(position.y) + col * cell_size+1, i32(position.x) + row * cell_size+1, cell_size-1, cell_size-1, colors[cell_value])
            }
            else
            {
                rl.DrawRectangleRounded({position.y + f32(col * cell_size+1), position.x + f32(row*cell_size+1), f32(cell_size-1), f32(cell_size-1)}, BLOCK_ROUNDNESS, 1, colors[cell_value])
            }

            if glowing_cells[row][col] > 0
            {
            rl.DrawRectangle(i32(position.y) + col * cell_size, i32(position.x) + row * cell_size, cell_size, cell_size, rl.ColorAlpha(rl.WHITE, glowing_cells[row][col]))
            glowing_cells[row][col]-=0.1
            }
        }
    }


}

draw_ui :: proc()
{
    using State;
    rect : rl.Rectangle = {grid.position.y + f32(10 * grid.cell_size) + 30,50, (30 * 4) + 25, (30 * 4) + 40}

    //next tetromino

    rl.DrawLineV({rect.x, rect.y - 8}, {rect.x + rect.width, rect.y - 8}, rl.BLACK)
    rl.DrawLineV({rect.x, rect.y - 16}, {rect.x + rect.width, rect.y - 16}, rl.BLACK)

    rl.DrawRectangle(i32(rect.x) - 29, i32(rect.y) + 20, 300, 30*4, {255,255,255,255})
    rl.DrawRectangleLinesEx({rect.x-1, rect.y-1, rect.width+2, rect.height+2}, 1.2, {70,10,10,255})
    rl.DrawRectangleRec(rect, {250,250,250, 255})
    text := rl.TextFormat("%02i", State.score)
    lvl_text := rl.TextFormat("LEVEL: %02i", State.current_level)
    //---

    //score
    rl.DrawRectangle(i32(rect.x-4), i32(rect.y + rect.height + 10-2), 150+5, 15+4+8, {0,0,0,255})

    rl.DrawRectangle(i32(rect.x-2), i32(rect.y + rect.height + 10), 150, 15+4, {240,240,240,255})

    rl.DrawText(text, i32(rect.x + 1), i32(rect.y+rect.height+10), 20, rl.BLACK)
    //---

    //level
    rl.DrawRectangle(i32(rect.x-4), i32(450-2), 150+5, 15+4+8, {0,0,0,255})
    rl.DrawRectangle(i32(rect.x-2), i32(450), 150, 15+4, {240,240,240,255})
    rl.DrawText(lvl_text, i32(rect.x + 1), i32(450), 20, rl.BLACK)
    //---



    pos : vec2f
    switch State.next_block.id
    {
        case 4:
            pos = {rect.y + (30 *2) - 15, rect.x + 30 + 15}
        case 3:
            pos = {rect.y + 30, rect.x + (25 / 2)}
        case 1:
            fallthrough
        case 2:
            pos = {rect.y + 30 + 15, rect.x + 27}
        case 6:
            pos = {rect.y + (30*2) - 15, rect.x + 30}
        case 7:
            fallthrough
        case 5:
            pos = {rect.y + 30 + 15, rect.x + 27}
        case:
            pos = {rect.y, rect.x}
    }
    @(static) bar_height : f32
    draw_tetro_at(&State.next_block, pos, 30)
    rl.DrawLineEx({25, f32(rl.GetScreenHeight() - 30)}, {25, f32(rl.GetScreenHeight() - 30) - bar_height}, 20.0, {235,235,235, 255})


    bar_height = math.lerp(bar_height, State.left_bar_height, f32(0.3))

    if State.game_over == true
    {
        
        game_over_screen_alpha = math.lerp(game_over_screen_alpha, f32(1.0), f32(0.1));
        rl.BeginBlendMode(.SUBTRACT_COLORS)
        rl.DrawRectangle(0,0,rl.GetScreenWidth(), i32(f32(rl.GetScreenHeight()) * game_over_screen_alpha), rl.ColorAlpha({255,0,255,255}, game_over_screen_alpha))
        rl.EndBlendMode()
        rl.DrawRectangle(0,0,rl.GetScreenWidth(), rl.GetScreenHeight(), rl.ColorAlpha({0,0,0,100}, game_over_screen_alpha - 0.5))
        rl.DrawRectangleRounded({50,50,f32(rl.GetScreenWidth() - 100), f32(rl.GetScreenHeight()-100)}, 0.1, 1, {0,0,0,210})

        measure := rl.MeasureText("GAME OVER", 40)
        rl.DrawText("GAME OVER", (rl.GetScreenWidth() / 2) - measure / 2, rl.GetScreenHeight() / 3 - 20, 40, rl.WHITE)

        button({100,100,70,20}, {255,255,255,100})
        
    }
    else if State.pause
    {
        game_over_screen_alpha = math.lerp(game_over_screen_alpha, f32(1.0), f32(0.1));

        rl.BeginBlendMode(.SUBTRACT_COLORS)
        rl.DrawRectangle(0,0,rl.GetScreenWidth(), i32(f32(rl.GetScreenHeight()) * game_over_screen_alpha), rl.ColorAlpha({255,0,255,255}, game_over_screen_alpha))
        rl.EndBlendMode()
        rl.DrawRectangle(0,0,rl.GetScreenWidth(), rl.GetScreenHeight(), rl.ColorAlpha({0,0,0,100}, game_over_screen_alpha - 0.5))

        
        slider_pos: vec2f = {f32(rl.GetScreenWidth() - 35), f32(rl.GetScreenHeight() - 35)}

        //volume slider

        {
            @(static) volume: bool
            if rl.CheckCollisionPointCircle(rl.GetMousePosition(), {slider_pos.x, slider_pos.y - (300) * State.master_volume}, 17.0) && rl.IsMouseButtonPressed(.LEFT)
            {
                volume = true
            }

            if volume == true
            {
                
                State.master_volume -= (rl.GetMouseDelta().y * 0.003)
                State.master_volume = clamp(State.master_volume, 0.0, 1.0)
                rl.SetMasterVolume(State.master_volume)

                if rl.IsMouseButtonReleased(.LEFT) do volume = false
            }

            rl.DrawLineEx(slider_pos, {slider_pos.x, slider_pos.y - (300 * State.master_volume)}, 5.0, rl.WHITE)        
            rl.DrawCircleV({slider_pos.x, slider_pos.y - (300 * State.master_volume)}, 10.0, rl.WHITE)
            rl.DrawCircleV({slider_pos.x, slider_pos.y - (300 * State.master_volume)}, 5.0, rl.BLACK)
       
        }

       
        @(static) random_pos: vec2f;

        if !event_triggered(0.4)
        {
            rl.DrawText("PAUSE", 10,10, 40, rl.ColorAlpha(rl.WHITE, game_over_screen_alpha));
            
        }
        else
        {
            random_pos = {rand.float32_range(0.0, 500), rand.float32_range(0.0, 600)}
        }
            rl.DrawText("PAUSE", i32(random_pos.x), i32(random_pos.y), 20, {255,255,255,100})

        
    }
    else
    {
        game_over_screen_alpha = 0.0;
    }
    
}

is_cell_empty :: proc(cell: vec2) -> bool
{
    using State
    if cell.x < 0 || cell.x >= grid.n_rows || cell.y < 0 || cell.y >= grid.n_cols do return false;
    if grid.grid[cell.x][cell.y] == 0 do return true;

    return false;
}

is_cell_out :: proc(cell: vec2) -> (bool, vec2)
{
    normal: vec2 = {0,0}
    using State

    if (cell.x >= 0 && cell.x < grid.n_rows && cell.y >= 0 && cell.y < grid.n_cols)
    {
        return false, {0,0}
    }
    if cell.y >= grid.n_cols do normal = {0,-1}
    if cell.x < 0         do normal = {1,0}
    if cell.y < 0         do normal = {0,1}
    if cell.x >= grid.n_rows do normal = {-1,0}

    return true, normal
}