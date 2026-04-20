package middleware

import (
	"context"
	"time"

	"github.com/modelcontextprotocol/go-sdk/mcp"
)

// ToolTimeout returns an MCP receiving middleware that applies a context
// timeout to every tools/call request. This ensures all tool operations
// have a bounded execution time without requiring per-tool code.
func ToolTimeout(timeout time.Duration) mcp.Middleware {
	return func(next mcp.MethodHandler) mcp.MethodHandler {
		return func(ctx context.Context, method string, req mcp.Request) (mcp.Result, error) {
			if method != "tools/call" {
				return next(ctx, method, req)
			}

			var cancel context.CancelFunc
			ctx, cancel = context.WithTimeout(ctx, timeout)
			defer cancel()

			return next(ctx, method, req)
		}
	}
}
