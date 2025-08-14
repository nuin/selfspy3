## Configuration management for Selfspy
## Handles loading and validation of configuration files

import std/[os, json, strutils, tables]
import yaml, chronicles

export chronicles

type
  DatabaseConfig* = object
    path*: string
    backupInterval*: int  # hours
    
  MonitoringConfig* = object
    captureText*: bool
    captureMouse*: bool
    captureWindows*: bool
    captureTerminal*: bool
    updateInterval*: int  # milliseconds
    
  EncryptionConfig* = object
    enabled*: bool
    algorithm*: string
    keyDerivation*: string
    
  PrivacyConfig* = object
    excludeApps*: seq[string]
    excludeWindowTitles*: seq[string] 
    excludeUrls*: seq[string]
    privateMode*: bool
    
  Config* = object
    database*: DatabaseConfig
    monitoring*: MonitoringConfig
    encryption*: EncryptionConfig
    privacy*: PrivacyConfig
    dataDir*: string
    logLevel*: string

proc getDefaultDataDir(): string =
  """Get platform-specific default data directory."""
  when defined(windows):
    result = getEnv("APPDATA") / "selfspy"
  elif defined(macosx):
    result = getEnv("HOME") / "Library/Application Support/selfspy"
  else:
    result = getEnv("HOME") / ".local/share/selfspy"

proc defaultConfig*(): Config =
  """Create default configuration."""
  let dataDir = getDefaultDataDir()
  
  result = Config(
    dataDir: dataDir,
    logLevel: "INFO",
    database: DatabaseConfig(
      path: dataDir / "selfspy.db",
      backupInterval: 24
    ),
    monitoring: MonitoringConfig(
      captureText: true,
      captureMouse: true, 
      captureWindows: true,
      captureTerminal: true,
      updateInterval: 100
    ),
    encryption: EncryptionConfig(
      enabled: true,
      algorithm: "AES-256-GCM",
      keyDerivation: "PBKDF2"
    ),
    privacy: PrivacyConfig(
      excludeApps: @[],
      excludeWindowTitles: @[],
      excludeUrls: @[],
      privateMode: false
    )
  )

proc configPath(): string =
  """Get configuration file path."""
  when defined(windows):
    result = getEnv("APPDATA") / "selfspy" / "config.yaml"
  elif defined(macosx):
    result = getEnv("HOME") / "Library/Application Support/selfspy" / "config.yaml"
  else:
    result = getEnv("HOME") / ".config/selfspy" / "config.yaml"

proc loadConfig*(): Config =
  """Load configuration from file or create default."""
  let path = configPath()
  
  if not fileExists(path):
    info "Configuration file not found, creating default", path=path
    result = defaultConfig()
    saveConfig(result)
    return
    
  try:
    let content = readFile(path)
    let yamlNode = loadAs[Config](content)
    result = yamlNode
    info "Configuration loaded", path=path
  except Exception as e:
    warn "Failed to load configuration, using defaults", 
         path=path, error=e.msg
    result = defaultConfig()

proc saveConfig*(config: Config) =
  """Save configuration to file."""
  let path = configPath()
  
  try:
    createDir(path.parentDir())
    let yamlContent = dump(config, tsYamlOptions)
    writeFile(path, yamlContent)
    info "Configuration saved", path=path
  except Exception as e:
    error "Failed to save configuration", path=path, error=e.msg

proc validateConfig*(config: Config): bool =
  """Validate configuration settings."""
  result = true
  
  # Check data directory
  if not dirExists(config.dataDir):
    try:
      createDir(config.dataDir)
      info "Created data directory", dir=config.dataDir
    except Exception as e:
      error "Cannot create data directory", dir=config.dataDir, error=e.msg
      result = false
      
  # Check database path
  let dbDir = config.database.path.parentDir()
  if not dirExists(dbDir):
    try:
      createDir(dbDir)
    except Exception as e:
      error "Cannot create database directory", dir=dbDir, error=e.msg
      result = false
      
  # Validate intervals
  if config.monitoring.updateInterval < 10:
    warn "Update interval too low, minimum 10ms recommended"
    
  if config.database.backupInterval < 1:
    warn "Backup interval too low, minimum 1 hour recommended"