import torch
import torch.nn as nn
import numpy as np
from scipy.fft import fft, fftfreq
from torch.fft import rfft, irfft

class FourierSignalQuantifier(nn.Module):
    """Módulo 1: Cuantificación de señales periódicas usando FFT"""
    def __init__(self, threshold=0.9):
        super().__init__()
        self.threshold = threshold  # Umbral energía espectral
    
    def forward(self, x):
        # x: (batch_size, seq_len)
        fft_coeffs = rfft(x, dim=1)
        magnitudes = torch.abs(fft_coeffs)
        
        # Identificar frecuencias dominantes
        energy = torch.cumsum(magnitudes**2, dim=1) / torch.sum(magnitudes**2, dim=1, keepdim=True)
        mask = (energy < self.threshold).float()
        compressed_coeffs = fft_coeffs * mask
        
        return compressed_coeffs, magnitudes

class FourierPositionalEncoding(nn.Module):
    """Módulo 2: Codificación posicional con base en frecuencias"""
    def __init__(self, d_model, max_len=5000):
        super().__init__()
        pe = torch.zeros(max_len, d_model)
        position = torch.arange(0, max_len, dtype=torch.float).unsqueeze(1)
        div_term = torch.exp(torch.arange(0, d_model, 2).float() * (-np.log(10000.0) / d_model))
        pe[:, 0::2] = torch.sin(position * div_term)  # Componentes seno
        pe[:, 1::2] = torch.cos(position * div_term)  # Componentes coseno
        self.register_buffer('pe', pe)

    def forward(self, x):
        x = x + self.pe[:x.size(1), :]
        return x

class FrequencyBasedCompression(nn.Module):
    """Módulo 3: Compresión de embeddings mediante coeficientes clave"""
    def __init__(self, keep_ratio=0.5):
        super().__init__()
        self.keep_ratio = keep_ratio
    
    def forward(self, embeddings):
        # embeddings: (batch, seq_len, d_model)
        coeffs = rfft(embeddings, dim=2)
        magnitudes = torch.mean(torch.abs(coeffs), dim=0)
        
        # Seleccionar top k frecuencias
        k = int(self.keep_ratio * coeffs.shape[2])
        _, indices = torch.topk(magnitudes, k, dim=1)
        compressed = torch.gather(coeffs, 2, indices.unsqueeze(0).expand(coeffs.shape[0], -1, -1))
        
        return compressed, indices

class FourierGANGenerator(nn.Module):
    """Módulo 4: Generador GAN con inyección de componentes frecuenciales"""
    def __init__(self, latent_dim=100, fourier_dim=10):
        super().__init__()
        self.fourier_proj = nn.Linear(fourier_dim, 256)
        self.main = nn.Sequential(
            nn.Linear(latent_dim + 256, 1024),
            nn.BatchNorm1d(1024),
            nn.ReLU(),
            nn.Linear(1024, 784),
            nn.Tanh()
        )
    
    def forward(self, z, fourier_coeffs):
        freq_features = self.fourier_proj(fourier_coeffs)
        combined = torch.cat([z, freq_features], dim=1)
        return self.main(combined)

class FourierAttentionAugmentation(nn.Module):
    """Módulo 5: Aumentación de atención con filtrado frecuencial"""
    def __init__(self, d_model, n_heads):
        super().__init__()
        self.head_dim = d_model // n_heads
        self.n_heads = n_heads
        
    def frequency_filter(self, attn_scores):
        # FFT en scores de atención
        freq_domain = rfft(attn_scores, dim=-1)
        magnitudes = torch.abs(freq_domain)
        
        # Filtro pasa-bajos
        mean_mag = torch.mean(magnitudes, dim=-1, keepdim=True)
        filtered = torch.where(magnitudes > mean_mag, freq_domain, 0.0)
        
        return irfft(filtered, dim=-1)
    
    def forward(self, query, key, value):
        # Cálculo estándar de atención
        scores = torch.matmul(query, key.transpose(-2, -1)) / np.sqrt(self.head_dim)
        
        # Aplicación de filtro frecuencial
        filtered_scores = self.frequency_filter(scores)
        
        attn = torch.softmax(filtered_scores, dim=-1)
        return torch.matmul(attn, value)

# --- Modelo Principal (Original) con Módulos Integrados ---
class CoreAIModel(nn.Module):
    def __init__(self, vocab_size, d_model=512, n_heads=8):
        super().__init__()
        
        # Módulos existentes (no modificados)
        self.embedding = nn.Embedding(vocab_size, d_model)
        self.transformer = nn.TransformerEncoder(
            nn.TransformerEncoderLayer(d_model, n_heads),
            num_layers=6
        )
        
        # Nuevos módulos Fourier
        self.fourier_quant = FourierSignalQuantifier()
        self.fourier_pos = FourierPositionalEncoding(d_model)
        self.freq_compress = FrequencyBasedCompression()
        self.attn_aug = FourierAttentionAugmentation(d_model, n_heads)
        self.gan_generator = FourierGANGenerator()
    
    def forward(self, x, z=None, fourier_coeffs=None):
        # Etapas originales
        x = self.embedding(x)
        x = self.fourier_pos(x)  # Inyección posición-Fourier
        
        # Compresión frecuencial
        compressed, _ = self.freq_compress(x)
        
        # Procesamiento con atención aumentada
        x = self.transformer(compressed)
        
        # Generación opcional con GAN
        if z is not None and fourier_coeffs is not None:
            gen_images = self.gan_generator(z, fourier_coeffs)
            return x, gen_images
        
        return x

# --- Funciones de Utilidad ---
def fourier_analysis(signal, threshold=0.9):
    """Analiza y extrae patrones periódicos"""
    coeffs = fft(signal.numpy())
    freqs = fftfreq(len(signal))
    magnitudes = np.abs(coeffs)
    
    # Identificar frecuencias dominantes
    sorted_indices = np.argsort(magnitudes)[::-1]
    cumulative_energy = np.cumsum(magnitudes[sorted_indices]**2)
    cumulative_energy /= cumulative_energy[-1]
    dominant = sorted_indices[cumulative_energy <= threshold]
    
    return freqs[dominant], magnitudes[dominant]

def reconstruct_signal(coeffs, original_length):
    """Reconstrucción desde coeficientes Fourier"""
    return irfft(coeffs, n=original_length)

# --- Configuración de Entrenamiento ---
def configure_training(model, use_fourier=True):
    optimizer = torch.optim.Adam(model.parameters(), lr=1e-4)
    scheduler = torch.optim.lr_scheduler.ReduceLROnPlateau(optimizer, 'min')
    
    if use_fourier:
        # Congelar parámetros originales si se requiere
        for param in model.transformer.parameters():
            param.requires_grad = False
            
    return optimizer, scheduler
