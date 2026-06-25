package main

import (
	"context"
	"database/sql"
	"log"
	"os"
	"os/signal"
	"simulator/military/engine"
	"simulator/military/publisher"
	"simulator/opensky/service"
	"sync"
	"syscall"

	_ "github.com/lib/pq"
	"github.com/nats-io/nats.go"
)

func main() {
	//NATS Connection
	natsURL := getEnv("NATS_URL", nats.DefaultURL)
	nc, err := nats.Connect(natsURL)
	if err != nil {
		log.Fatalf("[main] NATS connection failed: %v", err)
	}
	defer nc.Close()
	log.Printf("[main] Connected to NATS at %s", natsURL)

	// Context
	ctx, cancel := context.WithCancel(context.Background())
	defer cancel()

	var wg sync.WaitGroup

	// DB Connection
	dbURL := getEnv("DATABASE_URL", "postgres://admin:postgres@localhost:5432/battlefield?sslmode=disable")
	db, err := sql.Open("postgres", dbURL)
	if err != nil {
		log.Fatalf("[main] DB connection failed: %v", err)
	}
	defer db.Close()

	if err := db.Ping(); err != nil {
		log.Fatalf("[main] DB ping failed: %v", err)
	}
	log.Printf("[main] Connected to Postgres")

	// Historical Poller (replaces OpenSky)
	wg.Add(1)
	go func() {
		defer wg.Done()
		log.Println("(Historical Poller)")

		poller := service.NewHistoricalPoller(db, nc)
		poller.Run(ctx)
	}()

	// Military Simulation Engines
	militaryPub := publisher.NewNatsPublisher(nc)

	engines := []engine.Engine{
		engine.NewUAVEngine(militaryPub),
		engine.NewMissileEngine(militaryPub),
		engine.NewThreatEngine(militaryPub),
	}

	for _, eng := range engines {
		wg.Add(1)
		go func(e engine.Engine) {
			defer wg.Done()
			e.Run(ctx)
		}(eng)
	}

	// Graceful shutdown on SIGINT/SIGTERM
	quit := make(chan os.Signal, 1)
	signal.Notify(quit, syscall.SIGINT, syscall.SIGTERM)
	<-quit
	cancel()
	wg.Wait()
	log.Println("[main] All goroutines stopped.")
}

func getEnv(key, fallback string) string {
	if v := os.Getenv(key); v != "" {
		return v
	}
	return fallback
}
