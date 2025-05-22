package handler

import (
	"net/http"
	"time"
)

type RootResponse struct {
	Timestamp string `json:"timestamp"`
	IP        string `json:"ip"`
}

func RootHandler(responseWriter http.ResponseWriter, request *http.Request) {
	if request.Method != http.MethodGet {
		http.Error(responseWriter, "Method Not Allowed", http.StatusMethodNotAllowed)
		return
	}

	if request.URL.Path != "/" {
		http.NotFound(responseWriter, request)
		return
	}

	ip := getVisitorIP(request)
	payload := RootResponse{
		Timestamp: time.Now().UTC().Format(time.RFC3339),
		IP:        ip,
	}
	respondJSON(responseWriter, http.StatusOK, payload)
}
