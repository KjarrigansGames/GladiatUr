require "../spec_helper"

describe "Advances Moves" do
  # https://github.com/KjarrigansGames/GladiatUr/pull/5#issuecomment-1064455936
  #   dice roll: 2
  #   moveable: 6, 10
  #   my pieces: 2, 6, 10
  #   opponent pieces: 2, 4, 1, 5
  it "should have fixed Bug #5" do
    game = setup_game [2i8, 6i8, 10i8], [2i8, 4i8, 1i8, 5i8] do |valid_moves|
      valid_moves.should eq [2, 6, 10]
      2i8
    end

    next_player = game.turn(GladiatUr::Color::White, 2)
    game.turn_log.should eq ["W2-4R"]

    game.board[GladiatUr::Color::White].should eq [4, 6, 10]
    game.board[GladiatUr::Color::Black].should eq [2, 4, 1, 5]
    next_player.should eq GladiatUr::Color::White
  end
end
