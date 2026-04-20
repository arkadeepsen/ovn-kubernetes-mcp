package middleware

import (
	"context"
	"testing"
	"time"

	"github.com/modelcontextprotocol/go-sdk/mcp"
)

func TestToolTimeout(t *testing.T) {
	t.Run("applies deadline to tools/call", func(t *testing.T) {
		timeout := 200 * time.Millisecond
		m := ToolTimeout(timeout)

		var capturedCtx context.Context
		handler := m(func(ctx context.Context, method string, req mcp.Request) (mcp.Result, error) {
			capturedCtx = ctx
			return nil, nil
		})

		_, _ = handler(context.Background(), "tools/call", nil)

		deadline, ok := capturedCtx.Deadline()
		if !ok {
			t.Fatal("expected context to have a deadline for tools/call")
		}
		if time.Until(deadline) > timeout {
			t.Fatalf("deadline too far in the future: %v", time.Until(deadline))
		}
	})

	t.Run("no deadline for other methods", func(t *testing.T) {
		m := ToolTimeout(200 * time.Millisecond)

		var capturedCtx context.Context
		handler := m(func(ctx context.Context, method string, req mcp.Request) (mcp.Result, error) {
			capturedCtx = ctx
			return nil, nil
		})

		_, _ = handler(context.Background(), "initialize", nil)

		if _, ok := capturedCtx.Deadline(); ok {
			t.Fatal("expected no deadline for non-tools/call method")
		}
	})

	t.Run("timeout fires when handler is slow", func(t *testing.T) {
		m := ToolTimeout(10 * time.Millisecond)

		handler := m(func(ctx context.Context, method string, req mcp.Request) (mcp.Result, error) {
			time.Sleep(50 * time.Millisecond)
			return nil, ctx.Err()
		})

		_, err := handler(context.Background(), "tools/call", nil)
		if err != context.DeadlineExceeded {
			t.Fatalf("expected DeadlineExceeded, got: %v", err)
		}
	})

	t.Run("no timeout when handler completes in time", func(t *testing.T) {
		m := ToolTimeout(200 * time.Millisecond)

		handler := m(func(ctx context.Context, method string, req mcp.Request) (mcp.Result, error) {
			time.Sleep(5 * time.Millisecond)
			return nil, ctx.Err()
		})

		_, err := handler(context.Background(), "tools/call", nil)
		if err != nil {
			t.Fatalf("expected no error, got: %v", err)
		}
	})
}
