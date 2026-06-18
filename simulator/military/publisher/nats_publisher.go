package publisher

import (
	"encoding/json"
	"log"
	"simulator/military/model"

	"github.com/nats-io/nats.go"
)

const SubjectMilitaryPosition = "military.position.updated"

// NatsPublisher publish military events lên NATS
type NatsPublisher struct {
	nc *nats.Conn
}

func NewNatsPublisher(nc *nats.Conn) *NatsPublisher {
	return &NatsPublisher{nc: nc}
}

// Publish gửi một MilitaryEvent lên NATS subject
func (p *NatsPublisher) Publish(event model.MilitaryEvent) {
	data, err := json.Marshal(event)
	if err != nil {
		log.Printf("[publisher] marshal error: %v", err)
		return
	}

	if err := p.nc.Publish(SubjectMilitaryPosition, data); err != nil {
		log.Printf("[publisher] publish error for %s/%s: %v", event.Type, event.ID, err)
	}
}
