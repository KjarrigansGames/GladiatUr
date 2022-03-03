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


  SAVE_PATH = "./players"
  def self.load(name)
    File.open(File.join(SAVE_PATH, name + ".json")) do |json|
      from_json(json)
    end
  rescue File::NotFoundError
    nil
  end

  def save
    FileUtils.mkdir_p SAVE_PATH

    File.open(File.join(SAVE_PATH, @name + ".json"), "w+") do |json|
      to_json(json)
    end
  end

  def delete
    File.delete(File.join(SAVE_PATH, @name + ".json"))
  end
end

struct NewGameRequest
  include JSON::Serializable

  property players : Array(Player|String)
end

get "/game/:game_id" do |env|
  game_id = env.params.url["game_id"]
  File.read(File.join(GladiatUr::Game::METADATA_ARCHIVE_PATH, game_id + ".json"))
end

post "/game" do |env|
  req = NewGameRequest.from_json env.request.body.not_nil!

  game = GladiatUr::Game.new
  req.players.compact.each do |player|
    player = Player.load(player) if player.is_a?(String)
    raise "Invalid PlayerData" if player.nil?

    game.add_player GladiatUr::Player.new(name: player.name, url: player.url, token: player.token)
  end
  meta = game.start
  { game: { id: game.id }, winner: meta[:winner] }.to_json
rescue err : GladiatUr::Error
  { error: "#{err.class.to_s} #{err.to_s}".strip  }.to_json
end

get "/players/:player_name" do |env|
  if player = Player.load(env.params.url["player_id"])
    player.to_json
  else
    halt(env, status_code: 404)
  end
end

post "/players" do |env|
  player = Player.from_json env.request.body.not_nil!

  if existing_player = Player.load(player.name)
     halt(env, status_code: 403) if existing_player.token != player.token
  end

  player.save
end

delete "/players" do |env|
  player = Player.from_json env.request.body.not_nil!

  if existing_player = Player.load(player.name)
     halt(env, status_code: 403) if existing_player.token != player.token

     player.delete
  else
    halt(env, status_code: 201)
  end
end

Kemal.run
