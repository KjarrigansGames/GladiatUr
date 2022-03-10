module GladiatUr
  SPAWN_FIELD = 0i8
  START_AREA = [1i8, 2i8, 3i8, 4i8]
  TARGET_AREA = [13i8, 14i8]

  struct RuleSet
    property tokens_per_player : Int8 = 7i8
    property score_to_win : Int8 = 7i8

    property target_field : Int8 = 15i8
    property reroll_fields : Array(Int8) = [4i8, 8i8, 14i8]
    property safe_zone_fields : Array(Int8) = START_AREA + [8i8] + TARGET_AREA

    def combat_fields
      (1i8..@target_field).to_a - safe_zone_fields
    end

    def to_h
      {
        tokens_per_player: tokens_per_player,
        score_to_win: score_to_win,
        special_fields: {
          target: target_field,
          reroll: reroll_fields,
          safe: safe_zone_fields
        }
      }
    end
  end

  RULES = {
    "standard" => RuleSet.new
  }
end
