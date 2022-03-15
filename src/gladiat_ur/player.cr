require "http/client"

module GladiatUr

  # Wrapper for the client API as defined in https://pad.evilcookie.de/35KdzJ2AQDOxOfc4_zvq0w
  class Player
    class Error < Error; end
    class NotResponding < Error; end
    class Refused < Error; end
    class FailedRequest < Error; end

    property name : String
    property url : String
    property token : String
    property uri : URI
    property headers : HTTP::Headers

    def initialize(@name, @url, @token)
      @uri = URI.parse(@url)
      @headers = HTTP::Headers{"Content-Type" => "application/json", "Accept" => "application/json",
                               "Authorization" => "Bearer #{@token}"}
    end

    def client
      @client ||= HTTP::Client.new(@uri)
    end

    def to_json(json)
      json.object do
        json.field "name", @name
        json.field "url", @url
      end
    end

    def alive?
      client.head(@uri.path + "/ping").success?
    end

    def alive!
      raise NotResponding.new(self.to_s) unless alive?
    end

    struct JoinGameResponse
      include JSON::Serializable

      property accept : Bool
    end

    def join_game(game : Game, color : Color, turn_timeout : Int32 = 500)
      message = {
        game: {
          id: game.id,
          ruleset: game.rule_set.to_h,
          turn_timeout_ms: turn_timeout,
        },
        color: color
      }.to_json

      resp = client.post(@uri.path + "/start", body: message, headers: @headers)

      raise FailedRequest.new(self.to_s) unless resp.success?
      return true if JoinGameResponse.from_json(resp.body).accept

      raise Refused.new(self.to_s)
    rescue JSON::SerializableError
    rescue JSON::ParseException
      raise FailedRequest.new(self.to_s)
    end

    struct MakeTurnResponse
      include JSON::Serializable

      property move : Int8
    end

    def make_turn(game : Game, color : Color, dice_roll : Int32, valid_moves : Array(Int8))
      message = {
        game: { id: game.id },
        color: color,
        board: {
          Color::Black.to_s.underscore => game.board[Color::Black],
          Color::White.to_s.underscore => game.board[Color::White]
        },
        score: {
          Color::Black.to_s.underscore => game.score[Color::Black],
          Color::White.to_s.underscore => game.score[Color::White]
        },
        dice_roll: dice_roll,
        moveable: valid_moves
      }.to_json

      resp = client.put(@uri.path + "/turn", body: message, headers: @headers)
      raise FailedRequest.new(self.to_s) unless resp.success?

      return MakeTurnResponse.from_json(resp.body).move
    rescue JSON::SerializableError
      raise FailedRequest.new(self.to_s)
    end

    def leave_game(game : Game, color : Color, winner : Color|Nil)
      message = {
        game: { id: game.id },
        color: color,
        winner: winner,
      }.to_json

      client.delete(@uri.path + "/end", body: message, headers: @headers).success?
    rescue
    end

    def to_s
      "Player<#{@name}|#{@url}>"
    end
  end
end
