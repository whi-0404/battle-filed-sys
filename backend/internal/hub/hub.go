package hub

import (
	"encoding/json"
	"log"
	"sync"
	"time"

	"github.com/gorilla/websocket"
)

const (
	broadcastInterval = 100 * time.Millisecond // Snapshot mỗi 100ms
	writeTimeout      = 10 * time.Second
	pongTimeout       = 60 * time.Second
	pingInterval      = 30 * time.Second
	maxMessageSize    = 512 * 1024 // 512KB
)

// Client đại diện cho một WebSocket connection
type Client struct {
	hub  *Hub
	conn *websocket.Conn
	send chan []byte
}

// Hub quản lý tất cả WebSocket clients và state của radar
type Hub struct {
	// WebSocket client management
	clients    map[*Client]bool
	register   chan *Client
	unregister chan *Client
	broadcast  chan []byte

	// Shared radar state: icao24/id → RadarObject
	mu      sync.RWMutex
	objects map[string]RadarObject
}

// NewHub tạo Hub mới
func NewHub() *Hub {
	return &Hub{
		clients:    make(map[*Client]bool),
		register:   make(chan *Client, 64),
		unregister: make(chan *Client, 64),
		broadcast:  make(chan []byte, 256),
		objects:    make(map[string]RadarObject),
	}
}

// UpsertObject cập nhật hoặc thêm mới một đối tượng trên radar
// Thread-safe, được gọi từ NATS handlers
func (h *Hub) UpsertObject(obj RadarObject) {
	h.mu.Lock()
	h.objects[obj.ID] = obj
	h.mu.Unlock()
}

// DeleteObject xóa một đối tượng (vd: missile đã impact)
func (h *Hub) DeleteObject(id string) {
	h.mu.Lock()
	delete(h.objects, id)
	h.mu.Unlock()
}

// Run là event loop chính của Hub – phải chạy trong goroutine riêng
func (h *Hub) Run() {
	broadcastTicker := time.NewTicker(broadcastInterval)
	defer broadcastTicker.Stop()

	log.Printf("[hub] Started – broadcasting every %v", broadcastInterval)

	for {
		select {
		// Client mới kết nối
		case client := <-h.register:
			h.clients[client] = true
			log.Printf("[hub] Client registered. Total: %d", len(h.clients))
			// Gửi ngay snapshot hiện tại cho client mới
			h.sendSnapshotToClient(client)

		// Client disconnect
		case client := <-h.unregister:
			if _, ok := h.clients[client]; ok {
				delete(h.clients, client)
				close(client.send)
				log.Printf("[hub] Client unregistered. Total: %d", len(h.clients))
			}

		// Broadcast message từ bên ngoài (không dùng nhiều, snapshot tự gen)
		case msg := <-h.broadcast:
			for client := range h.clients {
				select {
				case client.send <- msg:
				default:
					// Buffer đầy → drop client
					close(client.send)
					delete(h.clients, client)
				}
			}

		// Định kỳ build và broadcast RadarSnapshot
		case <-broadcastTicker.C:
			if len(h.clients) == 0 {
				continue
			}
			h.broadcastSnapshot()
		}
	}
}

// broadcastSnapshot build snapshot và gửi đến tất cả clients
func (h *Hub) broadcastSnapshot() {
	h.mu.RLock()
	snapshot := BuildSnapshot(h.objects)
	h.mu.RUnlock()

	data, err := json.Marshal(snapshot)
	if err != nil {
		log.Printf("[hub] Failed to marshal snapshot: %v", err)
		return
	}

	dead := make([]*Client, 0)
	for client := range h.clients {
		select {
		case client.send <- data:
		default:
			dead = append(dead, client)
		}
	}

	// Cleanup dead clients
	for _, c := range dead {
		close(c.send)
		delete(h.clients, c)
		log.Printf("[hub] Dropped slow client. Remaining: %d", len(h.clients))
	}
}

// sendSnapshotToClient gửi snapshot hiện tại đến một client cụ thể
func (h *Hub) sendSnapshotToClient(client *Client) {
	h.mu.RLock()
	snapshot := BuildSnapshot(h.objects)
	h.mu.RUnlock()

	data, err := json.Marshal(snapshot)
	if err != nil {
		return
	}

	select {
	case client.send <- data:
	default:
	}
}

// RegisterClient đăng ký client mới và bắt đầu read/write pumps
func (h *Hub) RegisterClient(conn *websocket.Conn) {
	client := &Client{
		hub:  h,
		conn: conn,
		send: make(chan []byte, 256),
	}
	h.register <- client

	go client.writePump()
	go client.readPump()
}

// ─── Client pumps ────────────────────────────────────────────────

// readPump đọc messages từ client (chủ yếu để detect disconnect)
func (c *Client) readPump() {
	defer func() {
		c.hub.unregister <- c
		c.conn.Close()
	}()

	c.conn.SetReadLimit(maxMessageSize)
	c.conn.SetReadDeadline(time.Now().Add(pongTimeout))
	c.conn.SetPongHandler(func(string) error {
		c.conn.SetReadDeadline(time.Now().Add(pongTimeout))
		return nil
	})

	for {
		_, _, err := c.conn.ReadMessage()
		if err != nil {
			if websocket.IsUnexpectedCloseError(err,
				websocket.CloseGoingAway, websocket.CloseAbnormalClosure) {
				log.Printf("[hub] client read error: %v", err)
			}
			break
		}
	}
}

// writePump gửi messages từ send channel đến WebSocket
func (c *Client) writePump() {
	pingTicker := time.NewTicker(pingInterval)
	defer func() {
		pingTicker.Stop()
		c.conn.Close()
	}()

	for {
		select {
		case msg, ok := <-c.send:
			c.conn.SetWriteDeadline(time.Now().Add(writeTimeout))
			if !ok {
				c.conn.WriteMessage(websocket.CloseMessage, []byte{})
				return
			}
			if err := c.conn.WriteMessage(websocket.TextMessage, msg); err != nil {
				log.Printf("[hub] client write error: %v", err)
				return
			}

		case <-pingTicker.C:
			c.conn.SetWriteDeadline(time.Now().Add(writeTimeout))
			if err := c.conn.WriteMessage(websocket.PingMessage, nil); err != nil {
				return
			}
		}
	}
}
