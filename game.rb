require 'gosu'
require 'defstruct'
require_relative 'vector'

GRAVITY = Vec[0, 600] # pixels/s^2
JUMP_VEL = Vec[0, -300] # pixel/s
OBSTACLE_SPEED = 200 # pixel/s
OBSTACLE_SPAWN_INTERVAL = 1.3 #seconds
OBSTACLE_GAP = 100 #pixels

Rect = DefStruct.new{{
  pos: Vec[0,0],
  size: Vec[0,0],
}}.reopen do
  def min_x; pos.x; end
  def min_y; pos.y; end
  def max_x; pos.x + size.x; end
  def max_y; pos.y + size.y; end
end

GameState = DefStruct.new{{
  alive: true,
  scroll_x: 0,
  player_pos: Vec[20,0],
  player_vel: Vec[0,0],
  obstacles: [], # array of Vec
  obstacle_countdown: OBSTACLE_SPAWN_INTERVAL,
}}

class GameWindow < Gosu::Window
  def initialize(*args)
    super
    @images = {
      background: Gosu::Image.new(self, 'images/background.png', false),
      foreground: Gosu::Image.new(self, 'images/foreground.png', true),
      player: Gosu::Image.new(self, 'images/fruity_1.png', false),
      obstacle: Gosu::Image.new(self, 'images/obstacle.png', false),
    }
    @state = GameState.new
  end

  def button_down(button)
    case button
    when Gosu::KbEscape then close
    when Gosu::KbSpace then @state.player_vel.set!(JUMP_VEL)
    end
  end

  def spawn_obstacle
    @state.obstacles << Vec[width, rand(50..320)]
  end

  def update
    dt = update_interval / 1000.0

    @state.scroll_x += dt*OBSTACLE_SPEED*0.5
    if @state.scroll_x > @images[:foreground].width
      @state.scroll_x = 0
    end

    @state.player_vel += dt*GRAVITY
    @state.player_pos += dt*@state.player_vel

    @state.obstacle_countdown -= dt
    if @state.obstacle_countdown <= 0
      spawn_obstacle
      @state.obstacle_countdown += OBSTACLE_SPAWN_INTERVAL
    end

    @state.obstacles.each do |obst|
      obst.x -= dt*OBSTACLE_SPEED
    end

    if player_is_colliding?
      @state.alive = false
    end
  end

  def player_is_colliding?
    player_r = player_rect    
    obstacle_rects.find { |obst_r| rects_insterct?(player_r, obst_r) }
  end

  def rects_insterct?(r1, r2)
    return false if r1.max_x < r2.min_x
    return false if r1.min_x > r2.max_x

    return false if r1.min_y > r2.max_y
    return false if r1.max_y < r2.min_y

    true
  end

  def draw
    @images[:background].draw(0, 0, 0)
    @images[:foreground].draw(-@state.scroll_x, 0, 0)
    @images[:foreground].draw(-@state.scroll_x + @images[:foreground].width, 0, 0)

    @state.obstacles.each do |obst|
      img_y = @images[:obstacle].height 
      # top log
      @images[:obstacle].draw(obst.x, obst.y - img_y, 0)
      scale(1, -1) do
        # bottom log
        @images[:obstacle].draw(obst.x, -height - img_y + (height - obst.y - OBSTACLE_GAP), 0)
      end
    end

    @images[:player].draw(@state.player_pos.x, @state.player_pos.y, 0)

    debug_draw
  end

  def player_rect
    Rect.new(
      pos: @state.player_pos,
      size: Vec[@images[:player].width, @images[:player].height]
    )
  end

  def obstacle_rects
    img_y = @images[:obstacle].height 
    obst_size = Vec[@images[:obstacle].width, @images[:obstacle].height]

    @state.obstacles.flat_map do |obst|
      top = Rect.new(pos: Vec[obst.x, obst.y - img_y], size: obst_size)
      bottom = Rect.new(pos: Vec[obst.x, obst.y + OBSTACLE_GAP], size: obst_size)
      [top, bottom]
    end
  end

  def debug_draw
    color = player_is_colliding? ? Gosu::Color::RED : Gosu::Color::GREEN

    draw_debug_rect(player_rect, color) 
    obstacle_rects.each do |obst_rect|
      draw_debug_rect(obst_rect)
    end
  end

  def draw_debug_rect(rect, color = Gosu::Color::GREEN)
    x = rect.pos.x
    y = rect.pos.y
    w = rect.size.x
    h = rect.size.y

    points = [
      Vec[x, y],
      Vec[x + w, y],
      Vec[x + w, y + h],
      Vec[x, y + h]
    ]

    points.each_with_index do |p1, idx|
      p2 = points[(idx + 1) % points.size]
      draw_line(p1.x, p1.y, color, p2.x, p2.y, color)
    end
  end
end

window = GameWindow.new(320, 480, false)
window.show
