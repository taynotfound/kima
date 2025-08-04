#!/usr/bin/env python3
import subprocess
import sys
import os
import re

# --- Auto-install PyQt5 if missing ---
try:
    from PyQt5 import QtWidgets, QtCore, QtGui
    from PyQt5.QtCore import QProcess, QTimer, pyqtSignal
    from PyQt5.QtWidgets import QMessageBox, QProgressBar, QTabWidget, QTableWidget, QTableWidgetItem, QVBoxLayout, QHBoxLayout, QSplitter
except ImportError:
    print("PyQt5 not found. Attempting to install...")
    
    # First check if pip is available
    try:
        subprocess.check_call([sys.executable, "-m", "pip", "--version"], 
                            stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
        pip_available = True
    except subprocess.CalledProcessError:
        pip_available = False
    
    if pip_available:
        # Try pip installation
        try:
            subprocess.check_call([sys.executable, "-m", "pip", "install", "PyQt5"])
            print("PyQt5 installed successfully via pip!")
        except subprocess.CalledProcessError:
            print("Failed to install PyQt5 via pip.")
            pip_available = False  # Fall back to system packages
    
    if not pip_available:
        print("Pip not available or failed. Trying system package manager...")
        
        # Try system package managers as fallback
        installed = False
        try:
            # Try apt (Debian/Ubuntu)
            if subprocess.run(["which", "apt"], capture_output=True).returncode == 0:
                print("Trying apt package manager...")
                subprocess.check_call(["sudo", "apt", "update"], stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
                subprocess.check_call(["sudo", "apt", "install", "-y", "python3-pyqt5"])
                installed = True
            # Try dnf (Fedora/RHEL)
            elif subprocess.run(["which", "dnf"], capture_output=True).returncode == 0:
                print("Trying dnf package manager...")
                subprocess.check_call(["sudo", "dnf", "install", "-y", "python3-qt5"])
                installed = True
            # Try pacman (Arch)
            elif subprocess.run(["which", "pacman"], capture_output=True).returncode == 0:
                print("Trying pacman package manager...")
                subprocess.check_call(["sudo", "pacman", "-S", "--noconfirm", "python-pyqt5"])
                installed = True
                
            if installed:
                print("PyQt5 installed successfully via system package manager!")
            else:
                raise subprocess.CalledProcessError(1, "No supported package manager found")
                
        except subprocess.CalledProcessError:
            print("\n" + "="*60)
            print("ERROR: Failed to install PyQt5 automatically!")
            print("="*60)
            print("Please install PyQt5 manually using one of these methods:")
            print("\n• On Ubuntu/Debian:")
            print("  sudo apt update && sudo apt install python3-pyqt5")
            print("\n• On Fedora/RHEL:")
            print("  sudo dnf install python3-qt5")
            print("\n• On Arch Linux:")
            print("  sudo pacman -S python-pyqt5")
            print("\n• Using pip (if available):")
            print("  pip3 install PyQt5")
            print("\n• Using conda:")
            print("  conda install pyqt")
            print("\nAfter installation, run the GUI again with:")
            print("  ./kima.sh gui")
            print("="*60)
            sys.exit(1)
    
    # Try importing again after installation
    try:
        from PyQt5 import QtWidgets, QtCore, QtGui
        from PyQt5.QtCore import QProcess, QTimer, pyqtSignal
        from PyQt5.QtWidgets import QMessageBox, QProgressBar, QTabWidget, QTableWidget, QTableWidgetItem, QVBoxLayout, QHBoxLayout, QSplitter
    except ImportError as e:
        print(f"\nWarning: PyQt5 installation completed but import failed: {e}")
        print("This may be due to missing display server (X11/Wayland) in headless environments.")
        print("On desktop systems with a display, this should work fine.")
        print("If you're on a desktop system, try restarting your terminal and running the GUI again.")
        sys.exit(1)

KIMA_SCRIPT = os.path.join(os.path.dirname(__file__), "kima.sh")

class SearchResultsWidget(QtWidgets.QWidget):
    """Widget to display search results in a formatted table"""
    
    def __init__(self):
        super().__init__()
        layout = QVBoxLayout()
        
        self.table = QTableWidget()
        self.table.setColumnCount(3)
        self.table.setHorizontalHeaderLabels(["Package", "Version", "Description"])
        self.table.horizontalHeader().setStretchLastSection(True)
        
        layout.addWidget(QtWidgets.QLabel("Search Results:"))
        layout.addWidget(self.table)
        self.setLayout(layout)
    
    def update_results(self, output):
        """Parse and display search results"""
        self.table.setRowCount(0)
        
        # Parse the output to extract package information
        lines = output.split('\n')
        packages = []
        
        for line in lines:
            line = line.strip()
            if not line or line.startswith('─') or 'Search Results' in line:
                continue
                
            # Try to parse package info from various formats
            # Remove ANSI color codes
            clean_line = re.sub(r'\x1b\[[0-9;]*m', '', line)
            
            if clean_line and not clean_line.startswith('Package') and not clean_line.startswith('Name'):
                parts = clean_line.split()
                if len(parts) >= 2:
                    name = parts[0]
                    version = parts[1] if len(parts) > 1 else "N/A"
                    description = " ".join(parts[2:]) if len(parts) > 2 else "No description available"
                    packages.append((name, version, description))
        
        # Populate table
        self.table.setRowCount(len(packages))
        for row, (name, version, desc) in enumerate(packages):
            self.table.setItem(row, 0, QTableWidgetItem(name))
            self.table.setItem(row, 1, QTableWidgetItem(version))
            self.table.setItem(row, 2, QTableWidgetItem(desc))

class PackageInfoWidget(QtWidgets.QWidget):
    """Widget to display package information in a formatted way"""
    
    def __init__(self):
        super().__init__()
        layout = QVBoxLayout()
        
        self.info_text = QtWidgets.QTextEdit()
        self.info_text.setReadOnly(True)
        
        layout.addWidget(QtWidgets.QLabel("Package Information:"))
        layout.addWidget(self.info_text)
        self.setLayout(layout)
    
    def update_info(self, output):
        """Display formatted package information"""
        # Remove ANSI color codes and format the output
        clean_output = re.sub(r'\x1b\[[0-9;]*m', '', output)
        
        # Add some basic HTML formatting
        formatted_output = clean_output.replace('\n', '<br>')
        formatted_output = re.sub(r'(Name|Version|Description|Size|Repository):', r'<b>\1:</b>', formatted_output)
        
        self.info_text.setHtml(f"<pre>{formatted_output}</pre>")

class KimaGUI(QtWidgets.QMainWindow):
    def __init__(self):
        super().__init__()
        self.setWindowTitle("Kima Package Manager")
        self.setMinimumSize(800, 600)
        self.resize(1000, 700)
        
        # Current process
        self.current_process = None
        
        self.setup_ui()
        self.setup_status_bar()
        
    def setup_ui(self):
        central_widget = QtWidgets.QWidget()
        self.setCentralWidget(central_widget)
        
        # Main layout
        main_layout = QVBoxLayout()
        
        # Control panel
        control_panel = self.create_control_panel()
        main_layout.addWidget(control_panel)
        
        # Splitter for main content and debug console
        splitter = QSplitter(QtCore.Qt.Vertical)
        
        # Tabbed interface for results
        self.tab_widget = QTabWidget()
        
        # Search results tab
        self.search_widget = SearchResultsWidget()
        self.tab_widget.addTab(self.search_widget, "🔍 Search Results")
        
        # Package info tab
        self.info_widget = PackageInfoWidget()
        self.tab_widget.addTab(self.info_widget, "ℹ️ Package Info")
        
        # General output tab
        self.output_area = QtWidgets.QTextEdit()
        self.output_area.setReadOnly(True)
        self.tab_widget.addTab(self.output_area, "📋 General Output")
        
        splitter.addWidget(self.tab_widget)
        
        # Debug console (collapsible)
        debug_widget = QtWidgets.QWidget()
        debug_layout = QVBoxLayout()
        debug_layout.addWidget(QtWidgets.QLabel("🐛 Debug Console (Live Output):"))
        
        self.debug_console = QtWidgets.QTextEdit()
        self.debug_console.setReadOnly(True)
        self.debug_console.setMaximumHeight(150)
        self.debug_console.setStyleSheet("font-family: monospace; background-color: #2e2e2e; color: #ffffff;")
        debug_layout.addWidget(self.debug_console)
        debug_widget.setLayout(debug_layout)
        
        splitter.addWidget(debug_widget)
        splitter.setSizes([400, 150])  # Give more space to main content
        
        main_layout.addWidget(splitter)
        central_widget.setLayout(main_layout)
        
    def create_control_panel(self):
        """Create the control panel with command selection and input"""
        group_box = QtWidgets.QGroupBox("Command Control")
        layout = QVBoxLayout()
        
        # Command selection
        cmd_layout = QHBoxLayout()
        cmd_layout.addWidget(QtWidgets.QLabel("Command:"))
        
        self.cmd_box = QtWidgets.QComboBox()
        self.cmd_box.addItems([
            "search", "install", "uninstall", "info", "list", "upgrade", 
            "update", "cleanup", "stats", "orphaned", "outdated", "help"
        ])
        cmd_layout.addWidget(self.cmd_box)
        
        # Package input
        cmd_layout.addWidget(QtWidgets.QLabel("Package/Term:"))
        self.input_box = QtWidgets.QLineEdit()
        self.input_box.setPlaceholderText("Package name or search term (if applicable)")
        cmd_layout.addWidget(self.input_box)
        
        # Buttons
        self.run_button = QtWidgets.QPushButton("🚀 Run Command")
        self.run_button.clicked.connect(self.run_kima_command)
        cmd_layout.addWidget(self.run_button)
        
        self.stop_button = QtWidgets.QPushButton("⏹️ Stop")
        self.stop_button.setEnabled(False)
        self.stop_button.clicked.connect(self.stop_command)
        cmd_layout.addWidget(self.stop_button)
        
        layout.addLayout(cmd_layout)
        
        # Progress bar
        self.progress_bar = QProgressBar()
        self.progress_bar.setVisible(False)
        layout.addWidget(self.progress_bar)
        
        group_box.setLayout(layout)
        return group_box
        
    def setup_status_bar(self):
        """Setup status bar with information"""
        self.status_bar = self.statusBar()
        self.status_bar.showMessage("Ready")
        
    def run_kima_command(self):
        """Run a kima command with real-time output"""
        command = self.cmd_box.currentText()
        extra = self.input_box.text().strip()
        
        # Build command arguments
        args = [KIMA_SCRIPT, command]
        if extra:
            args.append(extra)
            
        # Clear previous outputs
        self.debug_console.clear()
        self.output_area.clear()
        
        # Setup process
        self.current_process = QProcess()
        self.current_process.readyReadStandardOutput.connect(self.handle_stdout)
        self.current_process.readyReadStandardError.connect(self.handle_stderr)
        self.current_process.finished.connect(self.command_finished)
        
        # Start process
        self.current_process.start(args[0], args[1:])
        
        # Update UI state
        self.run_button.setEnabled(False)
        self.stop_button.setEnabled(True)
        self.progress_bar.setVisible(True)
        self.progress_bar.setRange(0, 0)  # Indeterminate progress
        self.status_bar.showMessage(f"Running: {' '.join(args)}")
        
        # Clear and prepare appropriate tab
        if command == "search":
            self.tab_widget.setCurrentWidget(self.search_widget)
        elif command == "info":
            self.tab_widget.setCurrentWidget(self.info_widget)
        else:
            self.tab_widget.setCurrentWidget(self.output_area)
            
    def handle_stdout(self):
        """Handle stdout from the process"""
        if self.current_process:
            data = self.current_process.readAllStandardOutput()
            text = bytes(data).decode('utf-8')
            self.debug_console.append(text.strip())
            
            # Scroll to bottom
            cursor = self.debug_console.textCursor()
            cursor.movePosition(QtGui.QTextCursor.End)
            self.debug_console.setTextCursor(cursor)
            
    def handle_stderr(self):
        """Handle stderr from the process"""
        if self.current_process:
            data = self.current_process.readAllStandardError()
            text = bytes(data).decode('utf-8')
            self.debug_console.append(f"ERROR: {text.strip()}")
            
    def command_finished(self, exit_code):
        """Handle command completion"""
        command = self.cmd_box.currentText()
        
        # Get full output
        if self.current_process:
            stdout_data = self.current_process.readAllStandardOutput()
            stderr_data = self.current_process.readAllStandardError()
            
            stdout_text = bytes(stdout_data).decode('utf-8')
            stderr_text = bytes(stderr_data).decode('utf-8')
            full_output = stdout_text + ("\n" + stderr_text if stderr_text else "")
            
            # Process output based on command type
            if command == "search" and stdout_text:
                self.search_widget.update_results(stdout_text)
            elif command == "info" and stdout_text:
                self.info_widget.update_info(stdout_text)
            else:
                self.output_area.setPlainText(full_output)
        
        # Show completion notification
        if exit_code == 0:
            self.show_success_notification(command)
            self.status_bar.showMessage(f"✅ Command '{command}' completed successfully")
        else:
            self.show_error_notification(command, exit_code)
            self.status_bar.showMessage(f"❌ Command '{command}' failed with exit code {exit_code}")
            
        # Reset UI state
        self.run_button.setEnabled(True)
        self.stop_button.setEnabled(False)
        self.progress_bar.setVisible(False)
        self.current_process = None
        
    def stop_command(self):
        """Stop the currently running command"""
        if self.current_process:
            self.current_process.kill()
            self.current_process = None
            
        self.run_button.setEnabled(True)
        self.stop_button.setEnabled(False)
        self.progress_bar.setVisible(False)
        self.status_bar.showMessage("Command stopped by user")
        
    def show_success_notification(self, command):
        """Show success notification popup"""
        if command in ["install", "uninstall", "update", "cleanup", "upgrade"]:
            msg = QMessageBox()
            msg.setIcon(QMessageBox.Information)
            msg.setWindowTitle("Success")
            
            if command == "install":
                msg.setText("📦 Package installed successfully!")
            elif command == "uninstall":
                msg.setText("🗑️ Package uninstalled successfully!")
            elif command == "update":
                msg.setText("🔄 Package lists updated successfully!")
            elif command == "cleanup":
                msg.setText("🧹 System cleanup completed successfully!")
            elif command == "upgrade":
                msg.setText("⬆️ Package upgraded successfully!")
            else:
                msg.setText(f"✅ Command '{command}' completed successfully!")
                
            msg.exec_()
            
    def show_error_notification(self, command, exit_code):
        """Show error notification popup"""
        msg = QMessageBox()
        msg.setIcon(QMessageBox.Critical)
        msg.setWindowTitle("Error")
        msg.setText(f"❌ Command '{command}' failed with exit code {exit_code}")
        msg.setDetailedText("Check the debug console for more details.")
        msg.exec_()

def main():
    app = QtWidgets.QApplication(sys.argv)
    app.setStyle('Fusion')  # Modern look
    
    # Set application icon and info
    app.setApplicationName("Kima Package Manager")
    app.setApplicationVersion("2.0")
    
    gui = KimaGUI()
    gui.show()
    sys.exit(app.exec_())

if __name__ == "__main__":
    main()