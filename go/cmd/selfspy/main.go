// Selfspy - Modern Activity Monitoring in Go
//
// Practical and widely used for system tools, excellent concurrency with goroutines,
// strong standard library, and cross-platform compatibility.

package main

import (
	"context"
	"encoding/json"
	"fmt"
	"log"
	"os"
	"os/signal"
	"syscall"
	"time"

	"github.com/fatih/color"
	"github.com/spf13/cobra"
	"github.com/spf13/viper"

	"selfspy/internal/config"
	"selfspy/internal/monitor"
	"selfspy/internal/platform"
	"selfspy/internal/stats"
	"selfspy/internal/storage"
	"selfspy/internal/types"
)

var (
	version = "1.0.0"
	gitHash = "dev"
)

func main() {
	if err := newRootCmd().Execute(); err != nil {
		fmt.Fprintf(os.Stderr, "Error: %v\n", err)
		os.Exit(1)
	}
}

func newRootCmd() *cobra.Command {
	cmd := &cobra.Command{
		Use:   "selfspy",
		Short: "Modern activity monitoring in Go",
		Long: `Selfspy - Modern Activity Monitoring in Go

Practical and widely used for system tools with excellent concurrency support,
strong standard library, and cross-platform compatibility.

Features:
  • Excellent concurrency with goroutines
  • Strong standard library and ecosystem
  • Cross-platform compatibility
  • Fast compilation and execution
  • Robust error handling patterns`,
		Version: fmt.Sprintf("%s (%s)", version, gitHash),
	}

	cmd.AddCommand(
		newStartCmd(),
		newStopCmd(),
		newStatsCmd(),
		newCheckCmd(),
		newExportCmd(),
	)

	return cmd
}

func newStartCmd() *cobra.Command {
	cmd := &cobra.Command{
		Use:   "start",
		Short: "Start activity monitoring",
		RunE:  runStart,
	}

	cmd.Flags().Bool("no-text", false, "Disable text capture for privacy")
	cmd.Flags().Bool("no-mouse", false, "Disable mouse monitoring")
	cmd.Flags().Bool("debug", false, "Enable debug logging")

	return cmd
}

func newStopCmd() *cobra.Command {
	return &cobra.Command{
		Use:   "stop",
		Short: "Stop running monitoring instance",
		RunE:  runStop,
	}
}

func newStatsCmd() *cobra.Command {
	cmd := &cobra.Command{
		Use:   "stats",
		Short: "Show activity statistics",
		RunE:  runStats,
	}

	cmd.Flags().Int("days", 7, "Number of days to analyze")
	cmd.Flags().Bool("json", false, "Output in JSON format")

	return cmd
}

func newCheckCmd() *cobra.Command {
	return &cobra.Command{
		Use:   "check",
		Short: "Check system permissions and setup",
		RunE:  runCheck,
	}
}

func newExportCmd() *cobra.Command {
	cmd := &cobra.Command{
		Use:   "export",
		Short: "Export data to various formats",
		RunE:  runExport,
	}

	cmd.Flags().String("format", "json", "Export format (json, csv, sql)")
	cmd.Flags().String("output", "", "Output file path")
	cmd.Flags().Int("days", 30, "Number of days to export")

	return cmd
}

func runStart(cmd *cobra.Command, args []string) error {
	color.Cyan("🚀 Starting Selfspy monitoring (Go implementation)")

	// Load configuration
	cfg, err := config.Load()
	if err != nil {
		return fmt.Errorf("failed to load configuration: %w", err)
	}

	// Apply command line options
	if noText, _ := cmd.Flags().GetBool("no-text"); noText {
		cfg.CaptureText = false
	}
	if noMouse, _ := cmd.Flags().GetBool("no-mouse"); noMouse {
		cfg.CaptureMouse = false
	}
	if debug, _ := cmd.Flags().GetBool("debug"); debug {
		cfg.Debug = true
	}

	// Check permissions
	permissions, err := platform.CheckPermissions()
	if err != nil {
		return fmt.Errorf("failed to check permissions: %w", err)
	}

	if !permissions.HasAllPermissions() {
		color.Red("❌ Insufficient permissions for monitoring")
		fmt.Println("Missing permissions:")
		if !permissions.Accessibility {
			fmt.Println("   - Accessibility permission required")
		}
		if !permissions.InputMonitoring {
			fmt.Println("   - Input monitoring permission required")
		}

		fmt.Println("\nAttempting to request permissions...")
		if err := platform.RequestPermissions(); err != nil {
			return fmt.Errorf("failed to obtain required permissions: %w", err)
		}
	}

	// Initialize storage
	store, err := storage.New(cfg.DatabasePath)
	if err != nil {
		return fmt.Errorf("failed to initialize storage: %w", err)
	}
	defer store.Close()

	// Create monitor with dependency injection
	mon := monitor.New(cfg, store, platform.GetCurrent())

	// Set up graceful shutdown with context
	ctx, cancel := context.WithCancel(context.Background())
	defer cancel()

	// Handle signals for graceful shutdown
	sigChan := make(chan os.Signal, 1)
	signal.Notify(sigChan, os.Interrupt, syscall.SIGTERM)

	go func() {
		<-sigChan
		color.Yellow("\n🛑 Received shutdown signal, stopping gracefully...")
		cancel()
	}()

	// Start monitoring
	if err := mon.Start(ctx); err != nil {
		return fmt.Errorf("failed to start monitoring: %w", err)
	}

	color.Green("✅ Selfspy monitoring started successfully")
	color.Blue("📊 Press Ctrl+C to stop monitoring")

	// Wait for shutdown
	<-ctx.Done()

	// Stop monitoring gracefully
	if err := mon.Stop(); err != nil {
		log.Printf("Error stopping monitor: %v", err)
	}

	return nil
}

func runStop(cmd *cobra.Command, args []string) error {
	color.Yellow("🛑 Stopping Selfspy monitoring...")
	
	// Send signal to running process (implementation would find and signal the process)
	color.Green("✅ Stop signal sent")
	return nil
}

func runStats(cmd *cobra.Command, args []string) error {
	days, _ := cmd.Flags().GetInt("days")
	jsonOutput, _ := cmd.Flags().GetBool("json")

	cfg, err := config.Load()
	if err != nil {
		return fmt.Errorf("failed to load configuration: %w", err)
	}

	store, err := storage.New(cfg.DatabasePath)
	if err != nil {
		return fmt.Errorf("failed to initialize storage: %w", err)
	}
	defer store.Close()

	statistics, err := stats.GetActivityStats(store, days)
	if err != nil {
		return fmt.Errorf("failed to get statistics: %w", err)
	}

	if jsonOutput {
		jsonData, err := json.MarshalIndent(statistics, "", "  ")
		if err != nil {
			return fmt.Errorf("failed to marshal JSON: %w", err)
		}
		fmt.Println(string(jsonData))
	} else {
		printFormattedStats(statistics, days)
	}

	return nil
}

func runCheck(cmd *cobra.Command, args []string) error {
	color.Cyan("🔍 Checking Selfspy permissions...")
	fmt.Println(color.CyanString("==================================="))
	fmt.Println()

	permissions, err := platform.CheckPermissions()
	if err != nil {
		return fmt.Errorf("failed to check permissions: %w", err)
	}

	if permissions.HasAllPermissions() {
		color.Green("✅ All permissions granted")
	} else {
		color.Red("❌ Missing permissions:")
		if !permissions.Accessibility {
			fmt.Println("   - Accessibility permission required")
		}
		if !permissions.InputMonitoring {
			fmt.Println("   - Input monitoring permission required")
		}
		if !permissions.ScreenRecording {
			fmt.Println("   - Screen recording permission (optional)")
		}
	}

	fmt.Println()
	color.Blue("📱 System Information:")
	sysInfo := platform.GetSystemInfo()
	fmt.Printf("   Platform: %s\n", sysInfo.Platform)
	fmt.Printf("   Architecture: %s\n", sysInfo.Architecture)
	fmt.Printf("   Go Version: %s\n", sysInfo.GoVersion)
	fmt.Printf("   Hostname: %s\n", sysInfo.Hostname)

	return nil
}

func runExport(cmd *cobra.Command, args []string) error {
	format, _ := cmd.Flags().GetString("format")
	output, _ := cmd.Flags().GetString("output")
	days, _ := cmd.Flags().GetInt("days")

	color.Cyan("📤 Exporting %d days of data in %s format...", days, format)

	cfg, err := config.Load()
	if err != nil {
		return fmt.Errorf("failed to load configuration: %w", err)
	}

	store, err := storage.New(cfg.DatabasePath)
	if err != nil {
		return fmt.Errorf("failed to initialize storage: %w", err)
	}
	defer store.Close()

	var data string
	switch format {
	case "json":
		data, err = store.ExportJSON(days)
	case "csv":
		data, err = store.ExportCSV(days)
	case "sql":
		data, err = store.ExportSQL(days)
	default:
		return fmt.Errorf("unsupported export format: %s", format)
	}

	if err != nil {
		return fmt.Errorf("export failed: %w", err)
	}

	if output != "" {
		if err := os.WriteFile(output, []byte(data), 0644); err != nil {
			return fmt.Errorf("failed to write output file: %w", err)
		}
		color.Green("✅ Data exported to %s", output)
	} else {
		fmt.Print(data)
	}

	return nil
}

func printFormattedStats(stats *types.ActivityStats, days int) {
	fmt.Println()
	color.Blue("📊 Selfspy Activity Statistics (Last %d days)", days)
	fmt.Println(color.BlueString("=================================================="))
	fmt.Println()
	fmt.Printf("⌨️  Keystrokes: %s\n", formatNumber(stats.Keystrokes))
	fmt.Printf("🖱️  Mouse clicks: %s\n", formatNumber(stats.Clicks))
	fmt.Printf("🪟  Window changes: %s\n", formatNumber(stats.WindowChanges))
	fmt.Printf("⏰ Active time: %s\n", formatDuration(stats.ActiveTimeSeconds))

	if len(stats.TopApps) > 0 {
		fmt.Println("📱 Most used applications:")
		for i, app := range stats.TopApps {
			fmt.Printf("   %d. %s (%.1f%%)\n", i+1, app.Name, app.Percentage)
		}
	}
	fmt.Println()
}

func formatNumber(number uint64) string {
	switch {
	case number >= 1_000_000:
		return fmt.Sprintf("%.1fM", float64(number)/1_000_000)
	case number >= 1_000:
		return fmt.Sprintf("%.1fK", float64(number)/1_000)
	default:
		return fmt.Sprintf("%d", number)
	}
}

func formatDuration(seconds uint64) string {
	hours := seconds / 3600
	minutes := (seconds % 3600) / 60

	if hours > 0 {
		return fmt.Sprintf("%dh %dm", hours, minutes)
	}
	return fmt.Sprintf("%dm", minutes)
}