require "uuid"
require "file_utils"

module GladiatUr
  class Game
    class Error < Error; end
    class AlreadyFull < Error; end
    class NotEnoughPlayers < Error; end
    class InvalidMove < Error; end

    property id : String
    property current_turn : Int32
    property players = Hash(Color, Player).new
    property board : Hash(Color, Array(Int8))
    property score = Hash(Color, Int8).new(0i8)
    property rule_set : RuleSet
    property turn_log : Array(String)


    def initialize(@id = UUID.random.hexstring, rule_set : String|RuleSet = "standard")
      @board = { Color::Black => Array(Int8).new, Color::White => Array(Int8).new }
      @rule_set = rule_set.is_a?(String) ? RULES[rule_set] : rule_set
      raise ArgumentError.new("Invalid Ruleset") if @rule_set.nil?

      # Statistical knowledge
      @current_turn = 0
      @turn_log = [] of String
      @dice_rolls =  Hash(Int32, Int32).new(0)
    end

    def add_player(player : Player)
      raise AlreadyFull.new(self.to_s) if @players[Color::White]? && @players[Color::Black]?
      player.alive!

      color = @players[Color::White]? ? Color::Black : Color::White
      player.join_game(self, color)
      @players[color] = player
    end

    METADATA_ARCHIVE_PATH = "./archive"

    def start
      raise NotEnoughPlayers.new if @players[Color::White]?.nil? || @players[Color::Black]?.nil?

      current_color = Color.new(Random.rand(2))
      loop do
        break end_game(reason: :black_won, winner: Color::Black) if score[Color::Black] == @rule_set.score_to_win
        break end_game(reason: :white_won, winner: Color::White) if score[Color::White] == @rule_set.score_to_win

        current_color = turn(current_color)
      rescue err : InvalidMove
        break end_game(reason: :invalid_move, winner: opponent(current_color))
      end

      save_metadata
    end

    def turn(current_color, deterministic_dice_roll : Int32|Nil = nil )
      @current_turn += 1
      current_player = @players[current_color].not_nil!

      movement = deterministic_dice_roll || 4.times.sum { Random.rand(2) }
      @dice_rolls[movement] += 1

      valid_moves = calculate_valid_moves(movement, current_color)

      if valid_moves.empty?
        append_turn_to_log(current_color)
        return opponent(current_color)
      end

      selected_token = current_player.make_turn(game: self, color: current_color, dice_roll: movement, valid_moves: valid_moves)
      raise InvalidMove.new("#{current_color} wanted to move #{selected_token}->#{selected_token + movement}") unless valid_moves.includes?(selected_token)

      new_field = selected_token + movement
      board[current_color].delete(selected_token)

      case
      when new_field == @rule_set.target_field
        score[current_color] += 1
        append_turn_to_log(current_color, selected_token, new_field, score: true)

        opponent(current_color)
      when @rule_set.reroll_fields.includes?(new_field)
        board[current_color] << new_field
        board[current_color].sort!
        append_turn_to_log(current_color, selected_token, new_field, reroll: true)

        current_color
      when @rule_set.combat_fields.includes?(new_field)
        empty = board[opponent(current_color)].delete(new_field).nil?
        board[current_color] << new_field
        board[current_color].sort!
        append_turn_to_log(current_color, selected_token, new_field, fight: !empty)

        opponent(current_color)
      else
        board[current_color] << new_field
        board[current_color].sort!
        append_turn_to_log(current_color, selected_token, new_field)

        opponent(current_color)
      end
    end

    def calculate_valid_moves(movement, color : Color)
      return [] of Int8 if movement == 0

      valid_moves = @board[color].map do |token_position|
        new_pos = token_position + movement

        next if @board[color].includes?(new_pos) # already occupied by yourself
        next if new_pos > @rule_set.target_field # only exact movement scores

        next token_position if START_AREA.includes?(new_pos)
        next token_position if TARGET_AREA.includes?(new_pos)

        next if @rule_set.safe_zone_fields.includes?(new_pos) && @board[opponent(color)].includes?(new_pos)

        token_position
      end.compact

      # if you have tokens left AND the position is not blocked allow adding a new token
      if !@board[color].includes?(SPAWN_FIELD + movement) &&
         @board[color].size + @score[color] < @rule_set.tokens_per_player
        valid_moves << SPAWN_FIELD
      end

      valid_moves.sort
    end

    # Chess-like notation
    # W1-4 -> White moved from 1 to 4
    # Bx2-4 -> Black moved from 2 to 4 and removed a white token
    # W13-15+ -> White moved from 13 to 15 and got a point
    # B4-8R -> Black moved from 4 to 8 and got a reroll
    # B- -> Black can't move
    def append_turn_to_log(color : Color, current : Int8|Nil=nil, target : Int8|Nil=nil, fight=false, reroll=false, score=false)
      @turn_log << [
                     color.to_s[0],
                     fight ? 'x' : nil,
                     current,
                     '-',
                     target,
                     reroll ? 'R' : nil,
                     score ? '+' : nil
                   ].compact.join
    end

    def opponent(color)
      color == Color::White ? Color::Black : Color::White
    end

    def end_game(reason, winner : Color)
      @turn_log << (winner == Color::Black ? "0-1" : "1-0")

      @players.each do |color, player|
        next if player.nil?

        player.leave_game(self, color, winner: winner)
      end
    end

    def to_s
      "Game<#{id}>"
    end

    def save_metadata
      FileUtils.mkdir_p METADATA_ARCHIVE_PATH

      meta_data = {
        game_id: @id,
        players: {
          Color::Black.to_s.underscore => @players[Color::Black],
          Color::White.to_s.underscore => @players[Color::White]
        },
        winner: @turn_log[-1] == "0-1" ? Color::Black : Color::White,
        score: {
          Color::Black.to_s.underscore => @score[Color::Black],
          Color::White.to_s.underscore => @score[Color::White]
        },
        turns: @current_turn,
        log: @turn_log,
        dice_rolls: @dice_rolls
      }

      File.write(File.join("archive", @id + ".json"), meta_data.to_json)

      meta_data
    end
  end
end
