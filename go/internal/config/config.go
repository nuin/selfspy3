package config

import (
	"os"
	"path/filepath"
	"runtime"

	"github.com/spf13/viper"
)

// Config holds all configuration settings for Selfspy
type Config struct {
	DataDir              string `mapstructure:"data_dir"`
	DatabasePath         string `mapstructure:"database_path"`
	CaptureText          bool   `mapstructure:"capture_text"`
	CaptureMouse         bool   `mapstructure:"capture_mouse"`
	CaptureWindows       bool   `mapstructure:"capture_windows"`
	UpdateIntervalMs     int    `mapstructure:"update_interval_ms"`
	EncryptionEnabled    bool   `mapstructure:"encryption_enabled"`
	Debug                bool   `mapstructure:"debug"`
	PrivacyMode          bool   `mapstructure:"privacy_mode"`
	ExcludeApplications  []string `mapstructure:"exclude_applications"`
	MaxDatabaseSizeMB    int    `mapstructure:"max_database_size_mb"`
}

// Default returns a config with sensible defaults
func Default() *Config {
	homeDir, _ := os.UserHomeDir()
	
	var dataDir string
	switch runtime.GOOS {
	case "darwin":
		dataDir = filepath.Join(homeDir, "Library", "Application Support", "selfspy")
	case "windows":
		dataDir = filepath.Join(os.Getenv("APPDATA"), "selfspy")
	default: // linux and others
		dataDir = filepath.Join(homeDir, ".local", "share", "selfspy")
	}

	return &Config{
		DataDir:              dataDir,
		DatabasePath:         filepath.Join(dataDir, "selfspy.db"),
		CaptureText:          true,
		CaptureMouse:         true,
		CaptureWindows:       true,
		UpdateIntervalMs:     100,
		EncryptionEnabled:    true,
		Debug:                false,
		PrivacyMode:          false,
		ExcludeApplications:  []string{},
		MaxDatabaseSizeMB:    500,
	}
}

// Load reads configuration from file and environment variables
func Load() (*Config, error) {
	cfg := Default()

	// Set up viper
	viper.SetConfigName("config")
	viper.SetConfigType("yaml")
	viper.AddConfigPath(cfg.DataDir)
	viper.AddConfigPath(".")

	// Environment variable prefix
	viper.SetEnvPrefix("SELFSPY")
	viper.AutomaticEnv()

	// Set defaults
	viper.SetDefault("data_dir", cfg.DataDir)
	viper.SetDefault("database_path", cfg.DatabasePath)
	viper.SetDefault("capture_text", cfg.CaptureText)
	viper.SetDefault("capture_mouse", cfg.CaptureMouse)
	viper.SetDefault("capture_windows", cfg.CaptureWindows)
	viper.SetDefault("update_interval_ms", cfg.UpdateIntervalMs)
	viper.SetDefault("encryption_enabled", cfg.EncryptionEnabled)
	viper.SetDefault("debug", cfg.Debug)
	viper.SetDefault("privacy_mode", cfg.PrivacyMode)
	viper.SetDefault("exclude_applications", cfg.ExcludeApplications)
	viper.SetDefault("max_database_size_mb", cfg.MaxDatabaseSizeMB)

	// Read config file if it exists
	if err := viper.ReadInConfig(); err != nil {
		if _, ok := err.(viper.ConfigFileNotFoundError); !ok {
			return nil, err
		}
	}

	// Unmarshal into config struct
	if err := viper.Unmarshal(cfg); err != nil {
		return nil, err
	}

	// Ensure data directory exists
	if err := os.MkdirAll(cfg.DataDir, 0755); err != nil {
		return nil, err
	}

	return cfg, nil
}

// Save writes the current configuration to file
func (c *Config) Save() error {
	viper.Set("data_dir", c.DataDir)
	viper.Set("database_path", c.DatabasePath)
	viper.Set("capture_text", c.CaptureText)
	viper.Set("capture_mouse", c.CaptureMouse)
	viper.Set("capture_windows", c.CaptureWindows)
	viper.Set("update_interval_ms", c.UpdateIntervalMs)
	viper.Set("encryption_enabled", c.EncryptionEnabled)
	viper.Set("debug", c.Debug)
	viper.Set("privacy_mode", c.PrivacyMode)
	viper.Set("exclude_applications", c.ExcludeApplications)
	viper.Set("max_database_size_mb", c.MaxDatabaseSizeMB)

	configPath := filepath.Join(c.DataDir, "config.yaml")
	return viper.WriteConfigAs(configPath)
}