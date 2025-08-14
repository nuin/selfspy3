defmodule SelfspyWeb.Schemas.Activity do
  @moduledoc """
  Ecto schemas for activity monitoring data models.
  
  These schemas represent the core data structures for selfspy activity tracking:
  - Process: Applications being monitored
  - Window: Window metadata and state
  - Keystroke: Encrypted keystroke data
  - Click: Mouse click events
  - Terminal: Terminal session and command tracking
  """
  
  use Ecto.Schema
  import Ecto.Changeset
  
  # Process Schema - represents applications/processes being monitored
  defmodule Process do
    use Ecto.Schema
    import Ecto.Changeset
    
    @primary_key {:id, :id, autogenerate: true}
    
    schema "processes" do
      field :name, :string
      field :pid, :integer
      field :bundle_id, :string  # macOS bundle identifier
      field :executable_path, :string
      field :command_line, :string
      field :created_at, :utc_datetime
      
      # Relationships
      has_many :windows, SelfspyWeb.Schemas.Activity.Window
      has_many :keystrokes, SelfspyWeb.Schemas.Activity.Keystroke
      has_many :clicks, SelfspyWeb.Schemas.Activity.Click
      
      timestamps(type: :utc_datetime)
    end
    
    def changeset(process, attrs) do
      process
      |> cast(attrs, [:name, :pid, :bundle_id, :executable_path, :command_line, :created_at])
      |> validate_required([:name])
      |> validate_length(:name, min: 1, max: 255)
      |> validate_number(:pid, greater_than: 0)
    end
  end
  
  # Window Schema - represents application windows
  defmodule Window do
    use Ecto.Schema
    import Ecto.Changeset
    
    @primary_key {:id, :id, autogenerate: true}
    
    schema "windows" do
      field :title, :string
      field :x, :integer, default: 0
      field :y, :integer, default: 0
      field :width, :integer, default: 0
      field :height, :integer, default: 0
      field :screen_width, :integer
      field :screen_height, :integer
      field :is_active, :boolean, default: false
      field :is_visible, :boolean, default: true
      field :created_at, :utc_datetime
      
      # Foreign keys
      belongs_to :process, SelfspyWeb.Schemas.Activity.Process
      
      # Relationships  
      has_many :keystrokes, SelfspyWeb.Schemas.Activity.Keystroke
      has_many :clicks, SelfspyWeb.Schemas.Activity.Click
      
      timestamps(type: :utc_datetime)
    end
    
    def changeset(window, attrs) do
      window
      |> cast(attrs, [:title, :x, :y, :width, :height, :screen_width, :screen_height, 
                      :is_active, :is_visible, :created_at, :process_id])
      |> validate_required([:process_id])
      |> validate_length(:title, max: 500)
      |> validate_number(:x, greater_than_or_equal_to: 0)
      |> validate_number(:y, greater_than_or_equal_to: 0)
      |> validate_number(:width, greater_than_or_equal_to: 0)
      |> validate_number(:height, greater_than_or_equal_to: 0)
      |> foreign_key_constraint(:process_id)
    end
  end
  
  # Keystroke Schema - encrypted keystroke data
  defmodule Keystroke do
    use Ecto.Schema
    import Ecto.Changeset
    
    @primary_key {:id, :id, autogenerate: true}
    
    schema "keystrokes" do
      field :encrypted_text, :binary
      field :key_count, :integer, default: 1
      field :special_keys, {:array, :string}, default: []
      field :modifier_keys, {:array, :string}, default: []
      field :is_encrypted, :boolean, default: true
      field :recorded_at, :utc_datetime
      
      # Foreign keys
      belongs_to :process, SelfspyWeb.Schemas.Activity.Process
      belongs_to :window, SelfspyWeb.Schemas.Activity.Window
      
      timestamps(type: :utc_datetime)
    end
    
    def changeset(keystroke, attrs) do
      keystroke
      |> cast(attrs, [:encrypted_text, :key_count, :special_keys, :modifier_keys, 
                      :is_encrypted, :recorded_at, :process_id, :window_id])
      |> validate_required([:recorded_at, :process_id, :window_id])
      |> validate_number(:key_count, greater_than: 0)
      |> foreign_key_constraint(:process_id)
      |> foreign_key_constraint(:window_id)
    end
  end
  
  # Click Schema - mouse click events
  defmodule Click do
    use Ecto.Schema
    import Ecto.Changeset
    
    @primary_key {:id, :id, autogenerate: true}
    
    schema "clicks" do
      field :x, :float
      field :y, :float
      field :button, :string  # "left", "right", "middle", "scroll_up", "scroll_down"
      field :click_count, :integer, default: 1
      field :pressure, :float, default: 1.0  # For pressure-sensitive devices
      field :movement_delta_x, :float, default: 0.0
      field :movement_delta_y, :float, default: 0.0
      field :recorded_at, :utc_datetime
      
      # Foreign keys
      belongs_to :process, SelfspyWeb.Schemas.Activity.Process
      belongs_to :window, SelfspyWeb.Schemas.Activity.Window
      
      timestamps(type: :utc_datetime)
    end
    
    def changeset(click, attrs) do
      click
      |> cast(attrs, [:x, :y, :button, :click_count, :pressure, :movement_delta_x, 
                      :movement_delta_y, :recorded_at, :process_id, :window_id])
      |> validate_required([:x, :y, :button, :recorded_at, :process_id, :window_id])
      |> validate_inclusion(:button, ["left", "right", "middle", "scroll_up", "scroll_down"])
      |> validate_number(:click_count, greater_than: 0)
      |> validate_number(:pressure, greater_than: 0.0, less_than_or_equal_to: 1.0)
      |> foreign_key_constraint(:process_id)
      |> foreign_key_constraint(:window_id)
    end
  end
  
  # Terminal Session Schema - terminal session metadata
  defmodule TerminalSession do
    use Ecto.Schema
    import Ecto.Changeset
    
    @primary_key {:id, :id, autogenerate: true}
    
    schema "terminal_sessions" do
      field :shell_type, :string  # "bash", "zsh", "fish", etc.
      field :shell_version, :string
      field :working_directory, :string
      field :session_id, :string
      field :started_at, :utc_datetime
      field :ended_at, :utc_datetime
      field :is_active, :boolean, default: true
      
      # Relationships
      has_many :commands, SelfspyWeb.Schemas.Activity.TerminalCommand
      
      timestamps(type: :utc_datetime)
    end
    
    def changeset(session, attrs) do
      session
      |> cast(attrs, [:shell_type, :shell_version, :working_directory, :session_id, 
                      :started_at, :ended_at, :is_active])
      |> validate_required([:shell_type, :working_directory, :started_at])
      |> validate_length(:shell_type, min: 1, max: 50)
      |> validate_length(:working_directory, min: 1, max: 1000)
      |> unique_constraint(:session_id)
    end
  end
  
  # Terminal Command Schema - individual commands with context
  defmodule TerminalCommand do
    use Ecto.Schema
    import Ecto.Changeset
    
    @primary_key {:id, :id, autogenerate: true}
    
    schema "terminal_commands" do
      field :command, :string
      field :command_type, :string  # "git", "npm", "python", "system", etc.
      field :working_directory, :string
      field :git_branch, :string
      field :project_type, :string  # "nodejs", "python", "rust", "elixir", etc.
      field :exit_code, :integer
      field :duration_ms, :integer
      field :executed_at, :utc_datetime
      
      # Foreign keys
      belongs_to :session, SelfspyWeb.Schemas.Activity.TerminalSession
      
      timestamps(type: :utc_datetime)
    end
    
    def changeset(command, attrs) do
      command
      |> cast(attrs, [:command, :command_type, :working_directory, :git_branch, 
                      :project_type, :exit_code, :duration_ms, :executed_at, :session_id])
      |> validate_required([:command, :working_directory, :executed_at, :session_id])
      |> validate_length(:command, min: 1, max: 2000)
      |> validate_length(:working_directory, min: 1, max: 1000)
      |> validate_number(:exit_code, greater_than_or_equal_to: 0)
      |> validate_number(:duration_ms, greater_than_or_equal_to: 0)
      |> foreign_key_constraint(:session_id)
    end
  end
end