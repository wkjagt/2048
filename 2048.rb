require 'io/console'

String::COLORS = {red:[31],green:[32],brown:[33],magenta:[35],cyan:[36],bold:[1,22] }.each do |c,s|
  define_method(c) { "\033[#{s[0]}m#{self}\033[#{s[1].to_i}m" }
end

class Board
  X, Y = 0, 1
  COLORS = String::COLORS.keys[0..-2]
  HOR_LINE, EMPTY_COL = "-" * 29, "|      " * 4 + "|"

  def initialize
    @score = 0
    @squares = (0..15).map { |n| [[n % 4, n / 4], nil] }.to_h
    @move_order = { [0,-1] => -> { lines(Y) }, [0,+1] => -> { lines(Y).reverse }, # rows
                    [-1,0] => -> { lines(X) }, [+1,0] => -> { lines(X).reverse }} # columns
    2.times { add_new }
    @history = [@squares.dup]
    draw
  end

  def draw
    system "clear" or system "cls"
    [ HOR_LINE,
      lines(Y).map { |row| format_row(row) }.join,
      "\nMoves: #{@history.size - 1}\nScore: #{@score}" ].each{ |l| puts l }
  end

  def move(dir)
    @doubled = []
    @move_order[dir].call.each do |line|
      line.select { |_,v| v }.each_key { |location| slide_square(location, dir) }
    end
    add_new && @history << @squares.dup unless @history.last == @squares
    draw
  end

  private

  def format_row(row)
    "#{EMPTY_COL}\n|" +
    row.map { |(_, val)| (val ? format_square(val) : " " * 6) + "|" }.join +
    "\n#{EMPTY_COL}\n#{HOR_LINE}\n"
  end

  def add_new
    @squares[empty_square] = [2, 4].sample
  end

  def format_square(value)
    log = Math.log(value, 2).to_i
    f = value.to_s.center(6).send(COLORS[-1 + log % COLORS.length])
    log <= COLORS.length ? f : f.bold
  end

  def slide_square(loc, dir)
    value, neighbour = @squares[loc], [loc[X] + dir[X],loc[Y] + dir[Y]]
    return unless @squares.key? neighbour

    if @squares[neighbour].nil?
      @squares[loc], @squares[neighbour] = nil, value
      slide_square(neighbour, dir)
    elsif @squares[neighbour] == value && !@doubled.include?(neighbour)
      @squares[loc], @squares[neighbour] = nil, value * 2
      @doubled << neighbour
      @score += @squares[neighbour]
    end
  end

  def empty_square
    @squares.select{ |_, v| v.nil? }.to_a.sample(1).to_h.keys.first
  end

  def lines(dir)
    (0..3).map{ |i| @squares.select { |s| s[dir] == i } }
  end
end

Game = Struct.new(:board) do
  KEYS = { "A" => [0,-1], "D" => [-1,0], "B" => [0,+1], "C" => [+1,0], "\u0003" => :exit }

  def run
    while key = STDIN.getch
      ((KEYS[key] == :exit ? exit : board.move(KEYS[key])) if KEYS.key?(key))
    end
  end
end

Game.new(Board.new).run
