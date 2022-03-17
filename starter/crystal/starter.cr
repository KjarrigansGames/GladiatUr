require "kemal"
require "json"

enum Color
  Black
  White
end

struct RuleSet
  include JSON::Serializable

  struct SpecialFields
    include JSON::Serializable

    property target : Int8
    property reroll : Array(Int8)
    property safe : Array(Int8)
  end

  property name : String
  property tokens_per_player : Int8
  property score_to_win : Int8
  property special_fields : SpecialFields
end

struct NewGame
  include JSON::Serializable

  property id : String
  property ruleset : RuleSet
  property turn_timeout_ms : Int32
end

struct Game
  include JSON::Serializable

  property id : String
end

struct Board
  include JSON::Serializable

  property black : Array(Int8)
  property white : Array(Int8)
end

struct Score
  include JSON::Serializable

  property black : Int8
  property white : Int8
end

struct NewGameRequest
  include JSON::Serializable

  property game : NewGame
  property color : Color
end

struct TurnRequest
  include JSON::Serializable

  property game : Game
  property color : Color
  property board : Board
  property moveable : Array(Int8)
  property score : Score
  property dice_roll : Int8
end

struct EndGameRequest
  include JSON::Serializable

  property game : Game
  property color : Color
  property winner : Color
end

before_all do |env|
  env.response.content_type = "application/json"
end

get "/ping" do |env|
  halt env, status_code: 201
end

post "/start" do |env|
  req = NewGameRequest.from_json env.request.body.not_nil!

  { accept: true }.to_json
end

put "/turn" do |env|
  req = TurnRequest.from_json env.request.body.not_nil!

  { move: req.moveable.last }.to_json
end

delete "/end" do |env|
  req = EndGameRequest.from_json env.request.body.not_nil!

  halt env, status_code: 204
end

Kemal.run
