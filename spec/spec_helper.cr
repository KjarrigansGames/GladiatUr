require "spec"
require "../src/gladiat_ur"

def setup_game(tokens_white = [] of Int8, tokens_black = [] of Int8, score_white = 0i8, score_black = 0i8, &block : Array(Int8) -> Int8)
  game = GladiatUr::Game.new

  game.add_player GladiatUr::Player::Dummy.new("White", block)
  game.add_player GladiatUr::Player::Dummy.new("Black")

  game.board[GladiatUr::Color::White] = tokens_white
  game.board[GladiatUr::Color::Black] = tokens_black

  game.score[GladiatUr::Color::White] = score_white
  game.score[GladiatUr::Color::Black] = score_black

  game
end
