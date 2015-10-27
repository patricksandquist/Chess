require_relative "display.rb"
require_relative "cursorable.rb"
require_relative "pieces"

class Board

  attr_reader :captured_white, :captured_black

  def initialize(new_game = true, grid = nil)
    if new_game
      @grid = populate
      @captured_white = []
      @captured_black = []
      @current_color = :white
    else
      @grid = grid
    end
  end

  def populate
    pop_grid = Array.new(8){ Array.new(8) }
    pop_grid.each_with_index do |row, row_idx|
      row.each_with_index do |el, col_idx|
        pop_grid[row_idx][col_idx] = EmptyPiece.new(self, [row_idx, col_idx])
      end
    end

    [:white, :black].each do |color|
      back_pieces = [Rook, Knight, Bishop, Queen, King, Bishop, Knight, Rook]
      back_idx = (color == :white) ? 7 : 0
      pawn_idx = (color == :white) ? 6 : 1

      back_pieces.each_with_index do |piece_class, i|
        pop_grid[back_idx][i] = piece_class.new(self, [back_idx, i], color)
      end

      8.times { |j| pop_grid[pawn_idx][j] = Pawn.new(self, [pawn_idx, j], color) }
    end

    pop_grid
  end

  def move(start,end_pos)
    raise NoPieceError unless piece_exist?(start)
    move_piece = @grid[start[0]][start[1]]
    raise WrongColorError unless move_piece.color == @current_color
    raise CantMoveIntoCheckError if move_piece.in_check?(end_pos)
    self.valid_move?(move_piece, start, end_pos)

    @grid[start[0]][start[1]] = EmptyPiece.new(self,[start[0],start[1]])
    if piece_exist?(end_pos)
      captured = piece_at_position(end_pos)
      if captured.color == :white
        @captured_white << captured.mark
      else
        @captured_black << captured.mark
      end
    end
    @grid[end_pos[0]][end_pos[1]] = move_piece
    move_piece.update_pos(end_pos, true)
  end

  def swap_color
    @current_color = other_color(@current_color)
  end

  def move!(start,end_pos)
    raise NoPieceError unless piece_exist?(start)
    move_piece = @grid[start[0]][start[1]]
    @grid[start[0]][start[1]] = EmptyPiece.new(self,[start[0],start[1]])
    @grid[end_pos[0]][end_pos[1]] = move_piece
    move_piece.update_pos(end_pos)
  end

  def dup
    new_grid = Array.new(8){Array.new(8)}
    new_board = self.class.new(false, new_grid)
    @grid.each_with_index do |row, i|
      row.each_with_index do |el, j|
        new_grid[i][j] = el.class.new(new_board, [i, j], el.color)
      end
    end

    new_board
  end

  def check?(color)
    king_position = find_king(color)
    other_color = other_color(color)
    @grid.flatten.any? do |el|
      el.color == other_color && el.valid_move?(king_position)
    end
  end

  def other_color(color)
    color == :white ? :black : :white
  end

  def find_king(color)
    pieces(color).each do |piece|
      return piece.position if piece.is_a?(King)
    end
    return "Error finding king..."
  end

  def valid_move?(piece, start, end_pos)
    raise InvalidMoveError if start == end_pos
    raise InvalidMoveError unless piece.valid_move?(end_pos)
  end

  def piece_exist?(pos)
    return false unless in_bounds?(pos)
    @grid[pos[0]][pos[1]].class != EmptyPiece
  end

  def piece_at_position(pos)
    @grid[pos[0]][pos[1]]
  end

  def [](pos)
    row,col = pos
    @grid[row][col]
  end

  def []=(pos, piece)
    row,col = pos
    @grid[row][col] = piece
  end

  def rows
    @grid
  end

  def in_bounds?(pos)
    pos.all? { |x| (0..7).include?(x) }
  end

  def pieces(color)
    @grid.flatten.select {|piece| piece.color == color}
  end

  def checkmate?(color)
    return false unless check?(color)
    pieces(color).all? do |piece|
      piece.moves.all? do |move|
        piece.in_check?(move)
      end
    end
  end
end

class NoPieceError < StandardError
end

class InvalidMoveError < StandardError
end

class CantMoveIntoCheckError < StandardError
end

class WrongColorError < StandardError
end
