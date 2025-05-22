#!/bin/bash
sed -i "s/ $//" src/app.py
sed -i -e "\$a\" src/app.py
sed -i -e "\$a\" src/config.py
flake8 src/
