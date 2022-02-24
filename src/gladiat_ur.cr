require "http/client"
require "json"

# AI-Arena playing the Royal Game of Ur against each other
module GladiatUr
  VERSION = "0.1.0"

  class Error < Exception
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

    def initialize(@id)
      @current_turn = 0
      @board = { Color::Black => Array(Int8).new, Color::White => Array(Int8).new }
      @turn_log = [] of String
    end

    def add_player(player : Player)
      raise AlreadyFull.new(self.to_s) if @players[Color::White]? && @players[Color::Black]?
      player.alive!

      color = @players[Color::White]? ? Color::Black : Color::White
      player.join_game(self, color)
      @players[color] = player
    end

    SPAWN_FIELD = 0
    TARGET_FIELD = 15
    REROLL_FIELDS = [4,8,14]
    FIGHT_FIELDS = [5,6,7,9,10,11,12]
    def start
      raise NotEnoughPlayer.new if @players[Color::White].nil? || @players[Color::Black].nil?

      current_color = Color.new(Random.rand(2))

#       until score[Color::White] == 7 || score[Color::Black] == 7
      10.times do
        @current_turn += 1
        current_player = @players[current_color].not_nil!
        puts "Turn #{@current_turn} | #{current_color} | #{current_player.name}"

        movement = Random.rand(5)
        puts "Dice-Roll: #{movement}"

        valid_moves = [1i8]
        selected_token = current_player.make_turn(game: self, color: current_color, valid_moves: valid_moves)
        puts "AIs Choise: #{selected_token}"
        return end_game(reason: :invalid_move) unless valid_moves.includes?(selected_token)

        new_field = selected_token + movement
        board[current_color].delete(selected_token)

        case new_field
        when TARGET_FIELD
          score[current_color] += 1
          append_turn_to_log(current_color, selected_token, new_field, score: true)

          current_color = opponent(current_color)
        when REROLL_FIELDS
          board[current_color] << new_field
          append_turn_to_log(current_color, selected_token, new_field, reroll: true)
        when FIGHT_FIELDS
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

      puts turn_log.join("\n")
    end

    # Chess-like notation
    # W1-4 -> White moved from 1 to 4
    # Bx2-4 -> Black moved from 2 to 4 and removed a white token
    # W13-15+ -> White moved from 13 to 15 and got a point
    # B4-8R -> Black moved from 4 to 8 and got a reroll
    def append_turn_to_log(color : Color, current : Int8, target : Int8, fight=false, reroll=false, score=false)
      @turn_log << [
                     color.to_s[0],
                     fight ? 'x' : nil,
                     current,
                     '-',
                     target,
                     reroll ? 'R' : nil,
                     score ? 'x' : nil
                   ].compact.join
    end

    def opponent(color)
      color == Color::White ? Color::Black : Color::White
    end

    def end_game(reason)
      @players.each do |color, player|
        next if player.nil?

        player.leave_game(self, color)
      end
    end

    def to_s
      "Game<#{id}>"
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
    def make_turn(game : Game, color : Color, valid_moves : Array(Int8))
      message = {
        game: { id: game.id },
        color: color,
        board: {
          Color::Black.to_s.underscore => game.board[Color::Black],
          Color::White.to_s.underscore => game.board[Color::White]
        },
        moveable: valid_moves
      }.to_json
      puts message

      resp = @client.put(@uri.path + "/move", body: message, headers: @headers)
      raise FailedRequest.new(self.to_s) unless resp.success?

      return MakeTurnResponse.from_json(resp.body).move
    end

    def leave_game(game : Game, color)
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

      @client.delete(@uri.path + "/end", body: message, headers: @headers).success?
    end

    def to_s
      "Player<#{@name}|#{@url}>"
    end
  end
end

game = GladiatUr::Game.new "1"
game.add_player GladiatUr::Player.new(name: "Kjarrigan", url: "http://localhost:3000", token: "secret")
game.add_player GladiatUr::Player.new(name: "Lies", url: "http://localhost:3000", token: "secret")
game.start
