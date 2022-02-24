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
	Winner   bool             `json:"winner"`
	Color    string           `json:"color"`
	Board    map[string][]int `json:"board"`
	Moveable []int            `json:"moveable"`
}

type Game struct {
	ID string `json:"id"`
}

func pingHandler(w http.ResponseWriter, _ *http.Request) {
	w.WriteHeader(http.StatusOK)
}

func startHandler(w http.ResponseWriter, r *http.Request) {
	var data Data
	if err := json.NewDecoder(r.Body).Decode(&data); err != nil {
		err = fmt.Errorf("ERROR: failed to decode data json, %w", err)
		log.Printf(err.Error())
		w.WriteHeader(http.StatusBadRequest)
		w.Write([]byte(err.Error()))
		return
	}

	log.Printf("INFO: started new game %s", data.Game.ID)

	w.WriteHeader(http.StatusOK)
}

func endHandler(w http.ResponseWriter, r *http.Request) {
	var data Data
	if err := json.NewDecoder(r.Body).Decode(&data); err != nil {
		err = fmt.Errorf("ERROR: failed to decode data json, %w", err)
		log.Printf(err.Error())
		w.WriteHeader(http.StatusBadRequest)
		w.Write([]byte(err.Error()))
		return
	}

	if data.Winner {
		log.Printf("INFO: won game %s", data.Game.ID)
	} else {
		log.Printf("INFO: lost game %s", data.Game.ID)
	}

	w.WriteHeader(http.StatusOK)
}

func moveHandler(w http.ResponseWriter, r *http.Request) {
	var data Data
	if err := json.NewDecoder(r.Body).Decode(&data); err != nil {
		err = fmt.Errorf("ERROR: failed to decode data json, %w", err)
		log.Printf(err.Error())
		w.WriteHeader(http.StatusBadRequest)
		w.Write([]byte(err.Error()))
		return
	}

	var response map[string]int
	response["move"] = data.Moveable[0]

	w.Header().Set("Content-Type", "application/json")
	if err := json.NewEncoder(w).Encode(response); err != nil {
		err = fmt.Errorf("ERROR: failed to encode move response, %w", err)
		log.Printf(err.Error())
		w.WriteHeader(http.StatusInternalServerError)
		w.Write([]byte(err.Error()))
		return
	}
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
