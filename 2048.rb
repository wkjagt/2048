require 'io/console'

String::COLORS = {red:[31],green:[32],brown:[33],magenta:[35],cyan:[36],bold:[1,22] }.each do |c,s|
  define_method(c) { "\033[#{s[0]}m#{self}\033[#{s[1].to_i}m" }
end

class Board
  X, Y = 0, 1
  COLORS = String::COLORS.keys[0..-2]
  HOR_LINE = "-" * 29
  EMPTY_COL = "|      " * 4 + "|"

  def initialize
    @score = 0
    @squares = (0..15).map { |n| [[n % 4, n / 4], nil] }.to_h
    @move_order = {
      [0,-1] => -> { rows }, [0,+1] => -> { rows.reverse },
      [-1,0] => -> { cols }, [+1,0] => -> { cols.reverse },
    }

    2.times { add_new }
    @history = [@squares.dup]
  end

  def draw
    system "clear" or system "cls"

    puts HOR_LINE
    rows.each { |row| draw_row(row) }
    puts "\nMoves: #{@history.size - 1}\nScore: #{@score}"
  end

  def move(dir)
    @doubled = []
    move_lines(@move_order[dir].call, dir)

    unless @history.last == @squares
      add_new
      @history << @squares.dup
    end
    self
  end

  private

  def draw_row(row)
    print "#{EMPTY_COL}\n|"
    print row.map { |(_, val)| format_square(val) + "|" }.join
    print "\n#{EMPTY_COL}\n#{HOR_LINE}\n"
  end

  def add_new
    @squares[random_empty] = [2, 4].sample(1).first
  end

  def format_square(value)
    return " " * 6 unless value

    log = Math.log(value, 2).to_i
    f = value.to_s.center(6).send(COLORS[-1 + log % COLORS.length])
    log <= COLORS.length ? f : f.bold
  end

  def move_lines(lines, dir)
    lines.each { |line| move_line(line, dir) }
  end

  def move_line(line, dir)
    line.select { |_,v| v }.each_key { |location| slide_square(location, dir) }
  end

  def slide_square(loc, dir)
    value = @squares[loc]
    neighbour = [loc[X] + dir[X],loc[Y] + dir[Y]]
    return unless @squares.key? neighbour

    if @squares[neighbour].nil?
      @squares[loc], @squares[neighbour] = nil, value
      slide_square(neighbour, dir)
    elsif @squares[neighbour] == value && !@doubled.include?(neighbour)
      @squares[loc], @squares[neighbour] = nil, value * 2
      @doubled << neighbour
      @score += value * 2
    end
  end

  def random_empty
    @squares.select{ |_, v| v.nil? }.to_a.sample(1).to_h.keys.first
  end

  def lines(dir)
    (0..3).map{ |i| @squares.select { |s| s[dir] == i } }
  end

  def rows
    lines(Y)
  end

  def cols
    lines(X)
  end
end

Game = Struct.new(:board) do
  KEYS = { "w" => [0,-1], "a" => [-1,0], "s" => [0,+1], "d" => [+1,0],
           "A" => [0,-1], "D" => [-1,0], "B" => [0,+1], "C" => [+1,0],
           "\u0003" => :exit }

  def run
    board.draw
    while key = STDIN.getch
      next unless KEYS.key?(key)
      KEYS[key] == :exit ? exit : board.move(KEYS[key]).draw
    end
  end
end

Game.new(Board.new).run
