#!/bin/bash
pkg update -y
pkg install -y python git
pip install python-telegram-bot==20.3 cryptography==39.0.2
git clone https://github.com/Gbrl777609/Eterna-2.1
cd Eterna-2.1/monetization
python bot_cyborg.py
