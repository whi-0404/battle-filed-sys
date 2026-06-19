package main

import (
	"context"
	"log"
	"os"
	"os/signal"
	"simulator/military/engine"
	"simulator/military/publisher"
	"simulator/opensky/service"
	"sync"
	"syscall"
	"time"

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

	// OpenSky
	wg.Add(1)
	go func() {
		defer wg.Done()
		log.Println("(OpenSky poller)")

		username := os.Getenv("OPENSKY_USERNAME")
		password := os.Getenv("OPENSKY_PASSWORD")

		civilClient := service.NewOpenSkyClient(username, password, nc)

		ticker := time.NewTicker(3 * time.Second)
		defer ticker.Stop()

		for {
			select {
			case <-ctx.Done():
				log.Println("[civil-layer] Shutting down")
				return
			case <-ticker.C:
				log.Println("[civil-layer] Polling OpenSky API...")
				civilClient.PollOpenSky()
			}
		}
	}()

	// Military Simulation (UAV/Missile/Threat)
	militaryPub := publisher.NewNatsPublisher(nc)

	// UAV Engine
	wg.Add(1)
	go func() {
		defer wg.Done()
		uavEngine := engine.NewUAVEngine(militaryPub)
		uavEngine.Run(ctx)
	}()

	// Missile Engine
	wg.Add(1)
	go func() {
		defer wg.Done()
		missileEngine := engine.NewMissileEngine(militaryPub)
		missileEngine.Run(ctx)
	}()

	// Threat Engine
	wg.Add(1)
	go func() {
		defer wg.Done()
		threatEngine := engine.NewThreatEngine(militaryPub)
		threatEngine.Run(ctx)
	}()

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
