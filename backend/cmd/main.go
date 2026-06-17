package main

import (
	"battlefiled-sys/config"
	"battlefiled-sys/db"
	"log"
)

func main() {

	cfg := config.Load()

	db, err := db.Connect(cfg.DSN())
	if err != nil {
		log.Println("Database connection failed")
		log.Fatal(err)
	}

	defer db.Close()

	log.Println("Database connected")

	// start http server
	// start websocket
	// start nats subscriber

	select {}
}
