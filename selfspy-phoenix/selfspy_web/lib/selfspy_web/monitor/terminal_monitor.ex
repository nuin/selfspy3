defmodule SelfspyWeb.Monitor.TerminalMonitor do
  @moduledoc """
  Terminal command monitoring GenServer.
  
  Monitors shell history files and extracts command execution data
  including working directories, git branches, and project context.
  """
  
  use GenServer
  require Logger
  
  alias SelfspyWeb.Repo
  alias SelfspyWeb.Schemas.Activity.{TerminalSession, TerminalCommand}
  
  defstruct [
    :config,
    :active,
    :watched_files,
    :file_watchers,
    :current_session,
    :command_buffer
  ]
  
  @check_interval_ms 5000  # Check history files every 5 seconds
  @supported_shells ["bash", "zsh", "fish"]
  
  # Client API
  
  def start_link(config \\ %{}) do
    GenServer.start_link(__MODULE__, config, name: __MODULE__)
  end
  
  def get_status do
    GenServer.call(__MODULE__, :get_status)
  end
  
  def record_command(command_data) do
    GenServer.cast(__MODULE__, {:record_command, command_data})
  end
  
  # Server Callbacks
  
  @impl true
  def init(config) do
    Logger.info("TerminalMonitor starting...")
    
    state = %__MODULE__{
      config: config,
      active: false,
      watched_files: [],
      file_watchers: %{},
      current_session: nil,
      command_buffer: []
    }
    
    case start_terminal_monitoring() do
      {:ok, new_state} ->
        schedule_history_check()
        {:ok, %{new_state | active: true}}
      {:error, reason} ->
        Logger.error("Failed to start terminal monitoring: #{inspect(reason)}")
        {:stop, reason}
    end
  end
  
  @impl true
  def handle_call(:get_status, _from, state) do
    status = %{
      active: state.active,
      watched_files: length(state.watched_files),
      current_session: state.current_session != nil,
      command_buffer_size: length(state.command_buffer)
    }
    {:reply, status, state}
  end
  
  @impl true
  def handle_cast({:record_command, command_data}, state) do
    if state.active do
      processed_command = process_command_data(command_data, state)
      new_buffer = [processed_command | state.command_buffer]
      
      new_state = %{state | command_buffer: new_buffer}
      new_state = maybe_flush_commands(new_state)
      
      {:noreply, new_state}
    else
      {:noreply, state}
    end
  end
  
  @impl true
  def handle_info(:check_history, state) do
    if state.active do
      new_state = check_history_files(state)
      schedule_history_check()
      {:noreply, new_state}
    else
      {:noreply, state}
    end
  end
  
  @impl true
  def handle_info({:file_event, path, events}, state) do
    if state.active and path in state.watched_files do
      new_state = handle_file_change(path, events, state)
      {:noreply, new_state}
    else
      {:noreply, state}
    end
  end
  
  # Private Functions
  
  defp start_terminal_monitoring do
    case find_history_files() do
      [] ->
        Logger.warn("No shell history files found")
        {:ok, %{watched_files: [], file_watchers: %{}}}
        
      files ->
        Logger.info("Found history files: #{inspect(files)}")
        
        # Start file watchers for history files
        watchers = start_file_watchers(files)
        
        # Create initial terminal session
        session = create_terminal_session()
        
        {:ok, %{
          watched_files: files,
          file_watchers: watchers,
          current_session: session
        }}
    end
  end
  
  defp find_history_files do
    home_dir = System.user_home()
    
    potential_files = [
      Path.join(home_dir, ".bash_history"),
      Path.join(home_dir, ".zsh_history"),
      Path.join(home_dir, ".config/fish/fish_history"),
      Path.join(home_dir, ".local/share/fish/fish_history")
    ]
    
    Enum.filter(potential_files, &File.exists?/1)
  end
  
  defp start_file_watchers(files) do
    # In production, this would use a file system watcher like FileSystem
    # For demo, we'll simulate with periodic checks
    Enum.reduce(files, %{}, fn file, acc ->
      Map.put(acc, file, :demo_watcher)
    end)
  end
  
  defp create_terminal_session do
    shell_info = get_shell_info()
    
    %{
      shell_type: shell_info.type,
      shell_version: shell_info.version,
      working_directory: System.get_cwd() || "/",
      session_id: generate_session_id(),
      started_at: DateTime.utc_now(),
      is_active: true
    }
  end
  
  defp get_shell_info do
    shell_path = System.get_env("SHELL", "/bin/bash")
    shell_type = Path.basename(shell_path)
    
    # Try to get shell version
    version = case System.cmd(shell_path, ["--version"], stderr_to_stdout: true) do
      {output, 0} ->
        output
        |> String.split("\n")
        |> List.first()
        |> String.trim()
      _ ->
        "unknown"
    end
    
    %{type: shell_type, version: version}
  end
  
  defp generate_session_id do
    :crypto.strong_rand_bytes(16) |> Base.encode16(case: :lower)
  end
  
  defp schedule_history_check do
    Process.send_after(self(), :check_history, @check_interval_ms)
  end
  
  defp check_history_files(state) do
    # Generate demo commands for demonstration
    demo_commands = generate_demo_commands()
    
    new_buffer = demo_commands ++ state.command_buffer
    new_state = %{state | command_buffer: new_buffer}
    
    maybe_flush_commands(new_state)
  end
  
  defp generate_demo_commands do
    now = DateTime.utc_now()
    
    demo_commands = [
      %{
        command: "git status",
        command_type: "git",
        working_directory: "/Users/nuin/Projects/selfspy3",
        git_branch: "elixir-phoenix-implementation",
        project_type: "elixir",
        exit_code: 0,
        duration_ms: 120,
        executed_at: DateTime.add(now, -30, :second)
      },
      %{
        command: "mix phx.server",
        command_type: "mix",
        working_directory: "/Users/nuin/Projects/selfspy3/selfspy-phoenix/selfspy_web",
        git_branch: "elixir-phoenix-implementation",
        project_type: "elixir",
        exit_code: 0,
        duration_ms: 2500,
        executed_at: DateTime.add(now, -60, :second)
      },
      %{
        command: "ls -la",
        command_type: "system",
        working_directory: "/Users/nuin/Projects/selfspy3",
        git_branch: "elixir-phoenix-implementation",
        project_type: "elixir",
        exit_code: 0,
        duration_ms: 45,
        executed_at: DateTime.add(now, -90, :second)
      }
    ]
    
    # Only return if it's time for new demo data
    if rem(System.system_time(:second), 30) == 0 do
      demo_commands
    else
      []
    end
  end
  
  defp handle_file_change(path, _events, state) do
    Logger.debug("History file changed: #{path}")
    
    # Parse new commands from the file
    case parse_history_file(path) do
      {:ok, commands} ->
        new_buffer = commands ++ state.command_buffer
        %{state | command_buffer: new_buffer}
        
      {:error, reason} ->
        Logger.warn("Failed to parse history file #{path}: #{inspect(reason)}")
        state
    end
  end
  
  defp parse_history_file(path) do
    # Implementation would parse shell-specific history formats
    # For now, return empty list
    {:ok, []}
  end
  
  defp process_command_data(command_data, state) do
    working_dir = command_data[:working_directory] || System.get_cwd() || "/"
    
    %{
      command: command_data[:command],
      command_type: detect_command_type(command_data[:command]),
      working_directory: working_dir,
      git_branch: get_git_branch(working_dir),
      project_type: detect_project_type(working_dir),
      exit_code: command_data[:exit_code] || 0,
      duration_ms: command_data[:duration_ms] || 0,
      executed_at: command_data[:executed_at] || DateTime.utc_now(),
      session_id: state.current_session[:session_id]
    }
  end
  
  defp detect_command_type(command) when is_binary(command) do
    command_parts = String.split(command, " ", parts: 2)
    base_command = List.first(command_parts, "")
    
    cond do
      String.starts_with?(base_command, "git") -> "git"
      String.starts_with?(base_command, "npm") -> "npm"
      String.starts_with?(base_command, "yarn") -> "yarn"
      String.starts_with?(base_command, "mix") -> "mix"
      String.starts_with?(base_command, "cargo") -> "cargo"
      String.starts_with?(base_command, "python") -> "python"
      String.starts_with?(base_command, "pip") -> "python"
      String.starts_with?(base_command, "docker") -> "docker"
      String.starts_with?(base_command, "kubectl") -> "kubernetes"
      base_command in ["ls", "cd", "mkdir", "rm", "cp", "mv"] -> "system"
      true -> "other"
    end
  end
  
  defp detect_command_type(_), do: "other"
  
  defp get_git_branch(working_dir) do
    git_dir = Path.join(working_dir, ".git")
    
    if File.exists?(git_dir) do
      case System.cmd("git", ["branch", "--show-current"], cd: working_dir, stderr_to_stdout: true) do
        {branch, 0} -> String.trim(branch)
        _ -> nil
      end
    else
      nil
    end
  rescue
    _ -> nil
  end
  
  defp detect_project_type(working_dir) do
    project_files = [
      {"package.json", "nodejs"},
      {"Cargo.toml", "rust"},
      {"mix.exs", "elixir"},
      {"requirements.txt", "python"},
      {"Pipfile", "python"},
      {"pyproject.toml", "python"},
      {"Gemfile", "ruby"},
      {"go.mod", "go"},
      {"pom.xml", "java"},
      {"build.gradle", "java"}
    ]
    
    Enum.find_value(project_files, "unknown", fn {file, type} ->
      if File.exists?(Path.join(working_dir, file)), do: type
    end)
  end
  
  defp maybe_flush_commands(state) do
    if length(state.command_buffer) >= 10 do
      flush_commands(state)
    else
      state
    end
  end
  
  defp flush_commands(state) do
    if length(state.command_buffer) > 0 do
      Logger.debug("Flushing #{length(state.command_buffer)} terminal commands")
      
      # In production, this would insert into database
      # For demo, just log the commands
      Enum.each(state.command_buffer, fn cmd ->
        Logger.debug("Command: #{cmd.command} (#{cmd.command_type}) in #{cmd.working_directory}")
      end)
      
      %{state | command_buffer: []}
    else
      state
    end
  end
end