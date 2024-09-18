package main

import "core:fmt"
import "core:math"
import "core:math/rand"
import rl "vendor:raylib"

WINDOW_WIDTH :: 1024
WINDOW_HEIGHT :: 768

Particle :: struct {
	size:      [2]f32,
	position:  [2]f32,
	color:     rl.Color,
	speed:     f32,
	state:     Particle_State,
	is_poison: bool,
}

Particle_State :: enum {
	Consumed,
	VeryClose,
	Nearby,
	Distant,
}

Particles :: #soa[50]Particle

new_particle :: proc(is_poison: bool) -> Particle {
	return {
		size = 15,
		position = particle_rand_position(15),
		color = is_poison ? rl.RED : rl.GREEN,
		speed = 150,
		is_poison = is_poison,
	}
}

particle_rand_position :: proc(size: f32) -> [2]f32 {
	return {
		rand.float32_range(0, WINDOW_WIDTH - 10),
		rand.float32_range(-WINDOW_HEIGHT, -(size * 2)),
	}
}

check_particle_state :: proc(p: Particle, ball: Ball) -> Particle_State {
	distance := rl.Vector2Distance(ball.position, p.position)

	if distance < p.size.y + ball.radius {
		return .Consumed
	}

	if distance < (p.size.y * 10) + ball.radius {
		return .VeryClose
	}

	if distance < (p.size.y * 15) + ball.radius {
		return .Nearby
	}

	return .Distant
}

Ball :: struct {
	position: [2]f32,
	color:    rl.Color,
	radius:   f32,
	speed:    f32,
}

move_ball :: proc(ball: ^Ball, delta_time: f32) {
	speed := (ball.speed - (ball.radius / 3)) * delta_time
	to_move := [2]f32{}

	if rl.IsKeyDown(.W) && ball.position.y > ball.radius {
		to_move.y = -1
	}

	if rl.IsKeyDown(.S) && ball.position.y < WINDOW_HEIGHT - ball.radius {
		to_move.y = 1
	}

	if rl.IsKeyDown(.A) && ball.position.x > ball.radius {
		to_move.x = -1
	}

	if rl.IsKeyDown(.D) && ball.position.x < WINDOW_WIDTH - ball.radius {
		to_move.x = 1
	}

	if to_move.x != 0 && to_move.y != 0 {
		to_move = rl.Vector2Normalize(to_move)
	}

	ball.position.x = clamp(ball.position.x + (to_move.x * speed), 0, WINDOW_WIDTH - ball.radius)
	ball.position.y = clamp(ball.position.y + (to_move.y * speed), 0, WINDOW_HEIGHT - ball.radius)
}

main :: proc() {
	particles := Particles{}

	for _, i in particles {
		particles[i] = new_particle(rand.int_max(3) == 0)
	}

	ball := Ball {
		position = {WINDOW_WIDTH / 2, WINDOW_HEIGHT - 10},
		color    = rl.GREEN,
		speed    = 150,
		radius   = 20,
	}

	rl.InitWindow(WINDOW_WIDTH, WINDOW_HEIGHT, "Laufen")
	defer rl.CloseWindow()

	fps := rl.GetMonitorRefreshRate(rl.GetCurrentMonitor())

	rl.SetTargetFPS(fps)
	rl.HideCursor()

	for !rl.WindowShouldClose() {
		delta_time := rl.GetFrameTime()
		move_ball(&ball, delta_time)

		rl.BeginDrawing()
		defer rl.EndDrawing()

		rl.ClearBackground(rl.BLACK)

		for &p in particles {
			speed := p.speed * delta_time

			p.position.y += speed
			p.state = check_particle_state(p, ball)
			p.color = p.is_poison ? rl.RED : rl.BLUE

			dx := math.sign(ball.position.x - p.position.x) * speed
			dy := math.sign(ball.position.y - p.position.y) * speed

			#partial switch p.state {
			case .Consumed:
				ball.radius += p.is_poison ? -ball.radius * 0.2 : ball.radius * 0.05
			case .VeryClose:
				p.position.x += dx / (p.is_poison ? 1 : 3)
				p.position.y += dy / (p.is_poison ? 4 : 5)

				p.color = p.is_poison ? rl.RED : rl.GREEN
			case .Nearby:
				p.position.x -= dx / (p.is_poison ? 5 : 3)
				p.position.y -= dy / (p.is_poison ? 8 : 6)
			}

			if p.position.y > WINDOW_HEIGHT + p.size.y || p.state == .Consumed {
				p.position = particle_rand_position(p.size.y)
				p.state = .Distant
			}

			if p.state == .VeryClose {
				rl.DrawLineV(p.position, ball.position, p.color)
			}

			rl.DrawRectangleV(p.position, p.size, p.color)
			rl.DrawCircleV(ball.position, ball.radius, ball.color)
		}

		rl.DrawFPS(10, 10)
	}
}
