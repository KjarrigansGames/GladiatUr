# Based on https://pad.evilcookie.de/35KdzJ2AQDOxOfc4_zvq0w
module ClientJSON
  struct SpecialFields
    include JSON::Serializable

    property target : Int8
    property reroll : Array(Int8)
    property safe : Array(Int8)
  end

  struct Ruleset
    include JSON::Serializable

    property name : String
    property tokens_per_player : Int8
    property score_to_win : Int8
    property special_fields : SpecialFields
  end

  struct Game
    include JSON::Serializable

    property id : String
  end

  struct GameStart
    include JSON::Serializable

    property id : String
    property ruleset : Ruleset
    property turn_timeout_ms : Int32
  end

  struct Board
    include JSON::Serializable

    property black : Array(Int8)
    property white : Array(Int8)
  end

  struct Score
    include JSON::Serializable

    property black : Int8
    property white : Int8
  end

  struct PostStart
    include JSON::Serializable

    property game : GameStart
    property color : GladiatUr::Color
  end

  struct PutTurn
    include JSON::Serializable

    property game : Game
    property color : GladiatUr::Color
    property board : Board
    property score : Score
    property dice_roll : Int8
    property moveable : Array(Int8)
  end

  struct DeleteEnd
    include JSON::Serializable

    property game : Game
    property color : GladiatUr::Color
    property winner : GladiatUr::Color
  end
end
