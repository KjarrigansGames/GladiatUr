require "http/client"

module GladiatUr

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

    def from_json
    end

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
    rescue JSON::SerializableError
      raise FailedRequest.new(self.to_s)
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
    #   "dice_roll": 3
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
    rescue JSON::SerializableError
      raise FailedRequest.new(self.to_s)
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
    rescue
    end

    def to_s
      "Player<#{@name}|#{@url}>"
    end
  end
end
