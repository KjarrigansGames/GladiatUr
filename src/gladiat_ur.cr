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
    property id : String
    property current_turn : Int8
    property players = { Color::White => nil, Color::Black => nil}
    property white_token = [] of Int32
    property black_token = [] of Int32

    def initialize(@id)
      @current_turn = 0
      @players = {} of Color => Player
    end

    def add_player(player : Player)
      raise AlreadyFull.new(self.to_s) if @players[Color::White] && @players[Color::Black]
      player.alive!

      if @player_white
        player.join_game(self, Color::Black)
        @player_black = player
      else
        player.join_game(self, Color::White)
        @player_white = player
      end
    end

    SPAWN_FIELD = 0
    TARGET_FIELD = 15
    REROLL_FIELDS = [4,8,14]
    FIGHT_FIELDS = [5,6,7,9,10,11,12]
    def start
      current_color = Color.get(Random.rand(2))

      until white_score == 7 || black_score == 7
        @current_turn += 1
        movement = Random.rand(5)
        @players[current_color].make_turn(self, current_color)
      end
    end

    def to_h
      {
        game: { id: id },
        board: {
          white: [1,2,3],
          black: [1,2,3]
        },
        moveable: [1]
      }
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
      raise NotResponding, self.to_s unless alive?
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
    def make_turn(game : Game, color : Color)
      message = game.to_h.merge(color: color)

      resp = @client.put(@uri.path + "/move", body: message.to_json, headers: @headers)
      raise FailedRequest.new(self.to_s) unless resp.success?

      return MakeTurnResponse.from_json(resp.body).move
    end

    def leave_game(game : Game)
#       @client.delete(@uri.path + "/end", body: game.to_json, headers: @headers).success?
    end

    def to_s
      "Player<#{@name}|#{@url}>"
    end
  end
end

game = GladiatUr::Game.new "1"
pl = GladiatUr::Player.new(name: "Kjarrigan", url: "http://localhost:3000", token: "secret")
p pl.alive?
p pl.join_game(game, color: GladiatUr::Color::White)
p pl.make_turn(game, color: GladiatUr::Color::White)
# p pl.make_turn(game, color: GladiatUr::Color::White)
