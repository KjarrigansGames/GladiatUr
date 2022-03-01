package main

import (
	"encoding/json"
	"fmt"
	"log"
	"net/http"
	"os"
)

type Data struct {
	Game     Game             `json:"game"`
	Winner   string           `json:"winner"`
	Color    string           `json:"color"`
	Board    map[string][]int `json:"board"`
	Moveable []int            `json:"moveable"`
	DiceRoll int              `json:"dice_roll"`
}

type Game struct {
	ID string `json:"id"`
}

type StartResponse struct {
	Accept bool
}

type MoveResponse struct {
	Move int
}

func pingHandler(w http.ResponseWriter, _ *http.Request) {
	w.WriteHeader(http.StatusOK)
}

func startHandler(w http.ResponseWriter, r *http.Request) {
	var data Data
	if err := json.NewDecoder(r.Body).Decode(&data); err != nil {
		log.Printf("ERROR: failed to decode data json: %s", err)
		w.WriteHeader(http.StatusBadRequest)
		return
	}

	log.Printf("INFO: started new game %s", data.Game.ID)

	var response StartResponse
	/*
		Whenever the game server sends a game invitation, it is up to you
		whether you would like to join or decline. The starter will always
		accept any new game.
	*/
	response.Accept = true

	responseBytes, err := json.Marshal(response)
	if err != nil {
		log.Printf("ERROR: failed to encode start response: %s", err)
		w.WriteHeader(http.StatusInternalServerError)
		return
	}

	w.Header().Set("Content-Type", "application/json")
	w.WriteHeader(http.StatusCreated)
	w.Write(responseBytes)
}

func moveHandler(w http.ResponseWriter, r *http.Request) {
	var data Data
	if err := json.NewDecoder(r.Body).Decode(&data); err != nil {
		log.Printf("ERROR: failed to decode data json: %s", err)
		w.WriteHeader(http.StatusBadRequest)
		return
	}

	var response MoveResponse
	/*
		This is the place where you should implement your strategy to defeat your
		opponents. For simplicity the starter will only return the first possible
		move.
	*/
	response.Move = data.Moveable[0]

	responseBytes, err := json.Marshal(response)
	if err != nil {
		log.Printf("ERROR: failed to encode move response: %s", err)
		w.WriteHeader(http.StatusInternalServerError)
		return
	}

	w.Header().Set("Content-Type", "application/json")
	w.WriteHeader(http.StatusOK)
	w.Write(responseBytes)
}

func endHandler(w http.ResponseWriter, r *http.Request) {
	var data Data
	if err := json.NewDecoder(r.Body).Decode(&data); err != nil {
		log.Printf("ERROR: failed to decode data json: %s", err)
		w.WriteHeader(http.StatusBadRequest)
		return
	}

	if data.Color == data.Winner {
		log.Printf("INFO: won game %s", data.Game.ID)
	} else {
		log.Printf("INFO: lost game %s", data.Game.ID)
	}

	w.WriteHeader(http.StatusOK)
}

func methodCheck(method string, next http.HandlerFunc) http.HandlerFunc {
	return func(w http.ResponseWriter, r *http.Request) {
		if r.Method != method {
			w.WriteHeader(http.StatusMethodNotAllowed)
			return
		}
		next(w, r)
	}
}

func main() {
	http.HandleFunc("/ping", methodCheck(http.MethodHead, pingHandler))
	http.HandleFunc("/start", methodCheck(http.MethodPost, startHandler))
	http.HandleFunc("/move", methodCheck(http.MethodPut, moveHandler))
	http.HandleFunc("/end", methodCheck(http.MethodDelete, endHandler))

	addr, port := "127.0.0.1", "8080"
	if val, ok := os.LookupEnv("BIND_ADDR"); ok {
		addr = val
	}
	if val, ok := os.LookupEnv("BIND_PORT"); ok {
		port = val
	}

	log.Printf("INFO: starting gladiatur server at http://%s:%s ...", addr, port)
	if err := http.ListenAndServe(fmt.Sprintf("%s:%s", addr, port), nil); err != nil {
		fmt.Printf("err: %s\n", err)
	}
}
