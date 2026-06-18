package main

import (
	"log"
	"os"
	"simulator/opensky/service"
	"time"

	"github.com/nats-io/nats.go"
)

func main() {

	nc, err := nats.Connect(nats.DefaultURL)
	if err != nil {
		log.Println("NATS connection failed")
		log.Fatal(err)
	}

	defer nc.Close()

	log.Println("NATS connected successfully")

	username := os.Getenv("OPENSKY_USERNAME")
	password := os.Getenv("OPENSKY_PASSWORD")

	client := service.NewOpenSkyClient(
		username,
		password,
		nc,
	)

	ticker := time.NewTicker(3 * time.Second)

	for range ticker.C {
		log.Println("Polling OpenSky API...")
		client.PollOpenSky()
	}
}
