defmodule SelfspyWeb.Monitor.ActivityMonitor do
  @moduledoc """
  Main activity monitoring GenServer that coordinates all monitoring activities.
  
  This GenServer manages the overall monitoring process and coordinates with
  platform-specific monitors for keyboard, mouse, and window tracking.
  """
  
  use GenServer
  require Logger
  
  alias SelfspyWeb.Monitor.{KeyboardMonitor, MouseMonitor, WindowMonitor, TerminalMonitor}
  alias SelfspyWeb.Repo
  alias SelfspyWeb.Schemas.Activity
  
  defstruct [
    :config,
    :monitoring_active,
    :monitors,
    :buffer,
    :last_flush,
    :stats
  ]
  
  @flush_interval_ms 5_000  # Flush every 5 seconds
  @buffer_max_size 1000     # Max entries before forced flush
  
  # Client API
  
  def start_link(config \\ %{}) do
    GenServer.start_link(__MODULE__, config, name: __MODULE__)
  end
  
  def start_monitoring do
    GenServer.call(__MODULE__, :start_monitoring)
  end
  
  def stop_monitoring do
    GenServer.call(__MODULE__, :stop_monitoring)
  end
  
  def get_status do
    GenServer.call(__MODULE__, :get_status)
  end
  
  def get_stats do
    GenServer.call(__MODULE__, :get_stats)
  end
  
  def record_keystroke(data) do
    GenServer.cast(__MODULE__, {:record_keystroke, data})
  end
  
  def record_click(data) do
    GenServer.cast(__MODULE__, {:record_click, data})
  end
  
  def record_window_change(data) do
    GenServer.cast(__MODULE__, {:record_window_change, data})
  end
  
  # Server Callbacks
  
  @impl true
  def init(config) do
    Logger.info("ActivityMonitor starting...")
    
    state = %__MODULE__{
      config: config,
      monitoring_active: false,
      monitors: %{},
      buffer: %{
        keystrokes: [],
        clicks: [],
        windows: [],
        processes: %{}
      },
      last_flush: System.monotonic_time(:millisecond),
      stats: %{
        keystrokes_count: 0,
        clicks_count: 0,
        windows_count: 0,
        started_at: nil,
        last_activity: nil
      }
    }
    
    # Schedule periodic flush
    schedule_flush()
    
    {:ok, state}
  end
  
  @impl true
  def handle_call(:start_monitoring, _from, state) do
    case start_monitors(state) do
      {:ok, monitors} ->
        new_state = %{state | 
          monitoring_active: true, 
          monitors: monitors,
          stats: %{state.stats | started_at: DateTime.utc_now()}
        }
        
        Logger.info("Activity monitoring started")
        broadcast_status_change(:started)
        
        {:reply, :ok, new_state}
        
      {:error, reason} ->
        Logger.error("Failed to start monitoring: #{inspect(reason)}")
        {:reply, {:error, reason}, state}
    end
  end
  
  @impl true
  def handle_call(:stop_monitoring, _from, state) do
    stop_monitors(state.monitors)
    flush_buffer(state)
    
    new_state = %{state | 
      monitoring_active: false, 
      monitors: %{}
    }
    
    Logger.info("Activity monitoring stopped")
    broadcast_status_change(:stopped)
    
    {:reply, :ok, new_state}
  end
  
  @impl true
  def handle_call(:get_status, _from, state) do
    status = %{
      monitoring_active: state.monitoring_active,
      stats: state.stats,
      buffer_size: buffer_size(state.buffer),
      monitors: Map.keys(state.monitors)
    }
    
    {:reply, status, state}
  end
  
  @impl true
  def handle_call(:get_stats, _from, state) do
    {:reply, state.stats, state}
  end
  
  @impl true
  def handle_cast({:record_keystroke, data}, state) do
    if state.monitoring_active do
      keystroke = prepare_keystroke_data(data)
      new_buffer = %{state.buffer | keystrokes: [keystroke | state.buffer.keystrokes]}
      new_stats = %{state.stats | 
        keystrokes_count: state.stats.keystrokes_count + 1,
        last_activity: DateTime.utc_now()
      }
      
      new_state = %{state | buffer: new_buffer, stats: new_stats}
      new_state = maybe_flush_buffer(new_state)
      
      {:noreply, new_state}
    else
      {:noreply, state}
    end
  end
  
  @impl true
  def handle_cast({:record_click, data}, state) do
    if state.monitoring_active do
      click = prepare_click_data(data)
      new_buffer = %{state.buffer | clicks: [click | state.buffer.clicks]}
      new_stats = %{state.stats | 
        clicks_count: state.stats.clicks_count + 1,
        last_activity: DateTime.utc_now()
      }
      
      new_state = %{state | buffer: new_buffer, stats: new_stats}
      new_state = maybe_flush_buffer(new_state)
      
      {:noreply, new_state}
    else
      {:noreply, state}
    end
  end
  
  @impl true
  def handle_cast({:record_window_change, data}, state) do
    if state.monitoring_active do
      window = prepare_window_data(data)
      new_buffer = %{state.buffer | windows: [window | state.buffer.windows]}
      new_stats = %{state.stats | 
        windows_count: state.stats.windows_count + 1,
        last_activity: DateTime.utc_now()
      }
      
      new_state = %{state | buffer: new_buffer, stats: new_stats}
      new_state = maybe_flush_buffer(new_state)
      
      {:noreply, new_state}
    else
      {:noreply, state}
    end
  end
  
  @impl true
  def handle_info(:flush_buffer, state) do
    new_state = flush_buffer(state)
    schedule_flush()
    {:noreply, new_state}
  end
  
  @impl true
  def handle_info({:DOWN, _ref, :process, pid, reason}, state) do
    Logger.warn("Monitor process #{inspect(pid)} died: #{inspect(reason)}")
    # Could implement restart logic here
    {:noreply, state}
  end
  
  # Private Functions
  
  defp start_monitors(state) do
    monitors = %{}
    
    with {:ok, keyboard_pid} <- KeyboardMonitor.start_link(),
         {:ok, mouse_pid} <- MouseMonitor.start_link(),
         {:ok, window_pid} <- WindowMonitor.start_link(),
         {:ok, terminal_pid} <- TerminalMonitor.start_link() do
      
      monitors = %{
        keyboard: keyboard_pid,
        mouse: mouse_pid,
        window: window_pid,
        terminal: terminal_pid
      }
      
      # Monitor all child processes
      Enum.each(monitors, fn {_name, pid} ->
        Process.monitor(pid)
      end)
      
      {:ok, monitors}
    else
      {:error, reason} -> {:error, reason}
    end
  end
  
  defp stop_monitors(monitors) do
    Enum.each(monitors, fn {_name, pid} ->
      if Process.alive?(pid) do
        GenServer.stop(pid, :normal)
      end
    end)
  end
  
  defp schedule_flush do
    Process.send_after(self(), :flush_buffer, @flush_interval_ms)
  end
  
  defp maybe_flush_buffer(state) do
    if buffer_size(state.buffer) >= @buffer_max_size do
      flush_buffer(state)
    else
      state
    end
  end
  
  defp flush_buffer(state) do
    if buffer_has_data?(state.buffer) do
      Logger.debug("Flushing buffer with #{buffer_size(state.buffer)} entries")
      
      try do
        Repo.transaction(fn ->
          # Insert processes first
          process_ids = insert_processes(state.buffer.processes)
          
          # Insert windows with process references
          window_ids = insert_windows(state.buffer.windows, process_ids)
          
          # Insert keystrokes and clicks with references
          insert_keystrokes(state.buffer.keystrokes, process_ids, window_ids)
          insert_clicks(state.buffer.clicks, process_ids, window_ids)
        end)
        
        broadcast_data_update(state.stats)
        
        Logger.debug("Buffer flushed successfully")
      rescue
        e ->
          Logger.error("Failed to flush buffer: #{inspect(e)}")
      end
    end
    
    %{state | 
      buffer: %{
        keystrokes: [],
        clicks: [],
        windows: [],
        processes: %{}
      },
      last_flush: System.monotonic_time(:millisecond)
    }
  end
  
  defp buffer_size(buffer) do
    length(buffer.keystrokes) + length(buffer.clicks) + length(buffer.windows)
  end
  
  defp buffer_has_data?(buffer) do
    buffer_size(buffer) > 0 or map_size(buffer.processes) > 0
  end
  
  defp prepare_keystroke_data(data) do
    %{
      encrypted_text: data[:encrypted_text],
      key_count: data[:key_count] || 1,
      special_keys: data[:special_keys] || [],
      modifier_keys: data[:modifier_keys] || [],
      is_encrypted: data[:is_encrypted] || true,
      recorded_at: data[:recorded_at] || DateTime.utc_now(),
      process_name: data[:process_name],
      window_title: data[:window_title]
    }
  end
  
  defp prepare_click_data(data) do
    %{
      x: data[:x],
      y: data[:y],
      button: data[:button],
      click_count: data[:click_count] || 1,
      pressure: data[:pressure] || 1.0,
      movement_delta_x: data[:movement_delta_x] || 0.0,
      movement_delta_y: data[:movement_delta_y] || 0.0,
      recorded_at: data[:recorded_at] || DateTime.utc_now(),
      process_name: data[:process_name],
      window_title: data[:window_title]
    }
  end
  
  defp prepare_window_data(data) do
    %{
      title: data[:title],
      x: data[:x] || 0,
      y: data[:y] || 0,
      width: data[:width] || 0,
      height: data[:height] || 0,
      screen_width: data[:screen_width],
      screen_height: data[:screen_height],
      is_active: data[:is_active] || false,
      is_visible: data[:is_visible] || true,
      created_at: data[:created_at] || DateTime.utc_now(),
      process_name: data[:process_name]
    }
  end
  
  defp insert_processes(processes) do
    # Implementation would insert unique processes and return ID mapping
    %{}
  end
  
  defp insert_windows(windows, _process_ids) do
    # Implementation would insert windows and return ID mapping
    %{}
  end
  
  defp insert_keystrokes(keystrokes, _process_ids, _window_ids) do
    # Implementation would insert keystrokes with proper foreign keys
    :ok
  end
  
  defp insert_clicks(clicks, _process_ids, _window_ids) do
    # Implementation would insert clicks with proper foreign keys
    :ok
  end
  
  defp broadcast_status_change(status) do
    Phoenix.PubSub.broadcast(SelfspyWeb.PubSub, "activity_monitor", {:status_change, status})
  end
  
  defp broadcast_data_update(stats) do
    Phoenix.PubSub.broadcast(SelfspyWeb.PubSub, "activity_monitor", {:data_update, stats})
  end
end