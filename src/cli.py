# src/cli.py
"""
Modern CLI interface for Selfspy using Typer
"""
import os
import asyncio
import signal
from pathlib import Path
from typing import Optional

import typer
from rich.console import Console
from rich.traceback import install
from rich.table import Table

from .activity_monitor import ActivityMonitor, verify_permissions
from .activity_store import ActivityStore
from .config import Settings
from .password_dialog import get_password
from .stats import app as stats_app

# Initialize Typer app and Rich console
app = typer.Typer(help="Selfspy - Monitor and analyze your computer activity")
console = Console()

# Install Rich traceback handler
install(show_locals=True)

app.add_typer(stats_app, name="stats", help="View activity statistics")

@app.command()
def start(
    data_dir: Path = typer.Option(None, "--data-dir", "-d", help="Data directory"),
    password: Optional[str] = typer.Option(None, "--password", "-p", help="Password"),
    no_text: bool = typer.Option(False, "--no-text", help="Don't store text"),
    debug: bool = typer.Option(False, "--debug", help="Enable debug logging"),
):
    """Start monitoring computer activity."""
    try:
        settings = Settings(
            data_dir=data_dir if data_dir else Settings().data_dir,
            encryption_enabled=not no_text,
            debug=debug
        )
        
        if settings.encryption_enabled and not password:
            password = get_password()
            
        store = ActivityStore(settings, password)
        monitor = ActivityMonitor(settings, store, debug)
        
        console.print("[green]Starting Selfspy monitor...[/green]")
        
        loop = asyncio.new_event_loop()
        asyncio.set_event_loop(loop)
        
        def signal_handler(signum, frame):
            if monitor.running:
                loop.create_task(monitor.stop())
                loop.stop()
        
        for sig in (signal.SIGTERM, signal.SIGINT):
            signal.signal(sig, signal_handler)
        
        try:
            loop.run_until_complete(monitor.start())
        except PermissionError as e:
            console.print("\n[red]⚠️  Permission Error[/red]")
            console.print(str(e))
            console.print("\nTo fix this, run: [cyan]selfspy check-permissions[/cyan]")
            return 1
        except Exception as e:
            console.print(f"\n[red]Error: {str(e)}[/red]")
            return 1
        finally:
            if loop.is_running():
                loop.stop()
            loop.close()
            
    except KeyboardInterrupt:
        console.print("\n[yellow]Shutting down gracefully...[/yellow]")
        return 0
    except Exception as e:
        console.print(f"\n[red]Error: {str(e)}[/red]")
        return 1

@app.command()
def stats(
    data_dir: Path = typer.Option(
        None,
        "--data-dir", "-d",
        help="Data directory containing the database"
    ),
    start_date: str = typer.Option(
        None,
        "--start", "-s",
        help="Start date (YYYY-MM-DD)"
    ),
    end_date: str = typer.Option(
        None,
        "--end", "-e",
        help="End date (YYYY-MM-DD)"
    ),
    format: str = typer.Option(
        "text",
        "--format", "-f",
        help="Output format (text/json/csv)"
    )
):
    """Display activity statistics."""
    try:
        from .stats import generate_stats
        
        settings = Settings(
            data_dir=data_dir if data_dir else Settings().data_dir
        )
        
        stats = generate_stats(
            settings,
            start_date,
            end_date,
            format
        )
        
        if format == "text":
            console.print(stats)
        else:
            typer.echo(stats)
            
    except Exception as e:
        console.print(f"[red]Error: {str(e)}[/red]")
        raise typer.Exit(1)


@app.command()
def check_permissions() -> None:
    """Check required macOS permissions."""
    try:
        has_permission, msg = verify_permissions()
        
        # Create status table
        status = Table(title="System Permissions Status")
        status.add_column("Permission", style="cyan")
        status.add_column("Status", justify="center")
        status.add_column("Details", style="dim")
        
        # Add accessibility status
        terminal = os.environ.get('TERM_PROGRAM', 'Unknown Terminal')
        status.add_row(
            "Accessibility",
            "✓" if has_permission else "✗",
            f"Terminal: {terminal} ({msg})"
        )
        
        # Add database access status
        data_dir = Path.home() / ".selfspy"
        has_data_access = os.access(data_dir, os.W_OK)
        status.add_row(
            "Data Directory",
            "✓" if has_data_access else "✗",
            str(data_dir)
        )
        
        # Overall status message
        if has_permission and has_data_access:
            console.print("[green]✓ All required permissions granted![/green]\n")
        else:
            console.print("[red]✗ Some permissions are missing![/red]\n")
        
        # Print detailed status
        console.print(status)
        
        if not has_permission:
            console.print("\n[yellow]To fix accessibility permissions:[/yellow]")
            console.print(f"1. Open System Settings > Privacy & Security > Privacy > Accessibility")
            console.print(f"2. Add and enable {terminal}")
            console.print("3. Run [cyan]selfspy check-permissions[/cyan] to verify")
            return 1
            
        return 0
            
    except Exception as e:
        console.print(f"[red]Error: {str(e)}[/red]")
        return 1

def check_screen_recording_permission() -> bool:
    """Check screen recording permission status"""
    try:
        import AVFoundation
        
        session = AVFoundation.AVCaptureSession.alloc().init()
        screen_input = AVFoundation.AVCaptureScreenInput.alloc().init()
        
        if session.canAddInput_(screen_input):
            session.addInput_(screen_input)
            return True
        return False
        
    except Exception:
        return False



def main():
    """Main entry point."""
    app()

if __name__ == "__main__":
    main()