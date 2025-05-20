#+feature dynamic-literals
package TETORIS
import "core:fmt"
import "core:math"
import "core:math/rand"
import rl "vendor:raylib"


Screen :: enum
{
    GAMEPLAY,
    START,
    EXIT,
}

State : struct
{
    last_music_playtime: f32,
    current_level: u8,
    total_lines_cleared: i32,
    level_diff: [16]f32,
    speed_interval: f32,
    pause: bool,
    chromatic_shader: rl.Shader,
    game_over_screen_alpha: f32,
    screen: Screen,
    game_over: bool,
    sounds: map[cstring]rl.Sound,
    background_music : rl.Music,
    music_volume: f32,
    master_volume: f32,
    grid: Grid,
    blocks: [dynamic]Tetro,
    current_block, next_block: Tetro,
    left_bar_height: f32,
    teto_spin: rl.Texture2D,
    game_counter: i32,
    score: i32,
    render_target: rl.RenderTexture2D,
}

load_sounds :: proc()
{
    State.sounds["lose"] = rl.LoadSound("sfx/lose.wav")
    State.sounds["move_block"] = rl.LoadSound("sfx/change.ogg")
    State.sounds["rotate_block"] = rl.LoadSoundAlias(State.sounds["move_block"])
    State.sounds["drop"] = rl.LoadSound("sfx/bump.ogg")

    State.background_music = rl.LoadMusicStream("sfx/tetoris_instrumental.ogg")
    rl.SetMusicVolume(State.background_music, 0.4)

    rl.SetSoundPitch(State.sounds["rotate_block"], 0.8)
    rl.SetSoundPitch(State.sounds["drop"], 1.1)
    rl.SetSoundVolume(State.sounds["drop"], 0.5)
}


init_difficulties :: proc()
{
    for l in 0..<6
    {
        State.level_diff[l] = f32(53.0 - (5.0 * l)) / 60.0
    }
    State.level_diff[6] = 23.0 / 60.0
    State.level_diff[7] = 18.0 / 60.0
    State.level_diff[8] = 13.0 / 60.0
    State.level_diff[9] = 8.0 / 60.0
    State.level_diff[10] = 6.0 / 60.0
    State.level_diff[11] = 6.0 / 60.0
    State.level_diff[12] = 6.0 / 60.0
    State.level_diff[13] = 5.0 / 60.0
    State.level_diff[14] = 5.0 / 60.0
    State.level_diff[15] = 5.0 / 60.0


    State.current_level = 0
}

init_game :: proc()
{
    init_grid(&State.grid)
    State.grid.position = {0,50}

    init_difficulties()

    State.blocks = get_all_blocks()
    State.current_block = get_random_tetro()
    center_tetro(&State.current_block)
    State.next_block = get_random_tetro()

    State.master_volume = 1.0;

    load_sounds()
    teto_img := rl.LoadImage("images/teto_spin.png")
    State.teto_spin = rl.LoadTextureFromImage(teto_img)
    rl.GenTextureMipmaps(&State.teto_spin)
    rl.SetTextureFilter(State.teto_spin, .TRILINEAR)

    rl.UnloadImage(teto_img)

    State.chromatic_shader = rl.LoadShader("shader/base.vs", "shader/chrome.fs")

    rl.BeginTextureMode(State.render_target)
    rl.ClearBackground(rl.BLACK)
    rl.EndTextureMode()


}


button :: proc(rect: rl.Rectangle, rect_color: Color) -> bool
{
    rl.DrawRectangleRec(rect, rect_color)
    if rl.IsMouseButtonPressed(.LEFT) && rl.CheckCollisionPointRec(rl.GetMousePosition(), rect)
    {
        return true
    }
    return false
}

draw_teto :: proc(pos: vec2f, scale: f32)
{
    @(static) frame_interval : f32
    @(static) current_frame : i32
    //rl.DrawTexturePro(State.teto_spin, {666 * f32(current_frame),850 * f32(current_frame),666 * f32(current_frame + 1) ,850 * f32(current_frame + 1)}, {pos.x + 4,pos.y + 4, (666) * scale, (850) * scale}, {0,0}, 0, rl.BLACK)
    rl.DrawTexturePro(State.teto_spin, {666 * f32(current_frame),0,666 ,850}, {pos.x,pos.y, 666 * scale, 850 * scale}, {-5,-1}, 0, {0,0,0,150})
    rl.DrawTexturePro(State.teto_spin, {666 * f32(current_frame),0,666 ,850}, {pos.x,pos.y, 666 * scale, 850 * scale}, {0,0}, 0, rl.WHITE)
    if current_frame >= 8
    {
        current_frame = 0
    }

    if f32(rl.GetTime()) - frame_interval >= 0.055
    {
        frame_interval = f32(rl.GetTime())
        current_frame += 1
    }
}

block_fits :: proc(t: ^Tetro) -> bool
{
    using State
    tiles := tetro_get_cells(t)
    
    for item in tiles
    {
        
        if is_cell_empty({item.x, item.y}) == false
        {
            return false
        }
    }
    return true;
}
block_fits_under :: proc(t: ^Tetro) -> bool
{
    tiles := tetro_get_cells(t)
    for item in tiles
    {
        if item.x >= State.grid.n_rows do return false;
        if is_cell_empty({item.x+1, item.y}) == false
        {
            
            return false
        }
    }
    return true;
}



is_block_out :: proc(t: ^Tetro) -> (bool, vec2)
{
    tiles : []vec2 = tetro_get_cells(t)[:]
    for item in tiles
    {
        out, dir := is_cell_out({item.x, item.y})
        if out 
        {return true, dir}
    }
    return false, {0,0};
}

lock_block :: proc()
{
    using State
    tiles := tetro_get_cells(&State.current_block)
    for item in tiles
    {
        if item.x <= 0 || item.x > grid.n_rows || item.y < 0 || item.y > grid.n_cols {State.game_over = true; rl.PlaySound(State.sounds["lose"]); return};
        grid.grid[item.x][item.y] = State.current_block.id
        grid.glowing_cells[item.x][item.y] = 1.0

    }
    blink_alpha = 1.0


    rl.PlaySound(State.sounds["drop"])
    current_block = next_block
    center_tetro(&State.current_block)

    last_move = 0

}

is_row_full :: proc(row: i32) -> bool
{
    using State
    for c in 0..<grid.n_cols
    {
        if grid.grid[row][c] == 0 do return false
    }
    return true
}

clear_row :: proc(row: i32)
{
    using State
    glow : f32 = 2.2
    for c in 0..<grid.n_cols
    {
        grid.grid[row][c] = 0
        grid.glowing_cells[row][c] = glow
        glow -= 0.3
        
    }
}

move_row_down :: proc(row, num_rows: i32)
{
    using State
    for col in 0..<grid.n_cols
    {
        grid.grid[row + num_rows][col] = grid.grid[row][col]
        grid.grid[row][col] = 0
    }
}

clear_full_rows :: proc() -> i32
{
    completed: i32 = 0

    for row : i32 = State.grid.n_rows-1; row >= 0; row-=1
    {
        if is_row_full(row)
        {
            clear_row(row)
            completed+=1
        }
        else if completed > 0
        {
            move_row_down(row, completed)
        }
    }
    switch completed
    {
        case 1:
            State.score += 1
        case 2:
            State.score += 3
        case 3:
            State.score += 5
        case 4:
            State.score += 8
    }
    

    return completed
}



move_block :: proc(dir: Direction) -> bool
{
    dir_v : vec2

    #partial switch dir
    {
        case .DOWN:
            dir_v = {1, 0}
        case .LEFT:
            dir_v = {0, -1}
        case .RIGHT:
            dir_v = {0, 1}
    }

    tetro_move(&State.current_block, dir_v)

    if dir != .DOWN do rl.PlaySound(State.sounds["move_block"])
    

    out, out_dir := is_block_out(&State.current_block)

    if out || block_fits(&State.current_block) == false
    {
        tetro_move(&State.current_block, dir_v * -1)
        if dir == .DOWN
        {

            lock_block()

            State.next_block = get_random_tetro()
            State.total_lines_cleared += clear_full_rows()
            return true;

        }

    }
    return false

    
}



hard_drop :: proc() 
{
    glow : f32 = 0.05
    loop: for block_fits(&State.current_block)
    {
        cells := tetro_get_cells(&State.current_block)
        for i in cells
        {
            State.grid.glowing_cells[i.x][i.y] = glow
            glow+=0.009
        }
        if move_block(.DOWN)
        {
            break loop
        }

    }
}

ghost_tetro :: proc()
{
    t := State.current_block
    for block_fits(&t)
    {
        tetro_move(&t, {1,0})
        out , dir := is_block_out(&t)
        if out || block_fits(&t) == false
        {
            tetro_move(&t, {-1,0})
            break
        }
    }
    draw_tetro_ghost(&t)
}

blink_alpha: f32
draw_glowing_cell :: proc(cell: vec2)
{
    
    using State
    position := State.grid.position;
    rl.DrawRectangleRec({position.y + f32(cell.y * grid.cell_size), position.x + f32(cell.x * grid.cell_size), 30, 30}, rl.ColorAlpha(rl.WHITE, blink_alpha))
    //rl.DrawRectangleLinesEx({position.y + f32(cell.y * grid.cell_size), position.x + f32(cell.x * grid.cell_size), 30, 30}, 2.0, rl.ColorAlpha(rl.RED, blink_alpha))
    if blink_alpha > 0 do blink_alpha -= 0.01;
}


last_move: i32




handle_input :: proc()
{





    key := rl.GetKeyPressed()


    if State.screen == .START
    {
        #partial switch key
        {
            case .ENTER:
                State.screen = .GAMEPLAY
        }
        return
    }
    

    if !State.game_over && !State.pause
    {
        #partial switch key
        {
            case .W:
                if !block_fits_under(&State.current_block)
                {
                    if last_move < 10 {last_update_time = rl.GetTime(); last_move+=1}
                }
                rotate_tetro(&State.current_block)
                rl.PlaySound(State.sounds["rotate_block"])
            case .SPACE:
                hard_drop()
            case .A:
                fallthrough
            case .S:
                fallthrough
            case .D:
                last_update_time_input = rl.GetTime() - 5
            
        }
    
        if event_triggered_input(0.1)
        {
            switch true
            {
    
                case (rl.IsKeyDown(.A)):
                    if !block_fits_under(&State.current_block)
                    {
                        if last_move < 10 {last_update_time = rl.GetTime(); last_move+=1}
                    }
                    move_block(.LEFT)
                case rl.IsKeyDown(.D):
                    if !block_fits_under(&State.current_block)
                    {
                        if last_move < 10 {last_update_time = rl.GetTime(); last_move+=1}
                    }
                    move_block(.RIGHT)
                case rl.IsKeyDown(.S):
                    if !block_fits_under(&State.current_block) do break
                    last_update_time = rl.GetTime()
                    move_block(.DOWN)
                    rl.PlaySound(State.sounds["move_block"])
            }
        
        }
    }


    










}



draw_start_screen :: proc()
{
    measure := rl.MeasureText("TETORIS", 60) / 2

    rl.DrawText("TET0RIS", (rl.GetScreenWidth() / 2) - (measure), 50, 60, {180,20,10, 230})
    rl.DrawText("TET0RIS", (rl.GetScreenWidth() / 2) - (measure), 55, 60, {180,20,10, 210})
    rl.DrawText("TET0RIS", (rl.GetScreenWidth() / 2) - (measure), 45, 60, rl.WHITE)
    rl.DrawText("0", (rl.GetScreenWidth() / 2) - 3, 45, 60, rl.BLACK)

    
    if !event_triggered(0.8)
    {
        measure2 := rl.MeasureText("PRESS ENTER", 20)
        rl.DrawText("PRESS ENTER", (rl.GetScreenWidth() / 2) - (measure2 / 2), 300, 20, rl.BLACK)
    }

}

draw_game :: proc()
{
    
    rl.BeginTextureMode(State.render_target)
    rl.ClearBackground(yellow)

    #partial switch State.screen
    {
        case .START:
        {
            draw_start_screen()
        }
        case .GAMEPLAY:
            draw_grid()
            tetro_draw(&State.current_block)
            y := tetro_get_cells(&State.current_block)
            ghost_tetro()
            draw_teto({380,250}, 0.2)
            draw_ui()
        
        
    }

    rl.EndTextureMode()

    rl.BeginShaderMode(State.chromatic_shader)
    rl.DrawTextureRec(State.render_target.texture, {0,0, f32(rl.GetScreenWidth()), f32(rl.GetScreenHeight()) * -1}, {0,0}, rl.WHITE)
    rl.EndShaderMode()

}

get_random_tetro :: proc() -> Tetro
{
    if len(State.blocks) < 1
    {
        State.blocks = get_all_blocks()
    }
    rand_idx := rand.int_max(len(State.blocks))
    tetro := State.blocks[rand_idx]
    tetro.rotation_state = 0


    ordered_remove(&State.blocks, rand_idx)
    
    return tetro
}

get_all_blocks :: proc() -> [dynamic]Tetro
{
    t := [dynamic]Tetro {
        make_tetro(.IBLOCK),
        make_tetro(.JBLOCK),
        make_tetro(.LBLOCK),
        make_tetro(.OBLOCK),
        make_tetro(.SBLOCK),
        make_tetro(.TBLOCK),
        make_tetro(.ZBLOCK)
    }
    return t
}

init_window :: proc()
{
    rl.SetConfigFlags({.MSAA_4X_HINT})
    rl.InitWindow(550,600, "TETORIS")
    rl.SetTargetFPS(60)
    rl.InitAudioDevice()
    State.render_target = rl.LoadRenderTexture(rl.GetScreenWidth(), rl.GetScreenHeight())
    rl.SetExitKey(.KEY_NULL)


    init_game()
    
}



shutdown :: proc() 
{
    free_all()
    rl.UnloadMusicStream(State.background_music)
    rl.CloseAudioDevice()
    rl.CloseWindow()
}


last_update_time : f64
event_triggered :: proc(interval: f64) -> bool
{
    current_time := rl.GetTime()
    if current_time - last_update_time >= interval
    {
        last_update_time = current_time
        return true;
    }

    return false;

}

 last_update_time_input : f64;

event_triggered_input :: proc(interval: f64) -> bool
{
    
    current_time := rl.GetTime()
    if current_time - last_update_time_input >= interval
    {
        last_update_time_input = current_time
        return true;
    }

    return false;

}


update_music :: proc()
{



    rl.UpdateMusicStream(State.background_music)
    rl.SetMusicVolume(State.background_music, State.music_volume)

    if State.game_over || State.pause == true
    {
        State.music_volume = math.lerp(State.music_volume, f32(0.0), f32(0.04))
        
    }
    else
    {
        State.music_volume = math.lerp(State.music_volume, f32(0.4), f32(0.04))
    }
}

update_counter :: proc()
{
    @(static) last_time : f64
    if rl.GetTime() - last_time >= 1.0
    {
        last_time = rl.GetTime()
        State.game_counter += 1
    }
    
}

gameplay_loop :: proc()
{
    

    if rl.IsKeyPressed(.ESCAPE)
    {
        
        State.pause = !State.pause
    }


    handle_input()

    #partial switch State.screen
    {
        case .GAMEPLAY:
            update_music()
            if event_triggered(f64(State.speed_interval)) && (!State.game_over && !State.pause)
            {
                //fmt.printfln("%i", i32(rl.GetTime()))
                move_block(.DOWN)
        
                State.left_bar_height = rand.float32_range(30, 500)
        
            }
        
            if State.total_lines_cleared >= 10
            {
                if State.current_level < 16 do State.current_level += 1
                State.total_lines_cleared-=10;        
            }
            State.speed_interval = State.level_diff[State.current_level]
    }

}

running := true

main :: proc()
{
    init_window()
    State.screen = .START

    State.speed_interval = State.level_diff[0]
    State.music_volume = 0.4
    rl.PlayMusicStream(State.background_music)

    main_loop: for !rl.WindowShouldClose() && running
    {
        rl.ClearBackground(yellow)


        gameplay_loop()

        rl.BeginDrawing()

        draw_game()

        rl.EndDrawing()
    }
    shutdown()


}