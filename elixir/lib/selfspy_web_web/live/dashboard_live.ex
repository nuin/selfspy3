defmodule SelfspyWebWeb.DashboardLive do
  @moduledoc """
  Phoenix LiveView for the main activity monitoring dashboard.
  
  Provides real-time updates of monitoring status, activity statistics,
  and live charts showing current activity patterns.
  """
  
  use SelfspyWebWeb, :live_view
  require Logger
  
  alias SelfspyWeb.Monitor.ActivityMonitor
  alias Phoenix.PubSub
  
  @impl true
  def mount(_params, _session, socket) do
    if connected?(socket) do
      # Subscribe to activity monitor updates
      PubSub.subscribe(SelfspyWeb.PubSub, "activity_monitor")
      
      # Schedule periodic updates
      :timer.send_interval(1000, self(), :update_stats)
    end
    
    # Get initial status
    initial_status = get_monitor_status()
    initial_stats = get_activity_stats()
    
    socket = assign(socket,
      monitoring_active: initial_status.monitoring_active,
      status: initial_status,
      stats: initial_stats,
      live_data: %{
        keystrokes_per_minute: 0,
        clicks_per_minute: 0,
        active_windows: 0,
        current_window: "Loading..."
      },
      chart_data: generate_sample_chart_data(),
      last_update: DateTime.utc_now()
    )
    
    {:ok, socket}
  end
  
  @impl true
  def handle_info({:status_change, status}, socket) do
    Logger.info("Monitor status changed: #{status}")
    
    socket = assign(socket,
      monitoring_active: status == :started,
      last_update: DateTime.utc_now()
    )
    
    {:noreply, socket}
  end
  
  @impl true
  def handle_info({:data_update, stats}, socket) do
    socket = assign(socket,
      stats: stats,
      last_update: DateTime.utc_now()
    )
    
    {:noreply, socket}
  end
  
  @impl true
  def handle_info(:update_stats, socket) do
    new_stats = get_activity_stats()
    new_live_data = calculate_live_metrics(new_stats, socket.assigns.stats)
    
    socket = assign(socket,
      stats: new_stats,
      live_data: new_live_data,
      chart_data: update_chart_data(socket.assigns.chart_data),
      last_update: DateTime.utc_now()
    )
    
    {:noreply, socket}
  end
  
  @impl true
  def handle_event("toggle_monitoring", _params, socket) do
    result = if socket.assigns.monitoring_active do
      ActivityMonitor.stop_monitoring()
    else
      ActivityMonitor.start_monitoring()
    end
    
    case result do
      :ok ->
        {:noreply, socket}
      {:error, reason} ->
        socket = put_flash(socket, :error, "Failed to toggle monitoring: #{inspect(reason)}")
        {:noreply, socket}
    end
  end
  
  @impl true
  def handle_event("refresh_data", _params, socket) do
    status = get_monitor_status()
    stats = get_activity_stats()
    
    socket = assign(socket,
      status: status,
      stats: stats,
      monitoring_active: status.monitoring_active,
      last_update: DateTime.utc_now()
    )
    
    {:noreply, socket}
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
                🔍 Selfspy Dashboard
              </h1>
            </div>
            
            <div class="flex items-center space-x-4">
              <!-- Settings Link -->
              <.link navigate="/settings" class="px-4 py-2 bg-gray-600 hover:bg-gray-700 text-white rounded-md font-medium transition-colors">
                ⚙️ Settings
              </.link>
              
              <!-- Monitoring Toggle -->
              <button
                phx-click="toggle_monitoring"
                class={[
                  "px-4 py-2 rounded-md font-medium transition-colors",
                  if(@monitoring_active,
                    do: "bg-red-600 hover:bg-red-700 text-white",
                    else: "bg-green-600 hover:bg-green-700 text-white"
                  )
                ]}
              >
                <%= if @monitoring_active do %>
                  ⏹ Stop Monitoring
                <% else %>
                  ▶ Start Monitoring
                <% end %>
              </button>
              
              <!-- Refresh Button -->
              <button
                phx-click="refresh_data"
                class="px-4 py-2 bg-blue-600 hover:bg-blue-700 text-white rounded-md font-medium transition-colors"
              >
                🔄 Refresh
              </button>
              
              <!-- Status Indicator -->
              <div class="flex items-center space-x-2">
                <div class={[
                  "w-3 h-3 rounded-full",
                  if(@monitoring_active,
                    do: "bg-green-500 animate-pulse",
                    else: "bg-red-500"
                  )
                ]}></div>
                <span class="text-sm font-medium text-gray-700 dark:text-gray-300">
                  <%= if @monitoring_active, do: "Active", else: "Inactive" %>
                </span>
              </div>
            </div>
          </div>
        </div>
      </div>
      
      <!-- Main Content -->
      <div class="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-8">
        <!-- Stats Cards -->
        <div class="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-6 mb-8">
          <.stat_card
            title="Keystrokes"
            value={@stats.keystrokes_count || 0}
            icon="⌨️"
            color="blue"
            subtitle="per minute: #{@live_data.keystrokes_per_minute}"
          />
          
          <.stat_card
            title="Mouse Clicks"
            value={@stats.clicks_count || 0}
            icon="🖱️"
            color="green"
            subtitle="per minute: #{@live_data.clicks_per_minute}"
          />
          
          <.stat_card
            title="Windows"
            value={@stats.windows_count || 0}
            icon="🪟"
            color="purple"
            subtitle="active: #{@live_data.active_windows}"
          />
          
          <.stat_card
            title="Sessions"
            value={1}
            icon="⏱️"
            color="orange"
            subtitle={format_uptime(@stats.started_at)}
          />
        </div>
        
        <!-- Live Activity Chart -->
        <div class="bg-white dark:bg-gray-800 rounded-lg shadow p-6 mb-8">
          <h2 class="text-xl font-semibold text-gray-900 dark:text-white mb-4">
            📈 Live Activity
          </h2>
          
          <div class="h-64" id="activity-chart" phx-hook="ActivityChart" data-chart={Jason.encode!(@chart_data)}>
            <!-- Chart will be rendered here by JavaScript -->
            <div class="flex items-center justify-center h-full">
              <div class="text-gray-500 dark:text-gray-400">
                <div class="animate-spin rounded-full h-8 w-8 border-b-2 border-blue-600 mx-auto mb-2"></div>
                Loading chart...
              </div>
            </div>
          </div>
        </div>
        
        <!-- Current Activity -->
        <div class="grid grid-cols-1 lg:grid-cols-2 gap-6">
          <!-- Active Window -->
          <div class="bg-white dark:bg-gray-800 rounded-lg shadow p-6">
            <h3 class="text-lg font-semibold text-gray-900 dark:text-white mb-4">
              🪟 Current Window
            </h3>
            
            <div class="space-y-3">
              <div>
                <span class="text-sm font-medium text-gray-500 dark:text-gray-400">Title:</span>
                <p class="text-gray-900 dark:text-white"><%= @live_data.current_window %></p>
              </div>
              
              <div>
                <span class="text-sm font-medium text-gray-500 dark:text-gray-400">Process:</span>
                <p class="text-gray-900 dark:text-white">SelfspyWeb Demo</p>
              </div>
              
              <div>
                <span class="text-sm font-medium text-gray-500 dark:text-gray-400">Last Activity:</span>
                <p class="text-gray-900 dark:text-white">
                  <%= if @stats.last_activity do %>
                    <%= format_relative_time(@stats.last_activity) %>
                  <% else %>
                    Never
                  <% end %>
                </p>
              </div>
            </div>
          </div>
          
          <!-- System Status -->
          <div class="bg-white dark:bg-gray-800 rounded-lg shadow p-6">
            <h3 class="text-lg font-semibold text-gray-900 dark:text-white mb-4">
              ⚙️ System Status
            </h3>
            
            <div class="space-y-3">
              <div class="flex justify-between items-center">
                <span class="text-sm font-medium text-gray-500 dark:text-gray-400">Keyboard Monitor:</span>
                <span class={[
                  "px-2 py-1 rounded text-xs font-medium",
                  if(@monitoring_active,
                    do: "bg-green-100 text-green-800 dark:bg-green-900 dark:text-green-200",
                    else: "bg-red-100 text-red-800 dark:bg-red-900 dark:text-red-200"
                  )
                ]}>
                  <%= if @monitoring_active, do: "Active", else: "Inactive" %>
                </span>
              </div>
              
              <div class="flex justify-between items-center">
                <span class="text-sm font-medium text-gray-500 dark:text-gray-400">Mouse Monitor:</span>
                <span class={[
                  "px-2 py-1 rounded text-xs font-medium",
                  if(@monitoring_active,
                    do: "bg-green-100 text-green-800 dark:bg-green-900 dark:text-green-200",
                    else: "bg-red-100 text-red-800 dark:bg-red-900 dark:text-red-200"
                  )
                ]}>
                  <%= if @monitoring_active, do: "Active", else: "Inactive" %>
                </span>
              </div>
              
              <div class="flex justify-between items-center">
                <span class="text-sm font-medium text-gray-500 dark:text-gray-400">Window Monitor:</span>
                <span class={[
                  "px-2 py-1 rounded text-xs font-medium",
                  if(@monitoring_active,
                    do: "bg-green-100 text-green-800 dark:bg-green-900 dark:text-green-200",
                    else: "bg-red-100 text-red-800 dark:bg-red-900 dark:text-red-200"
                  )
                ]}>
                  <%= if @monitoring_active, do: "Active", else: "Inactive" %>
                </span>
              </div>
              
              <div class="pt-2 border-t border-gray-200 dark:border-gray-700">
                <span class="text-sm font-medium text-gray-500 dark:text-gray-400">Last Update:</span>
                <p class="text-gray-900 dark:text-white text-sm">
                  <%= format_relative_time(@last_update) %>
                </p>
              </div>
            </div>
          </div>
        </div>
      </div>
    </div>
    """
  end
  
  # Components
  
  defp stat_card(assigns) do
    ~H"""
    <div class="bg-white dark:bg-gray-800 rounded-lg shadow p-6">
      <div class="flex items-center">
        <div class="flex-shrink-0">
          <div class={[
            "w-8 h-8 rounded-md flex items-center justify-center text-white text-lg",
            stat_card_color(@color)
          ]}>
            <%= @icon %>
          </div>
        </div>
        
        <div class="ml-4 flex-1">
          <p class="text-sm font-medium text-gray-500 dark:text-gray-400 truncate">
            <%= @title %>
          </p>
          <p class="text-2xl font-semibold text-gray-900 dark:text-white">
            <%= format_number(@value) %>
          </p>
          <%= if assigns[:subtitle] do %>
            <p class="text-xs text-gray-500 dark:text-gray-400">
              <%= @subtitle %>
            </p>
          <% end %>
        </div>
      </div>
    </div>
    """
  end
  
  # Helper Functions
  
  defp stat_card_color("blue"), do: "bg-blue-500"
  defp stat_card_color("green"), do: "bg-green-500"
  defp stat_card_color("purple"), do: "bg-purple-500"
  defp stat_card_color("orange"), do: "bg-orange-500"
  defp stat_card_color(_), do: "bg-gray-500"
  
  defp get_monitor_status do
    try do
      case Process.whereis(ActivityMonitor) do
        nil ->
          %{monitoring_active: false, stats: %{}, buffer_size: 0, monitors: []}
        _pid ->
          ActivityMonitor.get_status()
      end
    rescue
      _ ->
        %{monitoring_active: false, stats: %{}, buffer_size: 0, monitors: []}
    end
  end
  
  defp get_activity_stats do
    try do
      case Process.whereis(ActivityMonitor) do
        nil ->
          %{keystrokes_count: 0, clicks_count: 0, windows_count: 0, started_at: nil, last_activity: nil}
        _pid ->
          ActivityMonitor.get_stats()
      end
    rescue
      _ ->
        %{keystrokes_count: 0, clicks_count: 0, windows_count: 0, started_at: nil, last_activity: nil}
    end
  end
  
  defp calculate_live_metrics(new_stats, old_stats) do
    time_diff = 60  # Assume 1 minute for rate calculation
    
    keystrokes_diff = (new_stats.keystrokes_count || 0) - (old_stats.keystrokes_count || 0)
    clicks_diff = (new_stats.clicks_count || 0) - (old_stats.clicks_count || 0)
    
    %{
      keystrokes_per_minute: max(0, div(keystrokes_diff, time_diff)),
      clicks_per_minute: max(0, div(clicks_diff, time_diff)),
      active_windows: 1,
      current_window: "Phoenix LiveView Dashboard - Selfspy"
    }
  end
  
  defp generate_sample_chart_data do
    now = DateTime.utc_now()
    
    # Generate sample data for the last hour
    Enum.map(0..59, fn minutes_ago ->
      timestamp = DateTime.add(now, -minutes_ago * 60, :second)
      
      %{
        timestamp: DateTime.to_iso8601(timestamp),
        keystrokes: :rand.uniform(50),
        clicks: :rand.uniform(20),
        active_time: :rand.uniform(100)
      }
    end)
    |> Enum.reverse()
  end
  
  defp update_chart_data(existing_data) do
    # Add new data point and remove oldest
    new_point = %{
      timestamp: DateTime.to_iso8601(DateTime.utc_now()),
      keystrokes: :rand.uniform(50),
      clicks: :rand.uniform(20),
      active_time: :rand.uniform(100)
    }
    
    [new_point | Enum.take(existing_data, 59)]
  end
  
  defp format_number(num) when num >= 1_000_000 do
    "#{Float.round(num / 1_000_000, 1)}M"
  end
  
  defp format_number(num) when num >= 1_000 do
    "#{Float.round(num / 1_000, 1)}K"
  end
  
  defp format_number(num), do: to_string(num)
  
  defp format_uptime(nil), do: "Not started"
  
  defp format_uptime(started_at) do
    diff = DateTime.diff(DateTime.utc_now(), started_at, :second)
    
    cond do
      diff < 60 -> "#{diff}s"
      diff < 3600 -> "#{div(diff, 60)}m"
      diff < 86400 -> "#{div(diff, 3600)}h #{div(rem(diff, 3600), 60)}m"
      true -> "#{div(diff, 86400)}d #{div(rem(diff, 86400), 3600)}h"
    end
  end
  
  defp format_relative_time(datetime) do
    diff = DateTime.diff(DateTime.utc_now(), datetime, :second)
    
    cond do
      diff < 60 -> "#{diff} seconds ago"
      diff < 3600 -> "#{div(diff, 60)} minutes ago"
      diff < 86400 -> "#{div(diff, 3600)} hours ago"
      true -> "#{div(diff, 86400)} days ago"
    end
  end
end