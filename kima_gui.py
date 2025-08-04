#!/usr/bin/env python3
import subprocess
import sys
import os

# --- Auto-install PyQt5 if missing ---
try:
    from PyQt5 import QtWidgets, QtCore
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
        from PyQt5 import QtWidgets, QtCore
    except ImportError as e:
        print(f"\nWarning: PyQt5 installation completed but import failed: {e}")
        print("This may be due to missing display server (X11/Wayland) in headless environments.")
        print("On desktop systems with a display, this should work fine.")
        print("If you're on a desktop system, try restarting your terminal and running the GUI again.")
        sys.exit(1)

KIMA_SCRIPT = os.path.join(os.path.dirname(__file__), "kima.sh")

class KimaGUI(QtWidgets.QWidget):
    def __init__(self):
        super().__init__()
        self.setWindowTitle("Kima Package Manager")
        self.resize(600, 400)

        # Widgets
        self.cmd_box = QtWidgets.QComboBox()
        self.cmd_box.addItems([
            "install", "uninstall", "search", "upgrade", "info", "list",
            "update", "cleanup", "help"
        ])
        self.input_box = QtWidgets.QLineEdit()
        self.input_box.setPlaceholderText("Package name or search term (if applicable)")
        self.run_button = QtWidgets.QPushButton("Run")
        self.output_area = QtWidgets.QTextEdit()
        self.output_area.setReadOnly(True)

        # Layout
        layout = QtWidgets.QVBoxLayout()
        form = QtWidgets.QHBoxLayout()
        form.addWidget(self.cmd_box)
        form.addWidget(self.input_box)
        form.addWidget(self.run_button)
        layout.addLayout(form)
        layout.addWidget(self.output_area)
        self.setLayout(layout)

        # Signals
        self.run_button.clicked.connect(self.run_kima_command)

    def run_kima_command(self):
        command = self.cmd_box.currentText()
        extra = self.input_box.text().strip()
        args = [KIMA_SCRIPT, command]
        if extra:
            args.append(extra)
        try:
            result = subprocess.run(args, stdout=subprocess.PIPE, stderr=subprocess.PIPE, text=True)
            output = result.stdout + ("\n" + result.stderr if result.stderr else "")
        except Exception as e:
            output = str(e)
        self.output_area.setPlainText(output)

def main():
    app = QtWidgets.QApplication(sys.argv)
    gui = KimaGUI()
    gui.show()
    sys.exit(app.exec_())

if __name__ == "__main__":
    main()