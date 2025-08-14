defmodule SelfspyWeb.Config do
  @moduledoc """
  Configuration management for SelfspyWeb application.
  
  Handles loading, validation, and persistence of application settings
  including monitoring preferences, privacy controls, and system configuration.
  """
  
  use GenServer
  require Logger
  
  @config_file "selfspy_config.json"
  @config_dir Application.compile_env(:selfspy_web, :config_dir, "~/.config/selfspy")
  
  # Default configuration
  @default_config %{
    # General settings
    app_name: "Selfspy Phoenix",
    data_directory: "~/.local/share/selfspy",
    log_level: "info",
    auto_start: false,
    
    # Privacy settings
    encrypt_keystrokes: true,
    password_chars: "●",
    excluded_apps: "",
    excluded_titles: "",
    incognito_mode: true,
    
    # Monitoring settings
    track_keystrokes: true,
    track_mouse: true,
    track_windows: true,
    track_terminal: true,
    idle_timeout: 300,
    flush_interval: 5,
    
    # Data & storage settings
    retention_days: 365,
    max_db_size_mb: 1000,
    compress_old_data: true,
    backup_interval_days: 7,
    export_format: "json",
    
    # Advanced settings
    buffer_size: 100,
    worker_pool_size: 4,
    enable_telemetry: false,
    debug_mode: false,
    custom_plugins: ""
  }
  
  ## Client API
  
  def start_link(opts \\ []) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end
  
  @doc """
  Get the current configuration.
  """
  def get_config do
    GenServer.call(__MODULE__, :get_config)
  end
  
  @doc """
  Update configuration with new values.
  """
  def update_config(params) do
    GenServer.call(__MODULE__, {:update_config, params})
  end
  
  @doc """
  Get default configuration.
  """
  def default_config, do: @default_config
  
  @doc """
  Reset configuration to defaults.
  """
  def reset_to_defaults do
    GenServer.call(__MODULE__, :reset_to_defaults)
  end
  
  @doc """
  Get a specific configuration value.
  """
  def get(key, default \\ nil) do
    config = get_config()
    Map.get(config, key, default)
  end
  
  ## Server Implementation
  
  @impl true
  def init(_opts) do
    config = load_config()
    {:ok, config}
  end
  
  @impl true
  def handle_call(:get_config, _from, state) do
    {:reply, state, state}
  end
  
  @impl true
  def handle_call({:update_config, params}, _from, state) do
    case validate_config(params) do
      {:ok, validated_params} ->
        new_config = Map.merge(state, validated_params)
        
        case save_config(new_config) do
          :ok ->
            {:reply, {:ok, new_config}, new_config}
          {:error, reason} ->
            Logger.error("Failed to save config: #{inspect(reason)}")
            {:reply, {:error, reason}, state}
        end
        
      {:error, errors} ->
        {:reply, {:error, errors}, state}
    end
  end
  
  @impl true
  def handle_call(:reset_to_defaults, _from, _state) do
    case save_config(@default_config) do
      :ok ->
        {:reply, {:ok, @default_config}, @default_config}
      {:error, reason} ->
        {:reply, {:error, reason}, @default_config}
    end
  end
  
  ## Private Functions
  
  defp load_config do
    config_path = config_file_path()
    
    case File.read(config_path) do
      {:ok, content} ->
        case Jason.decode(content, keys: :atoms) do
          {:ok, config} ->
            # Merge with defaults to ensure all keys are present
            Map.merge(@default_config, config)
          {:error, reason} ->
            Logger.warn("Failed to parse config file: #{inspect(reason)}. Using defaults.")
            @default_config
        end
        
      {:error, :enoent} ->
        Logger.info("Config file not found. Creating with defaults.")
        save_config(@default_config)
        @default_config
        
      {:error, reason} ->
        Logger.error("Failed to read config file: #{inspect(reason)}. Using defaults.")
        @default_config
    end
  end
  
  defp save_config(config) do
    config_path = config_file_path()
    config_dir = Path.dirname(config_path)
    
    # Ensure config directory exists
    case File.mkdir_p(config_dir) do
      :ok ->
        case Jason.encode(config, pretty: true) do
          {:ok, json} ->
            File.write(config_path, json)
          {:error, reason} ->
            {:error, "Failed to encode config: #{inspect(reason)}"}
        end
        
      {:error, reason} ->
        {:error, "Failed to create config directory: #{inspect(reason)}"}
    end
  end
  
  defp config_file_path do
    config_dir = Path.expand(@config_dir)
    Path.join(config_dir, @config_file)
  end
  
  defp validate_config(params) do
    errors = []
    
    # Convert string keys to atoms if needed
    params = Enum.into(params, %{}, fn
      {key, value} when is_binary(key) -> {String.to_existing_atom(key), value}
      {key, value} when is_atom(key) -> {key, value}
    end)
    
    # Validate each parameter
    errors = 
      params
      |> Enum.reduce(errors, fn {key, value}, acc ->
        case validate_param(key, value) do
          :ok -> acc
          {:error, error} -> [error | acc]
        end
      end)
    
    if Enum.empty?(errors) do
      {:ok, params}
    else
      {:error, Enum.reverse(errors)}
    end
  end
  
  defp validate_param(:idle_timeout, value) when is_binary(value) do
    case Integer.parse(value) do
      {int_val, ""} when int_val > 0 -> :ok
      _ -> {:error, "Idle timeout must be a positive integer"}
    end
  end
  
  defp validate_param(:idle_timeout, value) when is_integer(value) and value > 0, do: :ok
  defp validate_param(:idle_timeout, _), do: {:error, "Idle timeout must be a positive integer"}
  
  defp validate_param(:flush_interval, value) when is_binary(value) do
    case Integer.parse(value) do
      {int_val, ""} when int_val > 0 -> :ok
      _ -> {:error, "Flush interval must be a positive integer"}
    end
  end
  
  defp validate_param(:flush_interval, value) when is_integer(value) and value > 0, do: :ok
  defp validate_param(:flush_interval, _), do: {:error, "Flush interval must be a positive integer"}
  
  defp validate_param(:retention_days, value) when is_binary(value) do
    case Integer.parse(value) do
      {int_val, ""} when int_val >= 0 -> :ok
      _ -> {:error, "Retention days must be a non-negative integer"}
    end
  end
  
  defp validate_param(:retention_days, value) when is_integer(value) and value >= 0, do: :ok
  defp validate_param(:retention_days, _), do: {:error, "Retention days must be a non-negative integer"}
  
  defp validate_param(:max_db_size_mb, value) when is_binary(value) do
    case Integer.parse(value) do
      {int_val, ""} when int_val > 0 -> :ok
      _ -> {:error, "Maximum database size must be a positive integer"}
    end
  end
  
  defp validate_param(:max_db_size_mb, value) when is_integer(value) and value > 0, do: :ok
  defp validate_param(:max_db_size_mb, _), do: {:error, "Maximum database size must be a positive integer"}
  
  defp validate_param(:buffer_size, value) when is_binary(value) do
    case Integer.parse(value) do
      {int_val, ""} when int_val > 0 -> :ok
      _ -> {:error, "Buffer size must be a positive integer"}
    end
  end
  
  defp validate_param(:buffer_size, value) when is_integer(value) and value > 0, do: :ok
  defp validate_param(:buffer_size, _), do: {:error, "Buffer size must be a positive integer"}
  
  defp validate_param(:worker_pool_size, value) when is_binary(value) do
    case Integer.parse(value) do
      {int_val, ""} when int_val > 0 -> :ok
      _ -> {:error, "Worker pool size must be a positive integer"}
    end
  end
  
  defp validate_param(:worker_pool_size, value) when is_integer(value) and value > 0, do: :ok
  defp validate_param(:worker_pool_size, _), do: {:error, "Worker pool size must be a positive integer"}
  
  defp validate_param(:backup_interval_days, value) when is_binary(value) do
    case Integer.parse(value) do
      {int_val, ""} when int_val > 0 -> :ok
      _ -> {:error, "Backup interval must be a positive integer"}
    end
  end
  
  defp validate_param(:backup_interval_days, value) when is_integer(value) and value > 0, do: :ok
  defp validate_param(:backup_interval_days, _), do: {:error, "Backup interval must be a positive integer"}
  
  defp validate_param(:log_level, value) when value in ["debug", "info", "warning", "error"], do: :ok
  defp validate_param(:log_level, _), do: {:error, "Log level must be one of: debug, info, warning, error"}
  
  defp validate_param(:export_format, value) when value in ["json", "csv", "sqlite"], do: :ok
  defp validate_param(:export_format, _), do: {:error, "Export format must be one of: json, csv, sqlite"}
  
  defp validate_param(:data_directory, value) when is_binary(value) and value != "", do: :ok
  defp validate_param(:data_directory, _), do: {:error, "Data directory must be a non-empty string"}
  
  defp validate_param(:app_name, value) when is_binary(value) and value != "", do: :ok
  defp validate_param(:app_name, _), do: {:error, "App name must be a non-empty string"}
  
  # Boolean validations
  defp validate_param(key, value) when key in [
    :auto_start, :encrypt_keystrokes, :incognito_mode, :track_keystrokes,
    :track_mouse, :track_windows, :track_terminal, :compress_old_data,
    :enable_telemetry, :debug_mode
  ] do
    case value do
      v when v in [true, false, "true", "false"] -> :ok
      _ -> {:error, "#{key} must be a boolean value"}
    end
  end
  
  # String validations (allow empty strings)
  defp validate_param(key, value) when key in [
    :password_chars, :excluded_apps, :excluded_titles, :custom_plugins
  ] and is_binary(value), do: :ok
  
  # Default case - allow any value for unknown parameters
  defp validate_param(_key, _value), do: :ok
end