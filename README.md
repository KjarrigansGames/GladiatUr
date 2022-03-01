# GladiatUr

An AI-Competition in the spirit of BattleSnake but playing the Royal Game of Ur against each other.
So far the game works with basic-rules. There is a game-server available at http://gladiat-ur.kjarrigan.de
if you want to jumpstart developing an AI with one of the starter kits. Otherwise check the `Usage`
section below on how to operate your personal setup.

---
**Table of Contents**

1. [Getting Started](#getting-started)
   1. [Developing your own AI](#developing-your-own-ai)
   2. [Let your AI compete against someone else](#let-your-ai-compete-against-someone-else)
2. [Self-Hosted GameServer](#self-hosted-gameserver)
3. [Development](#development)
   1. [AI-Starter Kits](#ai-starter-kits)
4. [FAQ](#faq)
4. [Core Team](#core-team)
---

## Getting Started

If you want to develop your own AI and participate in the competition checkout our `starters/`. These
are available in multiple languages but don't worry if you favorite language is not (yet) available.
You can particiapte with basically every language as long as it can handle json and http-requests.

### Developing your own AI

Your AI has to provide a webserver responding to the following endpoints

#### HEAD /ping

A basic check if your AI is still responsive.

#### POST /new

A new game is triggered and you receive a game-UUID to setup your AI. Reply with `{"accept":"true"}`
if you want to run (another) game. Multiple games are possible in parallel each identified by the
UUID. If you can't or don't want to run multiple games just return `{"accept":"false"}`

`TODO Sample JSON`

#### PUT /turn

You'll reveive a lot of these every time it's (surprise) your turn. You'll reveive all the information
you need, like how does the board currently look like (your and opponents position), the dice-roll and
we even provide you with a list of valid moves. We want you to write a cool, challenging AI and not
bother to master the game(rules) before you write your first working GladitUr.

`TODO Sample JSON`

#### DELETE /end

Once the game is finished you'll receive a short information on who won. It's pretty scarce in terms
of metrics but that is on purpose. As beginner you probably only want to know if you've won or lost
BUT if you want the full-scale meta-data to analyse and optimize your AI then you can fetch extensive
data from the server(archive) containing a Replay-Log (see below how to read it), scores and even
dice-roll statistics.

`TODO Sample JSON`

### Let your AI compete against someone else

The GameServer connects to your AI via HTTP-Requests (not the other way around) so it has to be
reachable via WWW (in self-hosted setups localhost or LAN might work as well). Once your AI is ready
you can register a your AI and start playing.

#### Register your AI

`TODO`

#### Play a new Game

`TODO`

```bash
$ curl -XPOST gladiat-ur.kjarrigan.de/game -d '{"players": [{"name":"MyAI", "url":"http://example.com:8080/foo","secret":"MYPASSWORD"},{"name":"MyAIAgain", "url":"http://example.com:8080/foo","secret":"MYPASSWORD"}]}'

{ "game": { "id": "12345" }, "winner": "white" }

# Get the full replay-log and some more meta-data
$ curl gladiat-ur.kjarrigan.de/game/12345
```

## Self-Hosted GameServer

### From Source

* Install crystallang (v1.3.2+)
* git clone git@github.com:KjarrigansGames/GladiatUr.git
* shards install
* crystal build exe/server --release

### Pre-Built

* Goto https://github.com/KjarrigansGames/GladiatUr/releases
* Download a binary (currently statically linked, linux-only)

### Docker

`Not yet available`

## Development

### GameServer

Is currently located in `exe/` and only contains non-game-logic API endpoints. It's written in
Crystal.

### GameLogic

Is located in `src/` and also written in Crystal

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

## FAQ

### How did you come up with the idea?

Recently we particapted in another Godot Wild Jam and build our version of the Royal Game of Ur.
Part of that was to setup some (basic) AI you can play against. We figured, that although the gamegit dif
rules are pretty simple, there is actually quite some room strategy. Since we have participated in
BattleSnake a couple of times we came to the conclusion that it actually

### It feels a lot like BattleSnake?

Not really a question but yes the base concept on how the AI-API works is adapted from BattleSnake
because we really liked the concept and how easily you can start with any language of your choice.

### Will there be other game modes / rules?

Maybe. We've some ideas on how to tweak the game to provide additional challenges but let's flesh
out the base-game first and suppress the feature-creep as long as possible.

### I found a bug / I want to work on this?

You're welcome to open issues and/or pushing Pull Requests. We'll try to reply within a reasonable
timeframe. You probably already know the drill but for completeness sake:

1. Fork it (<https://github.com/KjarrigansGames/GladiatUr/fork>)
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create a new Pull Request

## Core Team

- [Holger Arndt](https://github.com/Kjarrigan)
- [Markus Freitag](https://github.com/MarkusFreitag)
