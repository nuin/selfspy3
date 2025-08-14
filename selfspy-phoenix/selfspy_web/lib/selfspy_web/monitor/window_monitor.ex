defmodule SelfspyWeb.Monitor.WindowMonitor do
  @moduledoc """
  Platform-specific window monitoring GenServer.
  
  Tracks active windows, their properties, and notifies other monitors
  about window changes for context information.
  """
  
  use GenServer
  require Logger
  
  alias SelfspyWeb.Monitor.{ActivityMonitor, KeyboardMonitor, MouseMonitor}
  
  defstruct [
    :config,
    :active,
    :current_window,
    :window_history,
    :check_interval
  ]
  
  @check_interval_ms 1000  # Check for window changes every second
  
  # Client API
  
  def start_link(config \\ %{}) do
    GenServer.start_link(__MODULE__, config, name: __MODULE__)
  end
  
  def get_status do
    GenServer.call(__MODULE__, :get_status)
  end
  
  def get_current_window do
    GenServer.call(__MODULE__, :get_current_window)
  end
  
  # Server Callbacks
  
  @impl true
  def init(config) do
    Logger.info("WindowMonitor starting...")
    
    state = %__MODULE__{
      config: config,
      active: false,
      current_window: nil,
      window_history: [],
      check_interval: @check_interval_ms
    }
    
    # Start window monitoring
    case start_window_monitoring() do
      :ok ->
        schedule_window_check()
        {:ok, %{state | active: true}}
      {:error, reason} ->
        Logger.error("Failed to start window monitoring: #{inspect(reason)}")
        {:stop, reason}
    end
  end
  
  @impl true
  def handle_call(:get_status, _from, state) do
    status = %{
      active: state.active,
      current_window: state.current_window,
      history_size: length(state.window_history)
    }
    {:reply, status, state}
  end
  
  @impl true
  def handle_call(:get_current_window, _from, state) do
    {:reply, state.current_window, state}
  end
  
  @impl true
  def handle_info(:check_window, state) do
    if state.active do
      case get_active_window() do
        {:ok, window_info} ->
          new_state = handle_window_change(window_info, state)
          schedule_window_check()
          {:noreply, new_state}
          
        {:error, reason} ->
          Logger.warn("Failed to get active window: #{inspect(reason)}")
          schedule_window_check()
          {:noreply, state}
      end
    else
      {:noreply, state}
    end
  end
  
  # Private Functions
  
  defp start_window_monitoring do
    # This would initialize platform-specific window monitoring
    case Application.get_env(:selfspy_web, :demo_mode, true) do
      true ->
        :ok  # Demo mode doesn't need special initialization
      false ->
        start_real_window_monitoring()
    end
  end
  
  defp start_real_window_monitoring do
    # This would call into platform-specific APIs
    # macOS: Use CGWindowListCopyWindowInfo
    # Linux: Use X11 or Wayland protocols
    # Windows: Use GetForegroundWindow, GetWindowText
    {:error, :not_implemented}
  end
  
  defp schedule_window_check do
    Process.send_after(self(), :check_window, @check_interval_ms)
  end
  
  defp get_active_window do
    case Application.get_env(:selfspy_web, :demo_mode, true) do
      true ->
        get_demo_window()
      false ->
        get_real_active_window()
    end
  end
  
  defp get_demo_window do
    # Simulate different demo windows
    demo_windows = [
      %{
        title: "Phoenix LiveView Dashboard - Selfspy",
        process_name: "SelfspyWeb",
        bundle_id: "com.selfspy.web",
        pid: 12345,
        x: 100,
        y: 50,
        width: 1200,
        height: 800,
        screen_width: 1920,
        screen_height: 1080,
        is_active: true,
        is_visible: true
      },
      %{
        title: "Terminal",
        process_name: "Terminal",
        bundle_id: "com.apple.Terminal",
        pid: 23456,
        x: 200,
        y: 100,
        width: 800,
        height: 600,
        screen_width: 1920,
        screen_height: 1080,
        is_active: true,
        is_visible: true
      },
      %{
        title: "Activity Monitor",
        process_name: "Activity Monitor",
        bundle_id: "com.apple.ActivityMonitor",
        pid: 34567,
        x: 300,
        y: 150,
        width: 900,
        height: 700,
        screen_width: 1920,
        screen_height: 1080,
        is_active: true,
        is_visible: true
      }
    ]
    
    # Cycle through demo windows based on time
    index = rem(System.system_time(:second), length(demo_windows))
    window = Enum.at(demo_windows, index)
    
    {:ok, window}
  end
  
  defp get_real_active_window do
    # This would call platform-specific NIFs
    {:error, :not_implemented}
  end
  
  defp handle_window_change(window_info, state) do
    if window_changed?(window_info, state.current_window) do
      Logger.debug("Window changed to: #{window_info.title}")
      
      # Record window change
      ActivityMonitor.record_window_change(window_info)
      
      # Notify other monitors about window change
      notify_window_change(window_info)
      
      # Update history
      new_history = [window_info | state.window_history]
      |> Enum.take(50)  # Keep last 50 windows
      
      %{state | 
        current_window: window_info,
        window_history: new_history
      }
    else
      state
    end
  end
  
  defp window_changed?(new_window, current_window) do
    case current_window do
      nil -> true
      current ->
        new_window.title != current.title or 
        new_window.process_name != current.process_name or
        new_window.pid != current.pid
    end
  end
  
  defp notify_window_change(window_info) do
    # Notify keyboard and mouse monitors about window change
    if Process.whereis(KeyboardMonitor) do
      send(KeyboardMonitor, {:window_change, window_info})
    end
    
    if Process.whereis(MouseMonitor) do
      send(MouseMonitor, {:window_change, window_info})
    end
  end
end