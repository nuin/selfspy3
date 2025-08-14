defmodule SelfspyWeb.Repo.Migrations.CreateActivityTables do
  @moduledoc """
  Creates the database tables for selfspy activity monitoring.
  
  This migration creates all the necessary tables for storing:
  - Process information
  - Window metadata
  - Encrypted keystroke data
  - Mouse click events
  - Terminal sessions and commands
  """
  
  use Ecto.Migration

  def up do
    # Enable UUID extension for PostgreSQL
    execute "CREATE EXTENSION IF NOT EXISTS \"uuid-ossp\""
    
    # Create processes table
    create table(:processes) do
      add :name, :string, null: false, size: 255
      add :pid, :integer
      add :bundle_id, :string, size: 255
      add :executable_path, :text
      add :command_line, :text
      add :created_at, :utc_datetime
      
      timestamps(type: :utc_datetime)
    end
    
    create index(:processes, [:name])
    create index(:processes, [:pid])
    create index(:processes, [:bundle_id])
    create index(:processes, [:created_at])
    
    # Create windows table
    create table(:windows) do
      add :title, :string, size: 500
      add :x, :integer, default: 0
      add :y, :integer, default: 0
      add :width, :integer, default: 0
      add :height, :integer, default: 0
      add :screen_width, :integer
      add :screen_height, :integer
      add :is_active, :boolean, default: false
      add :is_visible, :boolean, default: true
      add :created_at, :utc_datetime
      add :process_id, references(:processes, on_delete: :cascade), null: false
      
      timestamps(type: :utc_datetime)
    end
    
    create index(:windows, [:process_id])
    create index(:windows, [:is_active])
    create index(:windows, [:created_at])
    create index(:windows, [:title])
    
    # Create keystrokes table
    create table(:keystrokes) do
      add :encrypted_text, :binary
      add :key_count, :integer, default: 1
      add :special_keys, {:array, :string}, default: []
      add :modifier_keys, {:array, :string}, default: []
      add :is_encrypted, :boolean, default: true
      add :recorded_at, :utc_datetime, null: false
      add :process_id, references(:processes, on_delete: :cascade), null: false
      add :window_id, references(:windows, on_delete: :cascade), null: false
      
      timestamps(type: :utc_datetime)
    end
    
    create index(:keystrokes, [:process_id])
    create index(:keystrokes, [:window_id])
    create index(:keystrokes, [:recorded_at])
    create index(:keystrokes, [:is_encrypted])
    
    # Create clicks table
    create table(:clicks) do
      add :x, :float, null: false
      add :y, :float, null: false
      add :button, :string, null: false, size: 20
      add :click_count, :integer, default: 1
      add :pressure, :float, default: 1.0
      add :movement_delta_x, :float, default: 0.0
      add :movement_delta_y, :float, default: 0.0
      add :recorded_at, :utc_datetime, null: false
      add :process_id, references(:processes, on_delete: :cascade), null: false
      add :window_id, references(:windows, on_delete: :cascade), null: false
      
      timestamps(type: :utc_datetime)
    end
    
    create index(:clicks, [:process_id])
    create index(:clicks, [:window_id])
    create index(:clicks, [:recorded_at])
    create index(:clicks, [:button])
    create index(:clicks, [:x, :y])
    
    # Create terminal_sessions table
    create table(:terminal_sessions) do
      add :shell_type, :string, null: false, size: 50
      add :shell_version, :string, size: 50
      add :working_directory, :string, null: false, size: 1000
      add :session_id, :string, size: 255
      add :started_at, :utc_datetime, null: false
      add :ended_at, :utc_datetime
      add :is_active, :boolean, default: true
      
      timestamps(type: :utc_datetime)
    end
    
    create index(:terminal_sessions, [:shell_type])
    create index(:terminal_sessions, [:working_directory])
    create index(:terminal_sessions, [:session_id])
    create index(:terminal_sessions, [:started_at])
    create index(:terminal_sessions, [:is_active])
    create unique_index(:terminal_sessions, [:session_id])
    
    # Create terminal_commands table
    create table(:terminal_commands) do
      add :command, :text, null: false
      add :command_type, :string, size: 50
      add :working_directory, :string, null: false, size: 1000
      add :git_branch, :string, size: 255
      add :project_type, :string, size: 50
      add :exit_code, :integer
      add :duration_ms, :integer
      add :executed_at, :utc_datetime, null: false
      add :session_id, references(:terminal_sessions, on_delete: :cascade), null: false
      
      timestamps(type: :utc_datetime)
    end
    
    create index(:terminal_commands, [:session_id])
    create index(:terminal_commands, [:command_type])
    create index(:terminal_commands, [:working_directory])
    create index(:terminal_commands, [:git_branch])
    create index(:terminal_commands, [:project_type])
    create index(:terminal_commands, [:executed_at])
    create index(:terminal_commands, [:exit_code])
    
    # Create composite indexes for common queries
    create index(:keystrokes, [:process_id, :recorded_at])
    create index(:clicks, [:process_id, :recorded_at])
    create index(:terminal_commands, [:working_directory, :executed_at])
    create index(:terminal_commands, [:command_type, :executed_at])
  end

  def down do
    drop table(:terminal_commands)
    drop table(:terminal_sessions)
    drop table(:clicks)
    drop table(:keystrokes)
    drop table(:windows)
    drop table(:processes)
    
    # Drop UUID extension if no other tables use it
    execute "DROP EXTENSION IF EXISTS \"uuid-ossp\""
  end
end