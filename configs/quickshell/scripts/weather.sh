#!/bin/bash

# --- CONFIGURAÇÕES ---
API_KEY="a42b9b95aabc8b09afa78babf65335d4"
STATE_FILE="/tmp/waybar_weather_city"
MODE_FILE="/tmp/waybar_weather_mode"   # guarda "auto" ou "manual"

# --- FUNÇÃO: localizar (agora fixo no padrão solicitado) ---
locate_by_ip() {
    # Ignorando API de IP por pedido do usuário, padrão agora é fixo
    echo "Porto Alegre,BR" > "$STATE_FILE"
    echo "auto" > "$MODE_FILE"
}

# --- COMANDO: set "Cidade,CC" -> fixa a localização manualmente ---
if [ "$1" == "set" ]; then
    NEW_CITY="$2"
    if [ -z "$NEW_CITY" ]; then
        echo "Uso: weather.sh set \"Cidade,CC\"" >&2
        exit 1
    fi
    echo "$NEW_CITY" > "$STATE_FILE"
    echo "manual" > "$MODE_FILE"
    exit 0
fi

# --- COMANDO: auto -> força nova detecção por IP, mesmo se estava em modo manual ---
if [ "$1" == "auto" ]; then
    locate_by_ip
    exit 0
fi

# --- COMANDO: toggle -> respeita o modo manual ---
if [ "$1" == "toggle" ]; then
    CURRENT_MODE=$(cat "$MODE_FILE" 2>/dev/null)
    if [ "$CURRENT_MODE" != "manual" ]; then
        locate_by_ip
    fi
    exit 0
fi

# --- Primeira execução (sem STATE_FILE) -> localizar por IP ---
if [ ! -f "$STATE_FILE" ]; then
    locate_by_ip
fi

# Lê a cidade atual
CURRENT_CITY=$(cat "$STATE_FILE")
DISPLAY_NAME=$(echo "$CURRENT_CITY" | cut -d',' -f1)

# --- BUSCA NA API (OpenWeatherMap) ---
WEATHER_JSON=$(curl -s --get "https://api.openweathermap.org/data/2.5/weather" \
    --data-urlencode "q=${CURRENT_CITY}" \
    --data-urlencode "appid=${API_KEY}" \
    --data-urlencode "units=metric" \
    --data-urlencode "lang=pt_br")

# --- TRATAMENTO DE ERROS ---
API_STATUS=$(echo "$WEATHER_JSON" | jq -r '.cod')
if [ "$API_STATUS" != "200" ] || [ -z "$WEATHER_JSON" ]; then
    API_MSG=$(echo "$WEATHER_JSON" | jq -r '.message // "sem detalhes"')
    echo "{\"icon\":\"dialog-warning-symbolic\", \"temp\":\"Erro\", \"text\":\"Erro\", \"tooltip\":\"Falha ao consultar OpenWeatherMap para '$CURRENT_CITY': $API_MSG\"}"
    exit 0
fi

# --- EXTRAÇÃO DE DADOS ---
TEMP=$(echo "$WEATHER_JSON" | jq -r '.main.temp' | awk '{print int($1+0.5)}')
FEELS_LIKE=$(echo "$WEATHER_JSON" | jq -r '.main.feels_like' | awk '{print int($1+0.5)}')
TEMP_MAX=$(echo "$WEATHER_JSON" | jq -r '.main.temp_max' | awk '{print int($1+0.5)}')
TEMP_MIN=$(echo "$WEATHER_JSON" | jq -r '.main.temp_min' | awk '{print int($1+0.5)}')
HUMIDITY=$(echo "$WEATHER_JSON" | jq -r '.main.humidity')
WIND_SPEED=$(echo "$WEATHER_JSON" | jq -r '.wind.speed' | awk '{print int($1 * 3.6)}')
DESC=$(echo "$WEATHER_JSON" | jq -r '.weather[0].description')

DESC="$(tr '[:lower:]' '[:upper:]' <<< ${DESC:0:1})${DESC:1}"

# CORRIGIDO (clima desalinhado na barra): trocamos os emojis (que vinham
# de uma fonte de fallback com métricas de altura diferentes da fonte da
# UI) pelos MESMOS glifos de Nerd Font usados no resto do shell
# (ver config/Icons.qml — weatherCloud/weatherSun/weatherRain).
# PEDIDO: usar ícones parecidos com os do AGS/tema do sistema em vez de
# glifos de fonte — aqui mandamos o NOME do ícone (padrão freedesktop
# weather-*-symbolic), que o QML resolve via Quickshell.iconPath(), em vez
# de um caractere.
ICON_NAME="weather-few-clouds-symbolic"
if [[ "$DESC" == *"Limpo"* || "$DESC" == *"Céu limpo"* ]]; then ICON_NAME="weather-clear-symbolic"; fi
if [[ "$DESC" == *"Chuva"* || "$DESC" == *"Garoa"* ]]; then ICON_NAME="weather-showers-symbolic"; fi
if [[ "$DESC" == *"Nublado"* ]]; then ICON_NAME="weather-few-clouds-symbolic"; fi

MODE_LABEL=""
if [ "$(cat "$MODE_FILE" 2>/dev/null)" == "manual" ]; then
    MODE_LABEL=" (fixado manualmente)"
fi

TEXT="${TEMP}°C"
TOOLTIP="📍 $DISPLAY_NAME$MODE_LABEL
Céu: $DESC
Sensação: $FEELS_LIKE°C
Vento: $WIND_SPEED km/h
Umidade: $HUMIDITY%"

# "icon" agora é um NOME de ícone do tema (weather-*-symbolic), não mais
# um glifo — o QML resolve ele via Quickshell.iconPath() em
# widgets/SymbolicIcon.qml, igual ao resto dos ícones do shell.
jq -n -c \
  --arg icon "$ICON_NAME" \
  --arg temp "${TEMP}°C" \
  --arg text "$TEXT" \
  --arg tooltip "$TOOLTIP" \
  --arg desc "$DESC" \
  --arg feelsLike "$FEELS_LIKE" \
  --arg humidity "$HUMIDITY" \
  --arg wind "$WIND_SPEED" \
  --arg city "$DISPLAY_NAME" \
  --arg tmin "$TEMP_MIN" \
  --arg tmax "$TEMP_MAX" \
  '{icon: $icon, temp: $temp, text: $text, tooltip: $tooltip, desc: $desc, feelsLike: $feelsLike, humidity: $humidity, wind: $wind, city: $city, tempMin: $tmin, tempMax: $tmax}'
