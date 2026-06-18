package main

import (
	"battlefiled-sys/config"
	"battlefiled-sys/db"
	"battlefiled-sys/internal/api"
	"battlefiled-sys/internal/hub"
	inats "battlefiled-sys/internal/nats"
	"battlefiled-sys/internal/tracking/repository"
	"battlefiled-sys/internal/tracking/service"
	"log"
	"net/http"
	"os"
	"os/signal"
	"syscall"

	natsgo "github.com/nats-io/nats.go"
)

func main() {
	// ─── Config & Database ───────────────────────────────────────
	cfg := config.Load()

	dbConn, err := db.Connect(cfg.DSN())
	if err != nil {
		log.Fatalf("[main] Database connection failed: %v", err)
	}
	defer dbConn.Close()
	log.Println("[main] Database connected")

	// ─── NATS Connection ─────────────────────────────────────────
	natsURL := getEnv("NATS_URL", natsgo.DefaultURL)
	nc, err := natsgo.Connect(natsURL)
	if err != nil {
		log.Fatalf("[main] NATS connection failed: %v", err)
	}
	defer nc.Close()
	log.Printf("[main] Connected to NATS at %s", natsURL)

	// ─── DI: Repository → Service ────────────────────────────────
	trackingRepo := repository.NewPostgresRepository(dbConn)
	trackingService := service.NewTrackingService(trackingRepo)

	// ─── WebSocket Hub ───────────────────────────────────────────
	radarHub := hub.NewHub()
	go radarHub.Run()
	log.Println("[main] WebSocket Hub started")

	// ─── NATS Handlers & Subscriptions ──────────────────────────
	// Civil Aviation: flight.position.updated
	civilHandler := inats.NewTrackingHandler(trackingService, radarHub)
	if err := inats.SubscribeTracking(nc, civilHandler); err != nil {
		log.Fatalf("[main] Civil NATS subscription failed: %v", err)
	}

	// Military: military.position.updated
	militaryHandler := inats.NewMilitaryHandler(trackingService, radarHub)
	if err := inats.SubscribeMilitary(nc, militaryHandler); err != nil {
		log.Fatalf("[main] Military NATS subscription failed: %v", err)
	}

	// ─── HTTP Server ─────────────────────────────────────────────
	httpPort := getEnv("HTTP_PORT", "8080")

	mux := http.NewServeMux()
	mux.HandleFunc("/health", api.HealthHandler)
	mux.Handle("/ws/radar", api.NewWebSocketHandler(radarHub))

	server := &http.Server{
		Addr:    ":" + httpPort,
		Handler: mux,
	}

	go func() {
		log.Printf("[main] HTTP server listening on :%s", httpPort)
		log.Printf("[main] WebSocket radar endpoint: ws://localhost:%s/ws/radar", httpPort)
		if err := server.ListenAndServe(); err != nil && err != http.ErrServerClosed {
			log.Fatalf("[main] HTTP server error: %v", err)
		}
	}()

	// ─── Graceful Shutdown ───────────────────────────────────────
	quit := make(chan os.Signal, 1)
	signal.Notify(quit, syscall.SIGINT, syscall.SIGTERM)
	<-quit

	log.Println("[main] Shutdown signal received")
	server.Close()
	log.Println("[main] Backend stopped")
}

func getEnv(key, fallback string) string {
	if v := os.Getenv(key); v != "" {
		return v
	}
	return fallback
}
