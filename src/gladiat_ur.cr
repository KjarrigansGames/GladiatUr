require "http/client"
require "json"
require "uuid"
require "file_utils"

# AI-Arena playing the Royal Game of Ur against each other
module GladiatUr
  VERSION = "0.1.0"

  class Error < Exception
  end

  # Webservice providing endpoints to manage games
  class API
    # Create a new game
    # Change game-settings
    # Run game
    # Abort?
    # Get game results (persistent archive?)
  end

  enum Color
    Black
    White
  end

  # Core Rules:
  # - 2 Players
  # - 7 Token per Player
  # - Turn based
  # - Movement determined by 4d2 (ranging from 0-4, 0 -> turn wasted)
  # - First to bring 7 Stones Home wins
  # - Home has to be reached with an exact movement
  # - The board constinsts of 3 areas, a personal are per player and a shared zone were you can
  #   actively interact with the opponent (kicking, blocking)
  # - 5 Special fields that trigger another turn and prevent enemie actions
  # - only one Token per field
  class Game
    class Error < Error; end
    class AlreadyFull < Error; end
    class NotEnoughPlayer < Error; end

    property id : String
    property current_turn : Int32
    property players = Hash(Color, Player | Nil).new
    property board : Hash(Color, Array(Int8))
    property score = Hash(Color, Int8).new(0i8)
    property turn_log : Array(String)

    def initialize(@id = UUID.random.hexstring)
      @board = { Color::Black => Array(Int8).new, Color::White => Array(Int8).new }

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

    NUMBER_OF_TOKENS = 7 # may become a game attribute later, e.g. for special game modes

    SPAWN_FIELD = 0i8
    TARGET_FIELD = 15i8
    REROLL_FIELDS = [4i8,8i8,14i8]
    SAFE_ZONE = 8i8
    FIGHT_FIELDS = [5i8,6i8,7i8,9i8,10i8,11i8,12i8]
    def start
      raise NotEnoughPlayer.new if @players[Color::White].nil? || @players[Color::Black].nil?

      current_color = Color.new(Random.rand(2))
      loop do
        return end_game(reason: :black_won, winner: Color::Black) if score[Color::Black] == NUMBER_OF_TOKENS
        return end_game(reason: :white_won, winner: Color::White) if score[Color::White] == NUMBER_OF_TOKENS

        @current_turn += 1
        current_player = @players[current_color].not_nil!

        movement = 4.times.sum { Random.rand(2) }
        @dice_rolls[movement] += 1

        valid_moves = calculate_valid_moves(movement, current_color)

        if valid_moves.empty?
          append_turn_to_log(current_color)
          current_color = opponent(current_color)

          next
        end

        selected_token = current_player.make_turn(game: self, color: current_color, dice_roll: movement, valid_moves: valid_moves)
        return end_game(reason: :invalid_move, winner: opponent(current_color)) unless valid_moves.includes?(selected_token)

        new_field = selected_token + movement
        board[current_color].delete(selected_token)

        case
        when new_field == TARGET_FIELD
          score[current_color] += 1
          append_turn_to_log(current_color, selected_token, new_field, score: true)

          current_color = opponent(current_color)
        when REROLL_FIELDS.includes?(new_field)
          board[current_color] << new_field
          append_turn_to_log(current_color, selected_token, new_field, reroll: true)
        when FIGHT_FIELDS.includes?(new_field)
          empty = board[opponent(current_color)].delete(new_field).nil?
          board[current_color] << new_field
          append_turn_to_log(current_color, selected_token, new_field, fight: !empty)

          current_color = opponent(current_color)
        else
          board[current_color] << new_field
          append_turn_to_log(current_color, selected_token, new_field)

          current_color = opponent(current_color)
        end
      end
    ensure
      save_metadata
    end

    def calculate_valid_moves(movement, color : Color)
      valid_moves = @board[color].map do |token_position|
        new_pos = token_position + movement
        next if @board[color].includes?(new_pos) # already occupied by yourself
        next if new_pos > TARGET_FIELD # only exact movement scores
        next if new_pos == SAFE_ZONE && @board[opponent(color)].includes?(SAFE_ZONE) # safe zone is blocked

        token_position
      end.compact

      # if you have tokens left AND the position is not blocked allow adding a new token
      if !@board[color].includes?(SPAWN_FIELD + movement) &&
         @board[color].size + @score[color] < NUMBER_OF_TOKENS
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
        score: {
          Color::Black.to_s.underscore => @score[Color::Black],
          Color::White.to_s.underscore => @score[Color::White]
        },
        turns: @current_turn,
        log: @turn_log,
        dice_rolls: @dice_rolls
      }

      File.write(File.join("archive", @id + ".json"), meta_data.to_json)
      puts turn_log.join("\n")
    end
  end

  # GameServer:
  # - can host multiple games
  # - Server connects to the clients (and not vice versa)
  class Server
  end

  # Wrapper to connect to the Client-AI
  # - client.url/ping - are you still alive?, no response necessary
  # - client.url/start - start a new game with a session_id, no response necessary
  # - client.url/move - send current board_state and , respond with token-id (to move)
  # - client.url/end - send result (winner, win_reason)
  struct Player
    class Error < Error; end
    class NotResponding < Error; end
    class Refused < Error; end
    class FailedRequest < Error; end

    property name : String
    property url : String
    property token : String

    def initialize(@name, @url, @token)
      @uri = URI.parse(@url)
      @headers = HTTP::Headers{"Content-Type" => "application/json", "Accept" => "application/json",
                               "Authorization" => "Bearer #{@token}"}
      @client = HTTP::Client.new(@uri)
    end

    def to_json(json)
      json.object do
        json.field "name", @name
        json.field "url", @url
      end
    end

    def alive?
      @client.head(@uri.path + "/ping").success?
    end

    def alive!
      raise NotResponding.new(self.to_s) unless alive?
    end

    struct JoinGameResponse
      include JSON::Serializable

      property accept : Bool
    end

    # Send:
    # {
    #   "game": {
    #     "id": "64c8b0f0-aa36-459d-a997-cc9e818d7b8e"
    #   },
    #   "color": "white"
    # }
    def join_game(game : Game, color : Color)
      message = JSON.build do |json|
        json.object do
          json.field "game" do
            json.object do
              json.field "id", game.id
            end
          end
          json.field "color", color
        end
      end

      resp = @client.post(@uri.path + "/new", body: message, headers: @headers)

      raise FailedRequest.new(self.to_s) unless resp.success?
      return true if JoinGameResponse.from_json(resp.body).accept

      raise Refused.new(self.to_s)
    rescue
    end

    struct MakeTurnResponse
      include JSON::Serializable

      property move : Int8
    end

    # Send:
    # {
    #   "game": {
    #     "id": "64c8b0f0-aa36-459d-a997-cc9e818d7b8e"
    #   },
    #   "color": "white",
    #   "board": {
    #     "white": [1,2,5,8],
    #     "black": [1,2,3]
    #   },
    #   "moveable": [2,5]
    # }
    def make_turn(game : Game, color : Color, dice_roll : Int32, valid_moves : Array(Int8))
      message = {
        game: { id: game.id },
        color: color,
        board: {
          Color::Black.to_s.underscore => game.board[Color::Black],
          Color::White.to_s.underscore => game.board[Color::White]
        },
        dice_roll: dice_roll,
        moveable: valid_moves
      }.to_json

      resp = @client.put(@uri.path + "/move", body: message, headers: @headers)
      raise FailedRequest.new(self.to_s) unless resp.success?

      return MakeTurnResponse.from_json(resp.body).move
    end

    # Send
    # {
    #   "game": {
    #     "id": "64c8b0f0-aa36-459d-a997-cc9e818d7b8e"
    #   },
    #   "color": "white",
    #   "winner": "white"
    # }
    def leave_game(game : Game, color : Color, winner : Color|Nil)
      message = {
        game: { id: game.id },
        color: color,
        winner: winner,
      }.to_json

      @client.delete(@uri.path + "/end", body: message, headers: @headers).success?
    end

    def to_s
      "Player<#{@name}|#{@url}>"
    end
  end
end

game = GladiatUr::Game.new
game.add_player GladiatUr::Player.new(name: "White", url: ARGV[0]? || "http://localhost:3000", token: "secret")
game.add_player GladiatUr::Player.new(name: "Black", url: ARGV[1]? || "http://localhost:3000", token: "secret")
game.start
