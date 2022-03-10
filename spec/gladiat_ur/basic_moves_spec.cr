require "../spec_helper"

describe "Basic Moves" do
  it "W0-1" do
    game = setup_game { 0i8 }
    next_player = game.turn(GladiatUr::Color::White, 1)
    game.turn_log.should eq ["W0-1"]

    game.board[GladiatUr::Color::White].should eq [1]
    game.board[GladiatUr::Color::Black].should be_empty
    next_player.should eq GladiatUr::Color::Black
  end

  it "W2-4R" do
    game = setup_game([2i8]) { 2i8 }
    next_player = game.turn(GladiatUr::Color::White, 2)
    game.turn_log.should eq ["W2-4R"]

    game.board[GladiatUr::Color::White].should eq [4]
    game.board[GladiatUr::Color::Black].should be_empty
    next_player.should eq GladiatUr::Color::White
  end

  it "Wx4-5" do
    game = setup_game([4i8], [5i8]) { 4i8 }
    next_player = game.turn(GladiatUr::Color::White, 1)
    game.turn_log.should eq ["Wx4-5"]

    game.board[GladiatUr::Color::White].should eq [5]
    game.board[GladiatUr::Color::Black].should be_empty
    next_player.should eq GladiatUr::Color::Black
  end

  it "W12-15+" do
    game = setup_game([12i8], score_white: 6i8) {12i8 }
    next_player = game.turn(GladiatUr::Color::White, 3)
    game.turn_log.should eq ["W12-15+"]

    game.board[GladiatUr::Color::White].should be_empty
    game.board[GladiatUr::Color::Black].should be_empty
    game.score[GladiatUr::Color::White].should eq 7
    next_player.should eq GladiatUr::Color::Black
  end

  describe "W-" do
    it "skips when rolled 0" do
      game = setup_game {0i8 }
      next_player = game.turn(GladiatUr::Color::White, 0)
      game.turn_log.should eq ["W-"]

      game.board[GladiatUr::Color::White].should be_empty
      game.board[GladiatUr::Color::Black].should be_empty
      next_player.should eq GladiatUr::Color::Black
    end

    it "skips when all fields are blocked by yourself" do
      game = setup_game([12i8, 14i8], score_white: 5i8) {0i8 }
      next_player = game.turn(GladiatUr::Color::White, 2)
      game.turn_log.should eq ["W-"]

      game.board[GladiatUr::Color::White].should eq [12i8, 14i8]
      game.board[GladiatUr::Color::Black].should be_empty
      next_player.should eq GladiatUr::Color::Black
    end

    it "skips when the enemy is on the safe-spot" do
      game = setup_game([7i8], [8i8], score_white: 6i8) {0i8 }
      next_player = game.turn(GladiatUr::Color::White, 1)
      game.turn_log.should eq ["W-"]

      game.board[GladiatUr::Color::White].should eq [7i8]
      game.board[GladiatUr::Color::Black].should eq [8i8]
      next_player.should eq GladiatUr::Color::Black
    end

    it "skips when you can't reach the target" do
      game = setup_game([14i8], score_white: 6i8) {14i8 }
      next_player = game.turn(GladiatUr::Color::White, 2)
      game.turn_log.should eq ["W-"]

      game.board[GladiatUr::Color::White].should eq [14i8]
      game.board[GladiatUr::Color::Black].should be_empty
      next_player.should eq GladiatUr::Color::Black
    end
  end
end
