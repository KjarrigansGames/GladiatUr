require "json"
require "kemal"

# AI-Arena playing the Royal Game of Ur against each other
module GladiatUr
  VERSION = "0.1.0"

  class Error < Exception
  end

  enum Color
    Black
    White
  end
end
require "./gladiat_ur/player"
require "./gladiat_ur/game"

# game = GladiatUr::Game.new
# game.add_player GladiatUr::Player.new(name: "White", url: ARGV[0]? || "http://localhost:3000", token: "secret")
# game.add_player GladiatUr::Player.new(name: "Black", url: ARGV[1]? || "http://localhost:3000", token: "secret")
# game.start
