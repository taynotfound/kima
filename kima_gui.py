#!/usr/bin/env python3
import subprocess
import sys
import os

# --- Auto-install PyQt5 if missing ---
try:
    from PyQt5 import QtWidgets, QtCore
except ImportError:
    print("PyQt5 not found. Installing...")
    subprocess.check_call([sys.executable, "-m", "pip", "install", "PyQt5"])
    from PyQt5 import QtWidgets, QtCore

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