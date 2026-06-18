package main

import (
	"battlefiled-sys/config"
	"battlefiled-sys/db"
	"battlefiled-sys/internal/nats"
	"battlefiled-sys/internal/tracking/repository"
	"battlefiled-sys/internal/tracking/service"
	"log"

	natsgo "github.com/nats-io/nats.go"
)

func main() {

	// Load configuration & db
	cfg := config.Load()

	db, err := db.Connect(cfg.DSN())
	if err != nil {
		log.Println("Database connection failed")
		log.Fatal(err)
	}

	defer db.Close()

	log.Println("Database connected")

	// NATS connection

	nc, err := natsgo.Connect(natsgo.DefaultURL)
	if err != nil {
		log.Println("NATS connection failed")
		log.Fatal(err)
	}

	defer nc.Close()

	//Reposiory
	trackingRepo := repository.NewPostgresRepository(db)

	//Service
	trackingService := service.NewTrackingService(trackingRepo)

	//Handler

	trackingHandler := nats.NewTrackingHandler(trackingService)

	//Subscribe to NATS subject
	err = nats.SubscribeTracking(nc, trackingHandler)
	if err != nil {
		log.Println("NATS subscription failed")
		log.Fatal(err)
	}

	log.Println("Subscribed to NATS subject: flight.position.updated")

	select {}
}
