require "kemal"
require "json"

enum Color
  Black
  White
end

struct Game
  include JSON::Serializable

  property id : String
end

class Board
  include JSON::Serializable

  property black : Array(Int8)
  property white : Array(Int8)
end

struct NewGameRequest
  include JSON::Serializable

  property game : Game
end

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
struct TurnRequest
  include JSON::Serializable

  property game : Game
  property color : Color
  property board : Board
  property moveable : Array(Int8)
end

before_all do |env|
  env.response.content_type = "application/json"
end

get "/ping" do |env|
  halt env, status_code: 201
end

post "/new" do |env|
  req = NewGameRequest.from_json env.request.body.not_nil!

  { accept: true }.to_json
end

put "/move" do |env|
  req = TurnRequest.from_json env.request.body.not_nil!

  { move: req.moveable.last }.to_json
end

delete "/end" do
end

Kemal.run
