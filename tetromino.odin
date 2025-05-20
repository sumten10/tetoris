#+feature dynamic-literals
package TETORIS
import "core:fmt"
import rl "vendor:raylib"

import "core:math/rand"

vec2 :: [2]i32

Tetro_Type :: enum
{
    LBLOCK,
    JBLOCK,
    IBLOCK,
    OBLOCK,
    SBLOCK,
    TBLOCK,
    ZBLOCK
}

Direction :: enum
{
    UP,
    RIGHT,
    DOWN,
    LEFT
}


Tetro :: struct
{
    type: Tetro_Type,
    id: u8,
    cells : map[u8][dynamic]vec2,

    offset: vec2,

    cell_size: i32,
    rotation_state: u8,
    colors: [dynamic]Color,

}

center_tetro :: proc(t: ^Tetro) 
{
    #partial switch t.type
    {
        case .LBLOCK:
            tetro_move(t, {0,3})

        case .JBLOCK:
            tetro_move(t, {0,3})

        case .IBLOCK:
            tetro_move(t, {-1,3})

        case .OBLOCK:
            tetro_move(t, {0,4})

        case .SBLOCK:
            tetro_move(t, {0,3})

        case .TBLOCK:
            tetro_move(t, {0,3})

        case .ZBLOCK:
            tetro_move(t, {0,3})

    }
}

make_tetro :: proc(type: Tetro_Type) -> Tetro
{
    t := Tetro {
        offset = {0,0},
        cell_size = 30,
        rotation_state = 0,
        colors = get_cell_colors()
    }


    #partial switch type
    {
        case .LBLOCK:
            t.id = 1
            t.cells[0] = { {0,2}, {1,0}, {1,1}, {1,2} }
            t.cells[1] = { {0,1}, {1,1}, {2,1}, {2,2} }
            t.cells[2] = { {1,0}, {1,1}, {1,2}, {2,0} }
            t.cells[3] = { {0,0}, {0,1}, {1,1}, {2,1} }

        case .JBLOCK:
            t.id = 2
            t.cells[0] = { {0,0}, {1,0}, {1,1}, {1,2} }
            t.cells[1] = { {0,1}, {0,2}, {1,1}, {2,1} }
            t.cells[2] = { {1,0}, {1,1}, {1,2}, {2,2} }
            t.cells[3] = { {0,1}, {1,1}, {2,0}, {2,1} }


        case .IBLOCK:
            t.id = 3
            t.cells[0] = { {1,0}, {1,1}, {1,2}, {1,3} }
            t.cells[1] = { {0,2}, {1,2}, {2,2}, {3,2} }
            t.cells[2] = { {2,0}, {2,1}, {2,2}, {2,3} }
            t.cells[3] = { {0,1}, {1,1}, {2,1}, {3,1} }


        case .OBLOCK:
            t.id = 4
            t.cells[0] = { {0,0}, {0,1}, {1,0}, {1,1} }


        case .SBLOCK:
            t.id = 5
            t.cells[0] = { {0,1}, {0,2}, {1,0}, {1,1} }
            t.cells[1] = { {0,1}, {1,1}, {1,2}, {2,2} }
            t.cells[2] = { {1,1}, {1,2}, {2,0}, {2,1} }
            t.cells[3] = { {0,0}, {1,0}, {1,1}, {2,1} }


        case .TBLOCK:
            t.id = 6
            t.cells[0] = { {0,1}, {1,0}, {1,1}, {1,2} }
            t.cells[1] = { {0,1}, {1,1}, {1,2}, {2,1} }
            t.cells[2] = { {1,0}, {1,1}, {1,2}, {2,1} }
            t.cells[3] = { {0,1}, {1,0}, {1,1}, {2,1} }


        case .ZBLOCK:
            t.id = 7
            t.cells[0] = { {0,0}, {0,1}, {1,1}, {1,2} }
            t.cells[1] = { {0,2}, {1,1}, {1,2}, {2,1} }
            t.cells[2] = { {1,0}, {1,1}, {2,1}, {2,2} }
            t.cells[3] = { {0,1}, {1,0}, {1,1}, {2,0} }


    }

    t.type = type

    return t;
}

tetro_move :: proc(t: ^Tetro, v: vec2)
{
    t.offset += v;
}

tetro_get_cells :: proc(t: ^Tetro) -> [dynamic]vec2
{
    tiles : []vec2 =  t.cells[t.rotation_state][:]

    moved_tiles : [dynamic]vec2

    for item in tiles
    {
        new_pos := vec2{item.x + t.offset.x, item.y + t.offset.y}
        append(&moved_tiles, new_pos)
    }
    return moved_tiles
}

rotate_tetro :: proc(t: ^Tetro)
{
    t.rotation_state += 1
    

    if int(t.rotation_state) == 0
    {
        t.rotation_state = u8(len(t.cells))
    }
    else if int(t.rotation_state) == len(t.cells)
    {
        t.rotation_state = 0
    }

    out, normal := is_block_out(&State.current_block)
    if out
    {
       tetro_move(t, normal )
       if t.type == .IBLOCK do tetro_move(t, normal )

    }
    if !block_fits(t)
    {
        tetro_move(t, {-1, 0})
    }
    if !block_fits_under(t)
    {
        if last_move < 10 {last_update_time = rl.GetTime(); last_move+=1}
    }
}



tetro_draw :: proc(t: ^Tetro)
{
    tiles := tetro_get_cells(t)
    position := State.grid.position
    
    for item in tiles
    {
        col := t.colors[t.id]
        rl.DrawRectangleRounded({position.y + f32(item.y * t.cell_size + 1), position.x + f32(item.x * t.cell_size + 1), f32(t.cell_size) - 1, f32(t.cell_size) - 1}, BLOCK_ROUNDNESS, 1, col)
    }
}

draw_tetro_at :: proc(t: ^Tetro, pos: vec2f, size: i32)
{
    pos := pos
    tiles := tetro_get_cells(t)
    position := State.grid.position
    for item in tiles
    {
        rect : rl.Rectangle = {pos.y + f32(item.y * t.cell_size + 1), pos.x + f32(item.x * t.cell_size + 1), f32(t.cell_size) - 1, f32(t.cell_size) - 1} 
        rl.DrawRectangleRounded(rect, BLOCK_ROUNDNESS, 1, t.colors[t.id])
    }
}

draw_tetro_ghost :: proc(t: ^Tetro)
{
    tiles := tetro_get_cells(t)
    position := State.grid.position
    for item in tiles
    {
        col := t.colors[t.id]
        rl.DrawRectangleRoundedLines({position.y + f32(item.y) * f32(t.cell_size) + 1, position.x + f32(item.x) * f32(t.cell_size)+1, f32(t.cell_size)-1, f32(t.cell_size)-1}, 0.25, 3, col)
        rl.DrawRectangle(i32(position.y) + item.y * t.cell_size + 1,i32(position.x) + item.x * t.cell_size+1,t.cell_size-1,t.cell_size-1, {col.r, col.g, col.b, 10})
    }
}

