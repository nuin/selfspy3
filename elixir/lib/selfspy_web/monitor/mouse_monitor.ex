defmodule SelfspyWeb.Monitor.MouseMonitor do
  @moduledoc """
  Platform-specific mouse monitoring GenServer.
  
  Captures mouse events including clicks, movements, and scrolling,
  then forwards them to the ActivityMonitor.
  """
  
  use GenServer
  require Logger
  
  alias SelfspyWeb.Monitor.ActivityMonitor
  
  defstruct [
    :config,
    :active,
    :last_position,
    :last_window,
    :movement_buffer
  ]
  
  # Client API
  
  def start_link(config \\ %{}) do
    GenServer.start_link(__MODULE__, config, name: __MODULE__)
  end
  
  def get_status do
    GenServer.call(__MODULE__, :get_status)
  end
  
  # Server Callbacks
  
  @impl true
  def init(config) do
    Logger.info("MouseMonitor starting...")
    
    state = %__MODULE__{
      config: config,
      active: false,
      last_position: {0.0, 0.0},
      last_window: nil,
      movement_buffer: []
    }
    
    # Start platform-specific monitoring
    case start_mouse_monitoring() do
      :ok ->
        {:ok, %{state | active: true}}
      {:error, reason} ->
        Logger.error("Failed to start mouse monitoring: #{inspect(reason)}")
        {:stop, reason}
    end
  end
  
  @impl true
  def handle_call(:get_status, _from, state) do
    status = %{
      active: state.active,
      last_position: state.last_position,
      movement_buffer_size: length(state.movement_buffer)
    }
    {:reply, status, state}
  end
  
  @impl true
  def handle_info({:mouse_click, event}, state) do
    if state.active do
      processed_event = process_click_event(event, state)
      ActivityMonitor.record_click(processed_event)
      
      new_state = %{state | last_position: {event.x, event.y}}
      {:noreply, new_state}
    else
      {:noreply, state}
    end
  end
  
  @impl true
  def handle_info({:mouse_move, event}, state) do
    if state.active do
      # Only track significant movements to avoid flooding
      {last_x, last_y} = state.last_position
      distance = :math.sqrt(:math.pow(event.x - last_x, 2) + :math.pow(event.y - last_y, 2))
      
      if distance > 10.0 do  # Minimum movement threshold
        movement = %{
          x: event.x,
          y: event.y,
          delta_x: event.x - last_x,
          delta_y: event.y - last_y,
          timestamp: event.timestamp || DateTime.utc_now()
        }
        
        new_buffer = [movement | state.movement_buffer]
        |> Enum.take(100)  # Keep only last 100 movements
        
        new_state = %{state | 
          last_position: {event.x, event.y},
          movement_buffer: new_buffer
        }
        
        {:noreply, new_state}
      else
        {:noreply, state}
      end
    else
      {:noreply, state}
    end
  end
  
  @impl true
  def handle_info({:window_change, window_info}, state) do
    new_state = %{state | last_window: window_info}
    {:noreply, new_state}
  end
  
  # Private Functions
  
  defp start_mouse_monitoring do
    # This would use NIFs to start platform-specific mouse monitoring
    case Application.get_env(:selfspy_web, :demo_mode, true) do
      true ->
        start_demo_mouse_monitoring()
        :ok
      false ->
        start_real_mouse_monitoring()
    end
  end
  
  defp start_demo_mouse_monitoring do
    # Send fake mouse events for demo
    spawn(fn ->
      :timer.sleep(3000)
      send_demo_click_events()
    end)
  end
  
  defp send_demo_click_events do
    demo_clicks = [
      %{
        x: 100.5,
        y: 200.3,
        button: "left",
        click_count: 1,
        pressure: 1.0,
        timestamp: DateTime.utc_now()
      },
      %{
        x: 300.2,
        y: 150.8,
        button: "right",
        click_count: 1,
        pressure: 1.0,
        timestamp: DateTime.utc_now()
      },
      %{
        x: 250.0,
        y: 300.0,
        button: "scroll_up",
        click_count: 3,
        pressure: 1.0,
        timestamp: DateTime.utc_now()
      }
    ]
    
    Enum.each(demo_clicks, fn click ->
      :timer.sleep(8000)
      send(self(), {:mouse_click, click})
    end)
    
    # Schedule next batch
    :timer.apply_after(45_000, __MODULE__, :send_demo_click_events, [])
  end
  
  defp start_real_mouse_monitoring do
    # This would call into platform-specific NIFs
    # macOS: Use CGEventTap for mouse events
    # Linux: Use libinput or X11
    # Windows: Use SetWindowsHookEx
    {:error, :not_implemented}
  end
  
  defp process_click_event(event, state) do
    {last_x, last_y} = state.last_position
    window_info = get_current_window_info(state)
    
    %{
      x: event.x,
      y: event.y,
      button: event.button,
      click_count: event.click_count || 1,
      pressure: event.pressure || 1.0,
      movement_delta_x: event.x - last_x,
      movement_delta_y: event.y - last_y,
      recorded_at: event.timestamp || DateTime.utc_now(),
      process_name: window_info[:process_name] || "Unknown",
      window_title: window_info[:window_title] || "Unknown"
    }
  end
  
  defp get_current_window_info(state) do
    state.last_window || %{
      process_name: "SelfspyWeb Demo",
      window_title: "Phoenix LiveView Dashboard"
    }
  end
end