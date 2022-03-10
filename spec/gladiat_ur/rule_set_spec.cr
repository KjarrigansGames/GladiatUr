require "../spec_helper"

describe GladiatUr::RuleSet do
  it "should provide a standard rule_set" do
    GladiatUr::RULES.keys.should contain("standard")

    standard = GladiatUr::RULES["standard"]
    standard.should be_a GladiatUr::RuleSet
    standard.tokens_per_player.should eq 7
    standard.score_to_win.should eq 7
    standard.target_field.should eq 15
    standard.reroll_fields.should eq [4, 8, 14]
    standard.safe_zone_fields.should eq [1, 2, 3, 4, 8, 13, 14]
    standard.combat_fields.should eq [5, 6, 7, 9, 10, 11, 12]
  end
end
