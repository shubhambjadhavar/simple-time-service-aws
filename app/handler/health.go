package handler

import (
	"net/http"
)

type HealthResponse struct {
	Status string `json:"status"`
}

func HealthHandler(responseWriter http.ResponseWriter, request *http.Request) {
	if request.Method != http.MethodGet {
		http.Error(responseWriter, "Method Not Allowed", http.StatusMethodNotAllowed)
		return
	}

	if request.URL.Path != "/health" {
		http.NotFound(responseWriter, request)
		return
	}

	payload := HealthResponse{
		Status: "ok",
	}
	respondJSON(responseWriter, http.StatusOK, payload)
}
