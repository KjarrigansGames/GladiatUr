import logging
import os
from flask import Flask, request, make_response

app = Flask(__name__)

@app.route("/ping", methods=["HEAD"])
def handle_ping():
    return make_response("", 200)


@app.route("/start", methods=["POST"])
def handle_start():
    data = request.get_json()
    game_id = data["game"]["id"]
    logging.info(f"started new game {game_id}")
    return make_response("", 200)


@app.route("/move", methods=["PUT"])
def handle_move():
    data = request.get_json()
    return make_response(data["moveable"][0], 200)


@app.route("/end", methods=["DELETE"])
def handle_end():
    data = request.get_json()
    game_id = data["game"]["id"]
    if data["winner"]:
        logging.info(f"won game {game_id}")
    else:
        logging.info(f"lost game {game_id}")
    return make_response("", 200)


if __name__ == "__main__":
    logging.getLogger("werkzeug").setLevel(logging.ERROR)
    logging.basicConfig(level=logging.INFO)

    addr = os.environ.get("BIND_ADDR", "127.0.0.1")
    port = int(os.environ.get("BIND_PORT", "8080"))

    print(f"starting gladiatur server at http://{addr}:{port} ...\n")
    app.run(host=addr, port=port)
