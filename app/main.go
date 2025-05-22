package main

import (
	"log"
	"net/http"

	"github.com/shubhambjadhavar/simple-time-service/app/handler"
)

func main() {
	mux := http.NewServeMux()
	mux.HandleFunc("/", handler.RootHandler)
	mux.HandleFunc("/health", handler.HealthHandler)
	log.Println("Service running on :8080")
	if err := http.ListenAndServe(":8080", mux); err != nil {
		log.Fatalf("Server failed: %v", err)
	}
}
