require "../spec_helper"

describe GladiatUr::Player do
  describe "#alive? -> HEAD /ping" do
    it "is true" do
      player = setup_player do |request|
        request.method.should eq "HEAD"
        request.body.should be_nil

        HTTP::Client::Response.new 204
      end

      player.alive?.should be_true
    end

    it "is false" do
      player = setup_player do |request|
        request.method.should eq "HEAD"
        request.body.should be_nil

        HTTP::Client::Response.new 500
      end

      player.alive?.should be_false
    end

    it "has a raising version alive!" do
      player = setup_player do |request|
        request.method.should eq "HEAD"
        request.body.should be_nil

        HTTP::Client::Response.new 500
      end

      expect_raises(GladiatUr::Player::NotResponding) do
        player.alive!
      end
    end
  end

  describe "#join_game -> POST /start" do
    it "sends a valid JSON as defined in the docs" do
      player = setup_player do |request|
        request.method.should eq "POST"

        json = ClientJSON::PostStart.from_json(request.body.not_nil!)
        HTTP::Client::Response.new(201, "{\"accept\":true}")
      rescue err
        puts err.message
        body = request.body.not_nil!
        body.rewind
        puts body.to_s
        HTTP::Client::Response.new(500)
      end

      player.join_game(GladiatUr::Game.new, GladiatUr::Color::Black).should be_true
    end

    it "player accepts request" do
      player = setup_player do |request|
        request.method.should eq "POST"

        HTTP::Client::Response.new(201, "{\"accept\":true}")
      end

      player.join_game(GladiatUr::Game.new, GladiatUr::Color::Black).should be_true
    end

    it "player denies request" do
      player = setup_player do |request|
        request.method.should eq "POST"

        HTTP::Client::Response.new(201, "{\"accept\":false}")
      end

      expect_raises(GladiatUr::Player::Refused) do
        player.join_game(GladiatUr::Game.new, GladiatUr::Color::Black)
      end
    end
  end

  describe "make_turn -> PUT /turn" do
    it "sends a valid JSON as defined in the docs" do
      player = setup_player do |request|
        request.method.should eq "PUT"

        json = ClientJSON::PutTurn.from_json(request.body.not_nil!)
        HTTP::Client::Response.new(200, "{\"move\":0}")
      rescue err
        puts err.message
        body = request.body.not_nil!
        body.rewind
        puts body.to_s
        HTTP::Client::Response.new(500)
      end

      player.make_turn GladiatUr::Game.new, color: GladiatUr::Color::White, dice_roll: 1, valid_moves: [0i8]
    end
  end

  describe "leave_game -> DELETE /end" do
    it "sends a valid JSON as defined in the docs" do
      player = setup_player do |request|
        request.method.should eq "DELETE"

        json = ClientJSON::DeleteEnd.from_json(request.body.not_nil!)
        HTTP::Client::Response.new(201, "{\"accept\":true}")
      rescue err
        puts err.message
        body = request.body.not_nil!
        body.rewind
        puts body.to_s
        HTTP::Client::Response.new(500)
      end

      player.leave_game GladiatUr::Game.new, color: GladiatUr::Color::White,
                                             winner: GladiatUr::Color::Black
    end
  end
end
