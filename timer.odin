#+feature dynamic-literals
package TETORIS
import rl "vendor:raylib"


Timer :: struct
{
    start_time,
    lifetime: f64,
}

start_timer :: proc(t: ^Timer, life: f64)
{
    t.start_time = rl.GetTime()
    t.lifetime = life
}

timer_done :: proc(t: ^Timer) -> bool
{
    return rl.GetTime() - t.start_time >= t.lifetime
}

get_elapsed :: proc(t: ^Timer) -> f64
{
    return rl.GetTime() - t.start_time
}

