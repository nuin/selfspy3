require "yaml"
require "json" 
require "log"

module Selfspy
  # Configuration management with YAML support and sensible defaults
  class Config
    include YAML::Serializable
    include JSON::Serializable
    
    Log = ::Log.for(self)
    
    property database : DatabaseConfig
    property monitoring : MonitoringConfig
    property encryption : EncryptionConfig
    property privacy : PrivacyConfig
    property data_dir : String
    property log_level : String
    
    def initialize
      @data_dir = default_data_dir
      @log_level = "INFO"
      @database = DatabaseConfig.new(@data_dir)
      @monitoring = MonitoringConfig.new
      @encryption = EncryptionConfig.new
      @privacy = PrivacyConfig.new
    end
    
    def self.load : Config
      path = config_path
      
      if File.exists?(path)
        begin
          content = File.read(path)
          config = Config.from_yaml(content)
          Log.info { "Configuration loaded from #{path}" }
          return config
        rescue ex : Exception
          Log.warn { "Failed to load configuration from #{path}: #{ex.message}" }
          Log.warn { "Using default configuration" }
        end
      else
        Log.info { "Configuration file not found at #{path}, creating default" }
      end
      
      # Create default configuration
      config = Config.new
      config.save
      config
    end
    
    def save
      path = config_path
      Dir.mkdir_p(File.dirname(path))
      
      begin
        File.write(path, to_yaml)
        Log.info { "Configuration saved to #{path}" }
      rescue ex : Exception
        Log.error { "Failed to save configuration to #{path}: #{ex.message}" }
      end
    end
    
    def validate! : Bool
      # Ensure data directory exists
      unless Dir.exists?(@data_dir)
        begin
          Dir.mkdir_p(@data_dir)
          Log.info { "Created data directory: #{@data_dir}" }
        rescue ex : Exception
          Log.error { "Cannot create data directory #{@data_dir}: #{ex.message}" }
          return false
        end
      end
      
      # Ensure database directory exists
      db_dir = File.dirname(@database.path)
      unless Dir.exists?(db_dir)
        begin
          Dir.mkdir_p(db_dir)
        rescue ex : Exception
          Log.error { "Cannot create database directory #{db_dir}: #{ex.message}" }
          return false
        end
      end
      
      # Validate intervals
      if @monitoring.update_interval < 10
        Log.warn { "Update interval too low (#{@monitoring.update_interval}ms), minimum 10ms recommended" }
      end
      
      if @database.backup_interval < 1
        Log.warn { "Backup interval too low (#{@database.backup_interval}h), minimum 1 hour recommended" }
      end
      
      true
    end
    
    private def default_data_dir : String
      {% if flag?(:darwin) %}
        File.expand_path("~/Library/Application Support/selfspy")
      {% elsif flag?(:linux) %}
        File.expand_path("~/.local/share/selfspy")
      {% elsif flag?(:win32) %}
        ENV["APPDATA"] + "\\selfspy"
      {% else %}
        File.expand_path("~/.selfspy")
      {% end %}
    end
    
    private def self.config_path : String
      {% if flag?(:darwin) %}
        File.expand_path("~/Library/Application Support/selfspy/config.yaml")
      {% elsif flag?(:linux) %}
        File.expand_path("~/.config/selfspy/config.yaml")
      {% elsif flag?(:win32) %}
        ENV["APPDATA"] + "\\selfspy\\config.yaml"
      {% else %}
        File.expand_path("~/.selfspy/config.yaml")
      {% end %}
    end
    
    private def config_path : String
      self.class.config_path
    end
  end
  
  class DatabaseConfig
    include YAML::Serializable
    include JSON::Serializable
    
    property path : String
    property backup_interval : Int32  # hours
    
    def initialize(data_dir : String)
      @path = File.join(data_dir, "selfspy.db")
      @backup_interval = 24
    end
  end
  
  class MonitoringConfig
    include YAML::Serializable
    include JSON::Serializable
    
    property capture_text : Bool
    property capture_mouse : Bool
    property capture_windows : Bool
    property capture_terminal : Bool
    property update_interval : Int32  # milliseconds
    
    def initialize
      @capture_text = true
      @capture_mouse = true
      @capture_windows = true
      @capture_terminal = true
      @update_interval = 100
    end
  end
  
  class EncryptionConfig
    include YAML::Serializable
    include JSON::Serializable
    
    property enabled : Bool
    property algorithm : String
    property key_derivation : String
    
    def initialize
      @enabled = true
      @algorithm = "AES-256-GCM"
      @key_derivation = "PBKDF2"
    end
  end
  
  class PrivacyConfig
    include YAML::Serializable
    include JSON::Serializable
    
    property exclude_apps : Array(String)
    property exclude_window_titles : Array(String)
    property exclude_urls : Array(String)
    property private_mode : Bool
    
    def initialize
      @exclude_apps = [] of String
      @exclude_window_titles = [] of String
      @exclude_urls = [] of String
      @private_mode = false
    end
  end
end

# Extension to add formatting to numbers
struct Int32
  def format : String
    num = self.to_s.reverse
    formatted = ""
    
    num.each_char_with_index do |char, index|
      formatted += char
      formatted += "," if (index + 1) % 3 == 0 && index != num.size - 1
    end
    
    formatted.reverse
  end
end

struct Int64
  def format : String
    self.to_i32.format
  end
end