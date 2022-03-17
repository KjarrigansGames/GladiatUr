require 'sinatra'
require 'sinatra/json'

def parse_json
  JSON.parse request.body.read
end

get '/ping' do
  halt 204
end

post '/start' do
  data = parse_json
  puts "Starting Game##{data['game']['id']} as Player-#{data['color']}"
  
  json accept: true
end

put '/turn' do
  data = parse_json
  json move: data['moveable'].first
end

delete '/end' do
  data = parse_json
  
  if data['color'] == data['winner']
    puts "Game##{data['game']['id']} won"
  else
    puts "Game##{data['game']['id']} lost"
  end
  halt 204
end
