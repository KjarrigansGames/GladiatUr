module GladiatUr
  # Standard Rules:
  # - 2 Players
  # - 7 Token per Player
  # - Turn based
  # - Movement determined by 4d2 (ranging from 0-4, 0 -> turn wasted)
  # - First to bring 7 Stones Home wins
  # - Home has to be reached with an exact movement
  # - The board constinsts of 3 areas, a personal are per player and a shared zone were you can
  #   actively interact with the opponent (kicking, blocking)
  # - 5 Special fields that trigger another turn and prevent enemie actions
  # - only one Token per field
  SPAWN_FIELD = 0i8
  START_AREA = [1i8, 2i8, 3i8, 4i8]
  TARGET_AREA = [13i8, 14i8]

  struct RuleSet
    property name = "standard"
    property tokens_per_player : Int8 = 7i8
    property score_to_win : Int8 = 7i8

    property target_field : Int8 = 15i8
    property reroll_fields : Array(Int8) = [4i8, 8i8, 14i8]
    property safe_zone_fields : Array(Int8) = START_AREA + [8i8] + TARGET_AREA

    def combat_fields
      (1i8..@target_field - 1).to_a - safe_zone_fields
    end

    def to_h
      {
        name: name,
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
