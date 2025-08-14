defmodule SelfspyWebWeb.SettingsLive do
  @moduledoc """
  Phoenix LiveView for application settings and configuration.
  
  Allows users to configure monitoring preferences, privacy settings,
  data retention policies, and platform-specific options.
  """
  
  use SelfspyWebWeb, :live_view
  require Logger
  
  alias SelfspyWeb.Monitor.ActivityMonitor
  alias SelfspyWeb.Config
  alias Phoenix.PubSub
  
  @impl true
  def mount(_params, _session, socket) do
    if connected?(socket) do
      PubSub.subscribe(SelfspyWeb.PubSub, "activity_monitor")
    end
    
    # Load current configuration
    config = Config.get_config()
    
    socket = assign(socket,
      config: config,
      form: to_form(config),
      changes_saved: false,
      monitoring_active: get_monitoring_status(),
      current_tab: "general",
      demo_mode: Application.get_env(:selfspy_web, :demo_mode, false)
    )
    
    {:ok, socket}
  end
  
  @impl true
  def handle_event("change_tab", %{"tab" => tab}, socket) do
    {:noreply, assign(socket, current_tab: tab)}
  end
  
  @impl true
  def handle_event("update_config", %{"config" => config_params}, socket) do
    case Config.update_config(config_params) do
      {:ok, updated_config} ->
        socket = assign(socket,
          config: updated_config,
          form: to_form(updated_config),
          changes_saved: true
        )
        
        # Restart monitoring if active to apply new settings
        if socket.assigns.monitoring_active do
          ActivityMonitor.stop_monitoring()
          ActivityMonitor.start_monitoring()
        end
        
        socket = put_flash(socket, :info, "Settings saved successfully!")
        {:noreply, socket}
        
      {:error, changeset} ->
        socket = assign(socket, form: to_form(changeset))
        socket = put_flash(socket, :error, "Failed to save settings. Please check your input.")
        {:noreply, socket}
    end
  end
  
  @impl true
  def handle_event("reset_to_defaults", _params, socket) do
    default_config = Config.default_config()
    
    socket = assign(socket,
      config: default_config,
      form: to_form(default_config),
      changes_saved: false
    )
    
    socket = put_flash(socket, :info, "Settings reset to defaults. Don't forget to save!")
    {:noreply, socket}
  end
  
  @impl true
  def handle_event("toggle_demo_mode", _params, socket) do
    new_demo_mode = not socket.assigns.demo_mode
    
    # Update application config
    Application.put_env(:selfspy_web, :demo_mode, new_demo_mode)
    
    socket = assign(socket, demo_mode: new_demo_mode)
    socket = put_flash(socket, :info, "Demo mode #{if new_demo_mode, do: "enabled", else: "disabled"}")
    
    {:noreply, socket}
  end
  
  @impl true
  def handle_event("export_settings", _params, socket) do
    config_json = Jason.encode!(socket.assigns.config, pretty: true)
    
    # In a real app, this would trigger a download
    socket = put_flash(socket, :info, "Settings exported (would download as JSON file)")
    {:noreply, socket}
  end
  
  @impl true
  def handle_event("import_settings", %{"settings_file" => file_content}, socket) do
    case Jason.decode(file_content) do
      {:ok, imported_config} ->
        socket = assign(socket,
          config: imported_config,
          form: to_form(imported_config),
          changes_saved: false
        )
        
        socket = put_flash(socket, :info, "Settings imported successfully. Review and save to apply.")
        {:noreply, socket}
        
      {:error, _} ->
        socket = put_flash(socket, :error, "Invalid settings file format")
        {:noreply, socket}
    end
  end
  
  @impl true
  def render(assigns) do
    ~H"""
    <div class="min-h-screen bg-gray-50 dark:bg-gray-900">
      <!-- Header -->
      <div class="bg-white dark:bg-gray-800 shadow">
        <div class="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
          <div class="flex justify-between items-center py-6">
            <div class="flex items-center">
              <h1 class="text-3xl font-bold text-gray-900 dark:text-white">
                ⚙️ Settings
              </h1>
            </div>
            
            <div class="flex items-center space-x-4">
              <.link navigate="/dashboard" class="px-4 py-2 bg-blue-600 hover:bg-blue-700 text-white rounded-md font-medium transition-colors">
                🏠 Dashboard
              </.link>
              
              <!-- Demo Mode Toggle -->
              <button
                phx-click="toggle_demo_mode"
                class={[
                  "px-3 py-1 rounded text-xs font-medium transition-colors",
                  if(@demo_mode,
                    do: "bg-yellow-100 text-yellow-800 dark:bg-yellow-900 dark:text-yellow-200",
                    else: "bg-gray-100 text-gray-800 dark:bg-gray-700 dark:text-gray-200"
                  )
                ]}
              >
                <%= if @demo_mode, do: "🎭 Demo Mode", else: "🔧 Live Mode" %>
              </button>
            </div>
          </div>
        </div>
      </div>
      
      <!-- Main Content -->
      <div class="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-8">
        <div class="grid grid-cols-1 lg:grid-cols-4 gap-8">
          <!-- Sidebar Navigation -->
          <div class="lg:col-span-1">
            <nav class="bg-white dark:bg-gray-800 rounded-lg shadow p-4">
              <ul class="space-y-2">
                <.nav_item
                  tab="general"
                  current_tab={@current_tab}
                  icon="🔧"
                  title="General"
                />
                <.nav_item
                  tab="privacy"
                  current_tab={@current_tab}
                  icon="🔒"
                  title="Privacy"
                />
                <.nav_item
                  tab="monitoring"
                  current_tab={@current_tab}
                  icon="👁️"
                  title="Monitoring"
                />
                <.nav_item
                  tab="data"
                  current_tab={@current_tab}
                  icon="💾"
                  title="Data & Storage"
                />
                <.nav_item
                  tab="advanced"
                  current_tab={@current_tab}
                  icon="⚡"
                  title="Advanced"
                />
              </ul>
            </nav>
          </div>
          
          <!-- Settings Content -->
          <div class="lg:col-span-3">
            <div class="bg-white dark:bg-gray-800 rounded-lg shadow">
              <.form for={@form} phx-submit="update_config" class="p-6">
                <!-- General Settings -->
                <%= if @current_tab == "general" do %>
                  <.settings_section title="🔧 General Settings">
                    <.input_group
                      field={@form[:app_name]}
                      label="Application Name"
                      type="text"
                      help="Display name for the application"
                    />
                    
                    <.input_group
                      field={@form[:data_directory]}
                      label="Data Directory"
                      type="text"
                      help="Where to store activity data and logs"
                    />
                    
                    <.input_group
                      field={@form[:log_level]}
                      label="Log Level"
                      type="select"
                      options={[
                        {"Debug", "debug"},
                        {"Info", "info"},
                        {"Warning", "warning"},
                        {"Error", "error"}
                      ]}
                      help="Minimum log level to record"
                    />
                    
                    <.checkbox_group
                      field={@form[:auto_start]}
                      label="Auto-start monitoring"
                      help="Automatically begin monitoring when the application starts"
                    />
                  </.settings_section>
                <% end %>
                
                <!-- Privacy Settings -->
                <%= if @current_tab == "privacy" do %>
                  <.settings_section title="🔒 Privacy & Security">
                    <.checkbox_group
                      field={@form[:encrypt_keystrokes]}
                      label="Encrypt keystroke data"
                      help="Store all typed text in encrypted format"
                    />
                    
                    <.input_group
                      field={@form[:password_chars]}
                      label="Password field characters"
                      type="text"
                      help="Characters to mask in password fields (e.g., ●••••)"
                    />
                    
                    <.input_group
                      field={@form[:excluded_apps]}
                      label="Excluded Applications"
                      type="textarea"
                      help="Applications to ignore (one per line)"
                    />
                    
                    <.input_group
                      field={@form[:excluded_titles]}
                      label="Excluded Window Titles"
                      type="textarea"
                      help="Window title patterns to ignore (supports regex)"
                    />
                    
                    <.checkbox_group
                      field={@form[:incognito_mode]}
                      label="Incognito mode for private browsing"
                      help="Don't track activity in private/incognito browser windows"
                    />
                  </.settings_section>
                <% end %>
                
                <!-- Monitoring Settings -->
                <%= if @current_tab == "monitoring" do %>
                  <.settings_section title="👁️ Monitoring Configuration">
                    <.checkbox_group
                      field={@form[:track_keystrokes]}
                      label="Track keystrokes"
                      help="Monitor keyboard input"
                    />
                    
                    <.checkbox_group
                      field={@form[:track_mouse]}
                      label="Track mouse activity"
                      help="Monitor mouse clicks and movements"
                    />
                    
                    <.checkbox_group
                      field={@form[:track_windows]}
                      label="Track window changes"
                      help="Monitor active window switches"
                    />
                    
                    <.checkbox_group
                      field={@form[:track_terminal]}
                      label="Track terminal commands"
                      help="Monitor shell command history"
                    />
                    
                    <.input_group
                      field={@form[:idle_timeout]}
                      label="Idle timeout (seconds)"
                      type="number"
                      help="Consider user idle after this many seconds of inactivity"
                    />
                    
                    <.input_group
                      field={@form[:flush_interval]}
                      label="Data flush interval (seconds)"
                      type="number"
                      help="How often to write buffered data to database"
                    />
                  </.settings_section>
                <% end %>
                
                <!-- Data & Storage Settings -->
                <%= if @current_tab == "data" do %>
                  <.settings_section title="💾 Data & Storage">
                    <.input_group
                      field={@form[:retention_days]}
                      label="Data retention (days)"
                      type="number"
                      help="Automatically delete data older than this many days (0 = never)"
                    />
                    
                    <.input_group
                      field={@form[:max_db_size_mb]}
                      label="Maximum database size (MB)"
                      type="number"
                      help="Alert when database exceeds this size"
                    />
                    
                    <.checkbox_group
                      field={@form[:compress_old_data]}
                      label="Compress old data"
                      help="Compress data older than 30 days to save space"
                    />
                    
                    <.input_group
                      field={@form[:backup_interval_days]}
                      label="Backup interval (days)"
                      type="number"
                      help="Automatically backup database every N days"
                    />
                    
                    <.input_group
                      field={@form[:export_format]}
                      label="Default export format"
                      type="select"
                      options={[
                        {"JSON", "json"},
                        {"CSV", "csv"},
                        {"SQLite", "sqlite"}
                      ]}
                      help="Default format for data exports"
                    />
                  </.settings_section>
                <% end %>
                
                <!-- Advanced Settings -->
                <%= if @current_tab == "advanced" do %>
                  <.settings_section title="⚡ Advanced Configuration">
                    <.input_group
                      field={@form[:buffer_size]}
                      label="Activity buffer size"
                      type="number"
                      help="Number of events to buffer before writing to database"
                    />
                    
                    <.input_group
                      field={@form[:worker_pool_size]}
                      label="Worker pool size"
                      type="number"
                      help="Number of background worker processes"
                    />
                    
                    <.checkbox_group
                      field={@form[:enable_telemetry]}
                      label="Enable telemetry"
                      help="Collect anonymous usage statistics and performance metrics"
                    />
                    
                    <.checkbox_group
                      field={@form[:debug_mode]}
                      label="Debug mode"
                      help="Enable detailed logging and debug features"
                    />
                    
                    <.input_group
                      field={@form[:custom_plugins]}
                      label="Custom plugins directory"
                      type="text"
                      help="Directory to load custom monitoring plugins"
                    />
                  </.settings_section>
                <% end %>
                
                <!-- Action Buttons -->
                <div class="flex items-center justify-between pt-6 border-t border-gray-200 dark:border-gray-700">
                  <div class="flex space-x-3">
                    <button
                      type="button"
                      phx-click="reset_to_defaults"
                      class="px-4 py-2 bg-gray-600 hover:bg-gray-700 text-white rounded-md font-medium transition-colors"
                    >
                      🔄 Reset to Defaults
                    </button>
                    
                    <button
                      type="button"
                      phx-click="export_settings"
                      class="px-4 py-2 bg-blue-600 hover:bg-blue-700 text-white rounded-md font-medium transition-colors"
                    >
                      📤 Export Settings
                    </button>
                  </div>
                  
                  <div class="flex space-x-3">
                    <button
                      type="submit"
                      class="px-6 py-2 bg-green-600 hover:bg-green-700 text-white rounded-md font-medium transition-colors"
                    >
                      💾 Save Settings
                    </button>
                  </div>
                </div>
              </.form>
            </div>
          </div>
        </div>
      </div>
    </div>
    """
  end
  
  # Components
  
  defp nav_item(assigns) do
    ~H"""
    <li>
      <button
        phx-click="change_tab"
        phx-value-tab={@tab}
        class={[
          "w-full text-left px-3 py-2 rounded-md text-sm font-medium transition-colors",
          if(@tab == @current_tab,
            do: "bg-blue-100 text-blue-700 dark:bg-blue-900 dark:text-blue-200",
            else: "text-gray-700 hover:bg-gray-100 dark:text-gray-300 dark:hover:bg-gray-700"
          )
        ]}
      >
        <%= @icon %> <%= @title %>
      </button>
    </li>
    """
  end
  
  defp settings_section(assigns) do
    ~H"""
    <div class="mb-8">
      <h2 class="text-xl font-semibold text-gray-900 dark:text-white mb-6">
        <%= @title %>
      </h2>
      <div class="space-y-6">
        <%= render_slot(@inner_block) %>
      </div>
    </div>
    """
  end
  
  defp input_group(assigns) do
    ~H"""
    <div>
      <%= if assigns[:label] do %>
        <label class="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-2">
          <%= @label %>
        </label>
      <% end %>
      
      <%= if @type == "select" do %>
        <.input
          field={@field}
          type="select"
          options={@options}
          class="w-full px-3 py-2 border border-gray-300 dark:border-gray-600 rounded-md shadow-sm focus:ring-blue-500 focus:border-blue-500 dark:bg-gray-700 dark:text-white"
        />
      <% else %>
        <.input
          field={@field}
          type={@type}
          class={[
            "w-full px-3 py-2 border border-gray-300 dark:border-gray-600 rounded-md shadow-sm focus:ring-blue-500 focus:border-blue-500 dark:bg-gray-700 dark:text-white",
            if(@type == "textarea", do: "h-24", else: "")
          ]}
        />
      <% end %>
      
      <%= if assigns[:help] do %>
        <p class="mt-1 text-sm text-gray-500 dark:text-gray-400">
          <%= @help %>
        </p>
      <% end %>
    </div>
    """
  end
  
  defp checkbox_group(assigns) do
    ~H"""
    <div class="flex items-start">
      <div class="flex items-center h-5">
        <.input
          field={@field}
          type="checkbox"
          class="w-4 h-4 text-blue-600 bg-gray-100 border-gray-300 rounded focus:ring-blue-500 dark:focus:ring-blue-600 dark:ring-offset-gray-800 focus:ring-2 dark:bg-gray-700 dark:border-gray-600"
        />
      </div>
      <div class="ml-3">
        <label class="text-sm font-medium text-gray-700 dark:text-gray-300">
          <%= @label %>
        </label>
        <%= if assigns[:help] do %>
          <p class="text-sm text-gray-500 dark:text-gray-400">
            <%= @help %>
          </p>
        <% end %>
      </div>
    </div>
    """
  end
  
  # Helper Functions
  
  defp get_monitoring_status do
    try do
      case Process.whereis(ActivityMonitor) do
        nil -> false
        _pid -> ActivityMonitor.get_status().monitoring_active
      end
    rescue
      _ -> false
    end
  end
end