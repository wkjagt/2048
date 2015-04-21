#!/usr/bin/ruby

require "awesome_print"
require 'io/console'
require "pry"

class String
	def red;            "\033[31m#{self}\033[0m" end
	def green;          "\033[32m#{self}\033[0m" end
	def brown;          "\033[33m#{self}\033[0m" end
	def magenta;        "\033[35m#{self}\033[0m" end
	def cyan;           "\033[36m#{self}\033[0m" end
	def bold;           "\033[1m#{self}\033[22m" end
end

class Board
	COLORS = [:red, :green, :brown, :magenta, :cyan]
	HOR_LINE = "-" * 29
	EMPTY_COL = "|      " * 4 + "|"

	def initialize
    @score = 0
		@doubled = []
		@squares = (0..15).map { |n| [[n % 4, n / 4], nil] }.to_h
		@move_order = {
			[0,-1] => -> { rows }, [0,+1] => -> { rows.reverse },
			[-1,0] => -> { cols }, [+1,0] => -> { cols.reverse },
		}

		2.times { add_new }
		@history = [@squares.dup]
	end

	def add_new
		@squares[random_empty] = [2, 4].sample(1).first
	end

	def draw
		system "clear" or system "cls"

		puts HOR_LINE
		rows.each do |r|
			print EMPTY_COL + "\n|"
			r.each { |(s, v)| print format_nr_square(v) + "|" }
			puts "\n" + EMPTY_COL + "\n" + HOR_LINE
		end
		puts "\nMoves: #{@history.size - 1}\nScore: #{@score}"
	end

	def move(dir)
		@doubled = []
		move_lines(@move_order[dir].call, dir)

		unless @history.last == @squares
      add_new
      @history << @squares.dup
		end
	end

	private

	def format_nr_square(value)
		return " " * 6 unless value
		index = -1 + Math.log(value, 2).to_i % COLORS.length
		value.to_s.center(6).send(COLORS[index]).bold
	end

	def move_lines(lines, dir)
		lines.each { |line| move_line(line, dir) }
	end

	def move_line(line, dir)
		line.select { |k, v| v }.each_key { |location| slide_square(location, dir) }
	end

	def slide_square(location, dir)
		value = @squares[location]
		neighbour = [location[0] + dir[0],location[1] + dir[1]]

		return unless @squares.key? neighbour

		if @squares[neighbour].nil?
			@squares[location], @squares[neighbour] = nil, value
			slide_square(neighbour, dir)
		elsif @squares[neighbour] == value && !@doubled.include?(neighbour)
			@squares[location], @squares[neighbour] = nil, value * 2
			@doubled << neighbour
      @score += value * 2
		end
	end

	def random_empty
		@squares.select { |_, v| v.nil? }.to_a.sample(1).to_h.keys.first
	end

	def line(index, dir)
	  @squares.select { |a| a[dir] == index }
	end

	def rows
		(0..3).map { |i| line(i, 1) }
	end

	def cols
		(0..3).map { |i| line(i, 0) }
	end
end

class Game
	KEYS = { "w" => [0,-1], "a" => [-1,0], "s" => [0,+1], "d" => [+1,0], "\u0003" => :exit }

	def initialize
		@board = Board.new
		@board.draw
	end

	def run
		while key = STDIN.getch
			next unless KEYS.key?(key)
			handle_key(KEYS[key])
			@board.draw
		end
	end

	def handle_key(action)
		action == :exit ? exit : @board.move(action)
	end
end

Game.new.run

