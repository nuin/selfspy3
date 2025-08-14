defmodule SelfspyWeb.Monitor.KeyboardMonitor do
  @moduledoc """
  Platform-specific keyboard monitoring GenServer.
  
  Captures keyboard events and forwards them to the ActivityMonitor.
  Uses NIFs for low-level platform integration.
  """
  
  use GenServer
  require Logger
  
  alias SelfspyWeb.Monitor.ActivityMonitor
  
  defstruct [
    :config,
    :active,
    :buffer,
    :encryption_key,
    :last_window
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
    Logger.info("KeyboardMonitor starting...")
    
    state = %__MODULE__{
      config: config,
      active: false,
      buffer: [],
      encryption_key: generate_encryption_key(),
      last_window: nil
    }
    
    # Start platform-specific monitoring
    case start_keyboard_monitoring() do
      :ok ->
        {:ok, %{state | active: true}}
      {:error, reason} ->
        Logger.error("Failed to start keyboard monitoring: #{inspect(reason)}")
        {:stop, reason}
    end
  end
  
  @impl true
  def handle_call(:get_status, _from, state) do
    status = %{
      active: state.active,
      buffer_size: length(state.buffer)
    }
    {:reply, status, state}
  end
  
  @impl true
  def handle_info({:keyboard_event, event}, state) do
    if state.active do
      processed_event = process_keyboard_event(event, state)
      ActivityMonitor.record_keystroke(processed_event)
    end
    
    {:noreply, state}
  end
  
  @impl true
  def handle_info({:window_change, window_info}, state) do
    new_state = %{state | last_window: window_info}
    {:noreply, new_state}
  end
  
  # Private Functions
  
  defp start_keyboard_monitoring do
    # This would use NIFs to start platform-specific keyboard monitoring
    # For now, simulate with a timer that generates fake events
    case Application.get_env(:selfspy_web, :demo_mode, true) do
      true ->
        start_demo_keyboard_monitoring()
        :ok
      false ->
        start_real_keyboard_monitoring()
    end
  end
  
  defp start_demo_keyboard_monitoring do
    # Send fake keyboard events for demo
    spawn(fn ->
      :timer.sleep(2000)
      send_demo_events()
    end)
  end
  
  defp send_demo_events do
    demo_events = [
      %{
        text: "Hello World",
        special_keys: [],
        modifier_keys: [],
        timestamp: DateTime.utc_now()
      },
      %{
        text: "",
        special_keys: ["enter"],
        modifier_keys: [],
        timestamp: DateTime.utc_now()
      },
      %{
        text: "mix phx.server",
        special_keys: [],
        modifier_keys: [],
        timestamp: DateTime.utc_now()
      }
    ]
    
    Enum.each(demo_events, fn event ->
      :timer.sleep(5000)
      send(self(), {:keyboard_event, event})
    end)
    
    # Schedule next batch
    :timer.apply_after(30_000, __MODULE__, :send_demo_events, [])
  end
  
  defp start_real_keyboard_monitoring do
    # This would call into platform-specific NIFs
    # macOS: Use CGEventTap
    # Linux: Use libinput or X11
    # Windows: Use SetWindowsHookEx
    {:error, :not_implemented}
  end
  
  defp process_keyboard_event(event, state) do
    encrypted_text = if should_encrypt?(event.text) do
      encrypt_text(event.text, state.encryption_key)
    else
      nil
    end
    
    window_info = get_current_window_info(state)
    
    %{
      encrypted_text: encrypted_text,
      key_count: String.length(event.text || ""),
      special_keys: event.special_keys || [],
      modifier_keys: event.modifier_keys || [],
      is_encrypted: encrypted_text != nil,
      recorded_at: event.timestamp || DateTime.utc_now(),
      process_name: window_info[:process_name] || "Unknown",
      window_title: window_info[:window_title] || "Unknown"
    }
  end
  
  defp should_encrypt?(text) do
    # Don't encrypt special keys or empty text
    text != nil and String.length(text) > 0
  end
  
  defp encrypt_text(text, key) do
    # Simple XOR encryption for demo - use proper encryption in production
    :crypto.crypto_one_time(:aes_256_cbc, key, :crypto.strong_rand_bytes(16), text, true)
  rescue
    _ -> text  # Fallback to plaintext if encryption fails
  end
  
  defp generate_encryption_key do
    :crypto.strong_rand_bytes(32)
  end
  
  defp get_current_window_info(state) do
    state.last_window || %{
      process_name: "SelfspyWeb Demo",
      window_title: "Phoenix LiveView Dashboard"
    }
  end
end