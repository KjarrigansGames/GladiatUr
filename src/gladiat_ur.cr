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
require "./gladiat_ur/rule_set"
require "./gladiat_ur/game"
