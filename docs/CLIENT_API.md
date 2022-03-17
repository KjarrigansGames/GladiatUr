# Client API

Your AI has to provide a webserver(!) responding to the following endpoints. So Request is what
you'll get and response is what you have to provide.

## HEAD /ping

A basic check if your AI is still responsive.

### Request

`None`

### Response

* **Statuscode:** 204 No Content
* **Body**: `None`

## POST /start

Once per game, the client will receive an invitation and the rules for the match. 
The client has to accept the settings before the game will start.

_HINT: The server might initiate multiple games in parallel. If your client can't handle 
multiple requests just decline the game by replying with `"accept": false`_

### Request

```json
{
  "game": {
    "id": "64c8b0f0-aa36-459d-a997-cc9e818d7b8e",
    "ruleset": {
      "name": "standard",
      "tokens_per_player": 7,
      "score_to_win": 7
      "special_fields": {
        "target": 15
        "reroll": [4,8,14],
        "safe": [1,2,3,4,8,13,14],
      },
    },
    "turn_timeout_ms": 500
  },
  "color": "white"
}
```

### Response

* **Statuscode:** 201 Created
* **Body**:
```json
{
    "accept": true
}
```

## PUT /turn

You'll reveive a lot of these every time it's (surprise) your turn. You'll reveive all the information
you need, like how does the board currently look like (your and opponents position), the dice-roll and
we even provide you with a list of valid moves. We want you to write a cool, challenging AI and not
bother to master the game(rules) before you write your first working GladitUr.

### Request

```json
{
  "game": {
    "id": "64c8b0f0-aa36-459d-a997-cc9e818d7b8e"
  },
  "color": "white",
  "board": {
    "white": [1,2,5,8],
    "black": [1,2,3]
  },
  "score": {
    "white": 3,
    "black": 4
  },
  "dice_roll": 3
  "moveable": [2,5]
}
```

### Response

* **Statuscode:** 200 OK
* **Body**:
```json
{
    "move": 1
}
```

## DELETE /end

Once the game is finished you'll receive a short information on who won. It's pretty scarce in terms
of metrics but that is on purpose. As beginner you probably only want to know if you've won or lost
BUT if you want the full-scale meta-data to analyse and optimize your AI then you can fetch extensive
data from the server(archive) containing a Replay-Log (see below how to read it), scores and even
dice-roll statistics.

### Request

```json
{
  "game": {
    "id": "64c8b0f0-aa36-459d-a997-cc9e818d7b8e"
  },
  "color": "white",
  "winner": "white"
}
```

### Response

* **Statuscode:** 204 No Content
* **Body**: `None`

### AI-Starter-Kits

`starters/` contain multiple directories each named after the language it's written in. It shall
help diving directly into game AI development, in the language of your choice, withouth too much
necessary knowledge about how everything works. Ideally it's a dependency free script with all
necessary endpoints, data and usefull comments to get a newbie started. These starters are maintained
by the  core-team:

* Crystal (Holger)
* Ruby (Holger)
* Golang (Markus)
* Python (Markus)

If you are missing your language of choice consider submitting a PR!
