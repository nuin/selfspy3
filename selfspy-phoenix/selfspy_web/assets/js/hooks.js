/**
 * Phoenix LiveView hooks for Selfspy dashboard
 * 
 * Provides client-side functionality for interactive charts,
 * real-time updates, and enhanced UI components.
 */

// Import Chart.js for activity charts
import {
  Chart,
  CategoryScale,
  LinearScale,
  PointElement,
  LineElement,
  Title,
  Tooltip,
  Legend,
  Filler
} from 'chart.js';

// Register Chart.js components
Chart.register(
  CategoryScale,
  LinearScale,
  PointElement,
  LineElement,
  Title,
  Tooltip,
  Legend,
  Filler
);

// Activity Chart Hook
const ActivityChart = {
  mounted() {
    this.initChart();
    
    // Listen for data updates
    this.handleEvent("update_chart", (data) => {
      this.updateChart(data);
    });
  },
  
  updated() {
    // Update chart when data changes
    const chartData = JSON.parse(this.el.dataset.chart || '[]');
    this.updateChart(chartData);
  },
  
  destroyed() {
    if (this.chart) {
      this.chart.destroy();
    }
  },
  
  initChart() {
    const ctx = document.createElement('canvas');
    ctx.id = 'activity-chart-canvas';
    this.el.innerHTML = '';
    this.el.appendChild(ctx);
    
    const chartData = JSON.parse(this.el.dataset.chart || '[]');
    
    this.chart = new Chart(ctx, {
      type: 'line',
      data: {
        labels: chartData.map(point => {
          const date = new Date(point.timestamp);
          return date.toLocaleTimeString([], { hour: '2-digit', minute: '2-digit' });
        }),
        datasets: [
          {
            label: 'Keystrokes',
            data: chartData.map(point => point.keystrokes),
            borderColor: 'rgb(59, 130, 246)',
            backgroundColor: 'rgba(59, 130, 246, 0.1)',
            fill: true,
            tension: 0.4
          },
          {
            label: 'Mouse Clicks',
            data: chartData.map(point => point.clicks),
            borderColor: 'rgb(34, 197, 94)',
            backgroundColor: 'rgba(34, 197, 94, 0.1)',
            fill: true,
            tension: 0.4
          },
          {
            label: 'Active Time %',
            data: chartData.map(point => point.active_time),
            borderColor: 'rgb(168, 85, 247)',
            backgroundColor: 'rgba(168, 85, 247, 0.1)',
            fill: true,
            tension: 0.4
          }
        ]
      },
      options: {
        responsive: true,
        maintainAspectRatio: false,
        interaction: {
          mode: 'index',
          intersect: false,
        },
        plugins: {
          title: {
            display: false
          },
          legend: {
            position: 'top',
            labels: {
              usePointStyle: true,
              padding: 20
            }
          },
          tooltip: {
            backgroundColor: 'rgba(0, 0, 0, 0.8)',
            titleColor: 'white',
            bodyColor: 'white',
            borderColor: 'rgba(255, 255, 255, 0.1)',
            borderWidth: 1
          }
        },
        scales: {
          x: {
            display: true,
            title: {
              display: true,
              text: 'Time'
            },
            grid: {
              display: false
            }
          },
          y: {
            display: true,
            title: {
              display: true,
              text: 'Activity Count'
            },
            grid: {
              color: 'rgba(0, 0, 0, 0.1)'
            },
            beginAtZero: true
          }
        },
        elements: {
          point: {
            radius: 3,
            hoverRadius: 6
          }
        }
      }
    });
  },
  
  updateChart(data) {
    if (!this.chart || !data || data.length === 0) return;
    
    // Update labels (timestamps)
    this.chart.data.labels = data.map(point => {
      const date = new Date(point.timestamp);
      return date.toLocaleTimeString([], { hour: '2-digit', minute: '2-digit' });
    });
    
    // Update datasets
    this.chart.data.datasets[0].data = data.map(point => point.keystrokes);
    this.chart.data.datasets[1].data = data.map(point => point.clicks);
    this.chart.data.datasets[2].data = data.map(point => point.active_time);
    
    // Animate the update
    this.chart.update('active');
  }
};

// Real-time Status Indicator Hook
const StatusIndicator = {
  mounted() {
    this.updateStatus();
  },
  
  updated() {
    this.updateStatus();
  },
  
  updateStatus() {
    const isActive = this.el.dataset.active === 'true';
    const indicator = this.el.querySelector('.status-dot');
    
    if (indicator) {
      if (isActive) {
        indicator.classList.add('bg-green-500', 'animate-pulse');
        indicator.classList.remove('bg-red-500');
      } else {
        indicator.classList.add('bg-red-500');
        indicator.classList.remove('bg-green-500', 'animate-pulse');
      }
    }
  }
};

// Notification Toast Hook
const NotificationToast = {
  mounted() {
    this.showToast();
  },
  
  showToast() {
    const toast = this.el;
    toast.classList.add('translate-x-0');
    toast.classList.remove('translate-x-full');
    
    // Auto-hide after 5 seconds
    setTimeout(() => {
      this.hideToast();
    }, 5000);
  },
  
  hideToast() {
    const toast = this.el;
    toast.classList.add('translate-x-full');
    toast.classList.remove('translate-x-0');
    
    // Remove from DOM after animation
    setTimeout(() => {
      if (toast.parentNode) {
        toast.parentNode.removeChild(toast);
      }
    }, 300);
  }
};

// Keyboard Shortcuts Hook
const KeyboardShortcuts = {
  mounted() {
    this.handleKeydown = (event) => {
      // Global keyboard shortcuts
      if (event.ctrlKey || event.metaKey) {
        switch (event.key) {
          case 'r':
            event.preventDefault();
            this.pushEvent('refresh_data');
            break;
          case ' ':
            event.preventDefault();
            this.pushEvent('toggle_monitoring');
            break;
        }
      }
      
      // ESC key to close modals or cancel actions
      if (event.key === 'Escape') {
        this.pushEvent('cancel_action');
      }
    };
    
    document.addEventListener('keydown', this.handleKeydown);
  },
  
  destroyed() {
    document.removeEventListener('keydown', this.handleKeydown);
  }
};

// Auto-refresh Hook
const AutoRefresh = {
  mounted() {
    const interval = parseInt(this.el.dataset.interval || '30000'); // Default 30 seconds
    
    this.refreshTimer = setInterval(() => {
      this.pushEvent('auto_refresh');
    }, interval);
  },
  
  destroyed() {
    if (this.refreshTimer) {
      clearInterval(this.refreshTimer);
    }
  }
};

// Copy to Clipboard Hook
const CopyToClipboard = {
  mounted() {
    this.el.addEventListener('click', () => {
      const text = this.el.dataset.text;
      
      if (navigator.clipboard) {
        navigator.clipboard.writeText(text).then(() => {
          this.showCopyFeedback();
        });
      } else {
        // Fallback for older browsers
        const textArea = document.createElement('textarea');
        textArea.value = text;
        document.body.appendChild(textArea);
        textArea.select();
        document.execCommand('copy');
        document.body.removeChild(textArea);
        this.showCopyFeedback();
      }
    });
  },
  
  showCopyFeedback() {
    const originalText = this.el.textContent;
    this.el.textContent = 'Copied!';
    this.el.classList.add('bg-green-500');
    
    setTimeout(() => {
      this.el.textContent = originalText;
      this.el.classList.remove('bg-green-500');
    }, 1000);
  }
};

// Theme Toggle Hook
const ThemeToggle = {
  mounted() {
    this.initTheme();
    
    this.el.addEventListener('click', () => {
      this.toggleTheme();
    });
  },
  
  initTheme() {
    const savedTheme = localStorage.getItem('theme');
    const prefersDark = window.matchMedia('(prefers-color-scheme: dark)').matches;
    
    if (savedTheme === 'dark' || (!savedTheme && prefersDark)) {
      document.documentElement.classList.add('dark');
      this.updateToggleIcon(true);
    } else {
      document.documentElement.classList.remove('dark');
      this.updateToggleIcon(false);
    }
  },
  
  toggleTheme() {
    const isDark = document.documentElement.classList.contains('dark');
    
    if (isDark) {
      document.documentElement.classList.remove('dark');
      localStorage.setItem('theme', 'light');
      this.updateToggleIcon(false);
    } else {
      document.documentElement.classList.add('dark');
      localStorage.setItem('theme', 'dark');
      this.updateToggleIcon(true);
    }
  },
  
  updateToggleIcon(isDark) {
    const icon = this.el.querySelector('.theme-icon');
    if (icon) {
      icon.textContent = isDark ? '☀️' : '🌙';
    }
  }
};

// Export hooks for Phoenix LiveView
export default {
  ActivityChart,
  StatusIndicator,
  NotificationToast,
  KeyboardShortcuts,
  AutoRefresh,
  CopyToClipboard,
  ThemeToggle
};