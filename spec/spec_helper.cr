require "spec"
require "../src/gladiat_ur"
require "./client_api_docs"

def setup_game(tokens_white = [] of Int8, tokens_black = [] of Int8, score_white = 0i8, score_black = 0i8, &block : Array(Int8) -> Int8)
  game = GladiatUr::Game.new

  white = PredictableTurnPlayer.new("White", "http://spec", "SECRET")
  white.client = HTTPMock.new do |request|
    req = ClientJSON::PutTurn.from_json request.body.not_nil!

    HTTP::Client::Response.new(200, "{\"move\":#{block.call(req.moveable)}}")
  end
  game.add_player white
  game.add_player PredictableTurnPlayer.new("Black", "http://spec", "SECRET")

  game.board[GladiatUr::Color::White] = tokens_white
  game.board[GladiatUr::Color::Black] = tokens_black

  game.score[GladiatUr::Color::White] = score_white
  game.score[GladiatUr::Color::Black] = score_black

  game
end

class HTTPMock < HTTP::Client
  property callback : Proc(HTTP::Request, HTTP::Client::Response)
  def initialize(&@callback : HTTP::Request -> HTTP::Client::Response)
    super("spec")
  end

  private def exec_internal(request)
    @callback.call(request)
  end
end

class GladiatUr::Player
  def client=(client)
    @client = client
  end
end

def setup_player(&block : HTTP::Request -> HTTP::Client::Response)
  player = GladiatUr::Player.new "Spec", "http://spec", "SECRET"
  player.client = HTTPMock.new(&block)
  player
end

class PredictableTurnPlayer < GladiatUr::Player
  def alive?; true; end
  def join_game(*_args); true; end
  def leave_game(*_args); true; end
end
