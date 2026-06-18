package nats

import (
	"log"

	natsgo "github.com/nats-io/nats.go"
)

// SubscribeTracking lắng nghe civil aviation events từ OpenSky simulator
func SubscribeTracking(nc *natsgo.Conn, handler *TrackingHandler) error {
	_, err := nc.Subscribe("flight.position.updated", handler.HandlePositionUpdate)
	if err != nil {
		log.Printf("[subscriber] Error subscribing to flight.position.updated: %v", err)
		return err
	}
	log.Println("[subscriber] Subscribed to: flight.position.updated")
	return nil
}

// SubscribeMilitary lắng nghe military simulation events
func SubscribeMilitary(nc *natsgo.Conn, handler *MilitaryHandler) error {
	_, err := nc.Subscribe("military.position.updated", handler.HandleMilitaryUpdate)
	if err != nil {
		log.Printf("[subscriber] Error subscribing to military.position.updated: %v", err)
		return err
	}
	log.Println("[subscriber] Subscribed to: military.position.updated")
	return nil
}
