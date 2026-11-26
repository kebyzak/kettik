// Package web holds the JSON helpers every handler uses.
package web

import (
	"encoding/json"
	"log"
	"net/http"
)

func ReadJSON(w http.ResponseWriter, r *http.Request, v any) bool {
	r.Body = http.MaxBytesReader(w, r.Body, 4<<10)
	if err := json.NewDecoder(r.Body).Decode(v); err != nil {
		Fail(w, http.StatusBadRequest, "bad_json", nil)
		return false
	}
	return true
}

func WriteJSON(w http.ResponseWriter, status int, v any) {
	w.Header().Set("Content-Type", "application/json")
	w.WriteHeader(status)
	_ = json.NewEncoder(w).Encode(v)
}

// Fail answers {"error": reason, ...extra}.
func Fail(w http.ResponseWriter, status int, reason string, extra map[string]any) {
	body := map[string]any{"error": reason}
	for k, v := range extra {
		body[k] = v
	}
	WriteJSON(w, status, body)
}

func Internal(w http.ResponseWriter, err error) {
	log.Printf("internal: %v", err)
	Fail(w, http.StatusInternalServerError, "internal", nil)
}
