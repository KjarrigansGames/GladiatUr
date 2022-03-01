require "../src/gladiat_ur"
require "kemal"

before_all do |env|
  env.response.content_type = "application/json"
end

get "/info" do
  {
    version: GladiatUr::VERSION
  }.to_json
end

struct Player
  include JSON::Serializable

  property name : String
  property url : String
  property token : String
end

struct NewGameRequest
  include JSON::Serializable

  property players : Array(Player)
end

get "/game/:game_id" do |env|
  game_id = env.params.url["game_id"]
  File.read(File.join(GladiatUr::Game::METADATA_ARCHIVE_PATH, game_id + ".json"))
end

post "/game" do |env|
  req = NewGameRequest.from_json env.request.body.not_nil!

  game = GladiatUr::Game.new
  req.players.each do |player|
    game.add_player GladiatUr::Player.new(name: player.name, url: player.url, token: player.token)
  end
  meta = game.start
  { game: { id: game.id }, winner: meta[:winner] }.to_json
rescue err : GladiatUr::Error
  { error: "#{err.class.to_s} #{err.to_s}".strip  }.to_json
end

Kemal.run
