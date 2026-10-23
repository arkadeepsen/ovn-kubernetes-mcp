// SPDX-FileCopyrightText: Copyright The OVN-Kubernetes-MCP Contributors
// SPDX-License-Identifier: Apache-2.0

package mcp

import (
	"fmt"
	"regexp"
	"strings"

	"github.com/ovn-kubernetes/ovn-kubernetes-mcp/pkg/utils"
	"github.com/ovn-kubernetes/ovn-kubernetes-mcp/pkg/utils/commandbuilder"
)

var interfaceNamePattern = regexp.MustCompile(`^[a-zA-Z0-9][a-zA-Z0-9._-]*$`)

// validateInterface validates a network interface name for security and correctness.
func validateInterface(iface string) error {
	if iface == "" {
		return nil
	}
	if iface == "any" {
		return nil
	}
	if len(iface) > 15 {
		return fmt.Errorf("interface name too long: %s", iface)
	}
	if !interfaceNamePattern.MatchString(iface) {
		return fmt.Errorf("invalid interface name: %s", iface)
	}
	return nil
}

// validatePacketFilter validates a packet filter expression for security.
func validatePacketFilter(filter string) error {
	if len(filter) > 1024 {
		return fmt.Errorf("packet filter too long (max 1024 characters)")
	}
	// tcpdump and pwru parse an argument starting with '-' as a command-line
	// option (e.g. -w or --output-file), never as a filter expression.
	if strings.HasPrefix(strings.TrimSpace(filter), "-") {
		return fmt.Errorf("invalid packet filter: must not start with '-'")
	}
	return utils.ValidateSafeString(filter, "packet filter", true, utils.ShellMetaCharactersTypeDisallowSpecialCharacters)
}

// addPacketFilter appends the filter after a "--" end-of-options marker so the
// tool can never interpret it as an option.
func addPacketFilter(cmd *commandbuilder.CommandBuilder, filter string) {
	cmd.AddIfNotEmpty(filter, "--", filter)
}

// validateIntMax checks if a value exceeds the maximum or is negative and returns an error if it does
func validateIntMax(value, max int, fieldName, unit string) error {
	if value < 0 {
		return fmt.Errorf("%s cannot be negative", fieldName)
	}
	if value > max {
		if unit != "" {
			return fmt.Errorf("%s cannot exceed %d %s", fieldName, max, unit)
		}
		return fmt.Errorf("%s cannot exceed %d", fieldName, max)
	}
	return nil
}
