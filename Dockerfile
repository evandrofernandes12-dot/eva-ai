# Servidor online oficial do Chavinho's Kart (roda o projeto Godot em modo headless).
# Usado pelo Render (plano gratuito). A porta vem da variável PORT do Render.
FROM debian:bookworm-slim

RUN apt-get update && apt-get install -y --no-install-recommends \
    wget unzip ca-certificates libfontconfig1 libxcursor1 libxinerama1 libxrandr2 \
    libxi6 libxkbcommon0 libasound2 libpulse0 libdbus-1-3 libgl1 \
    && rm -rf /var/lib/apt/lists/*

RUN wget -q https://github.com/godotengine/godot/releases/download/4.3-stable/Godot_v4.3-stable_linux.x86_64.zip -O /tmp/godot.zip \
    && unzip -q /tmp/godot.zip -d /opt \
    && mv /opt/Godot_v4.3-stable_linux.x86_64 /usr/local/bin/godot \
    && chmod +x /usr/local/bin/godot \
    && rm /tmp/godot.zip

WORKDIR /app
COPY chavinhos-kart/ /app/

# Gera o cache de classes do GDScript (a pasta .godot não vai para o repositório).
RUN godot --headless --import --path /app || true

CMD ["godot", "--headless", "--path", "/app", "--", "--server"]
