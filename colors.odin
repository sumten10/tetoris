#+feature dynamic-literals
package TETORIS

import rl "vendor:raylib"

dark_grey : Color : {26,31,40,255}
green : Color : {47,230,23,255}
red : Color : {255,79,115,255}
orange : Color : {226,116,17,255}
yellow : Color : {255,217,82,255}
purple : Color : {166,0,247,255}
cyan : Color : {21,204,209,255}
blue : Color : {13,64,216,255}
dark_blue : Color : {44, 44, 127, 255}
ghost : Color : {210,20,20, 100}


get_cell_colors :: proc() -> [dynamic]Color
{
    return {dark_grey, green, red, orange, yellow, purple, cyan, blue}
    
}