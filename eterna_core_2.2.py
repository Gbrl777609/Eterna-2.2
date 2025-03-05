from qiskit import QuantumCircuit, Aer, execute
import subprocess
import sys
from datetime import datetime

class EternaCore:
    def __init__(self):
        self.qc = QuantumCircuit(2)
        self.qc.h(0)
        self.qc.cx(0, 1)
        
    def notificar(self, mensaje):
        subprocess.run([
            "termux-notification",
            "--title", f"Eterna-Core {datetime.now().strftime('%H:%M')}",
            "--content", mensaje,
            "--vibrate", "200,100,200",
            "--button1", "Status",
            "--button1-action", "python eterna_core_2.2.py --status"
        ])
        
    def iniciar(self):
        self.notificar("Núcleo cuántico activado")
        backend = Aer.get_backend('qasm_simulator')
        job = execute(self.qc, backend, shots=777)
        result = job.result()
        print("Entrelazamiento confirmado:", result.get_counts())

if __name__ == "__main__":
    print("🌀 Iniciando Eterna-Core v2.2...")
    eterna = EternaCore()
    eterna.iniciar()
