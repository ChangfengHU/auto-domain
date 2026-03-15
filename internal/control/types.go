package control

import "tunneling/internal/protocol"

type Tunnel struct {
	ID         string         `json:"id"`
	Name       string         `json:"name"`
	Token      string         `json:"token,omitempty"`
	OwnerID    string         `json:"owner_id,omitempty"`
	ProjectKey string         `json:"project_key,omitempty"`
	ClientIP   string         `json:"client_ip,omitempty"`
	OSType     string         `json:"os_type,omitempty"`
	Metadata   map[string]any `json:"metadata,omitempty"`
	Status     string         `json:"status,omitempty"`
	CreatedAt  string         `json:"created_at,omitempty"`
	UpdatedAt  string         `json:"updated_at,omitempty"`
}

type Route struct {
	ID        string `json:"id,omitempty"`
	TunnelID  string `json:"tunnel_id"`
	Hostname  string `json:"hostname"`
	Target    string `json:"target"`
	Enabled   bool   `json:"is_enabled"`
	CreatedAt string `json:"created_at,omitempty"`
	UpdatedAt string `json:"updated_at,omitempty"`
}

type RegisterSessionRequest struct {
	UserID      string         `json:"user_id"`
	Project     string         `json:"project"`
	Target      string         `json:"target"`
	BaseDomain  string         `json:"base_domain"`
	Subdomain   string         `json:"subdomain,omitempty"`
	TunnelID    string         `json:"tunnel_id,omitempty"`
	TunnelToken string         `json:"tunnel_token,omitempty"`
	Enabled     *bool          `json:"enabled,omitempty"`
	AdminKey    string         `json:"admin_key,omitempty"`
	ClientIP    string         `json:"client_ip,omitempty"`
	OSType      string         `json:"os_type,omitempty"`
	Metadata    map[string]any `json:"metadata,omitempty"`
}

type AgentRoutesResponse struct {
	TunnelID string           `json:"tunnel_id"`
	Routes   []protocol.Route `json:"routes"`
}
