#!/bin/bash
export LC_ALL=C

# 1. Ler o Uso da CPU (%)
cpu_idle=$(top -bn1 | grep "Cpu(s)" | sed "s/.*, *\([0-9.]*\)%* id.*/\1/")
cpu_usage=$(echo "100 - $cpu_idle" | bc | awk '{printf "%.0f", $0}')

# 2. Ler a Temperatura da CPU (°C)
cpu_temp=$(sensors | grep 'Tctl' | grep -Eo '\+[0-9.]+' | tr -d '+')
cpu_temp_int=$(echo $cpu_temp | awk '{print int($1)}')

# 3. Ler Uso e Temperatura da GPU NVIDIA (ignorando erros no terminal)
gpu_usage=$(nvidia-smi --query-gpu=utilization.gpu --format=csv,noheader,nounits 2>/dev/null)
gpu_temp=$(nvidia-smi --query-gpu=temperature.gpu --format=csv,noheader,nounits 2>/dev/null)

# 4. Ler o Uso de RAM (%)
ram_usage=$(free | awk '/Mem:/ {printf("%.0f"), $3/$2 * 100}')

# 5. Ler o Uso do Disco Root (%)
disk_usage=$(df -h / | awk 'NR==2 {print $5}' | tr -d '%')

# 6. Validação de Erros e Lógica do Emoji
if [[ ! "$cpu_usage" =~ ^[0-9]+$ ]] || [[ ! "$cpu_temp_int" =~ ^[0-9]+$ ]] || [[ ! "$gpu_usage" =~ ^[0-9]+$ ]] || [[ ! "$gpu_temp" =~ ^[0-9]+$ ]]; then
    emoji="💀"
    tooltip="Erro de leitura!\nVerifique se o nvidia-smi ou os sensores estão respondendo."
else
    emoji="😁"

    if [ "$cpu_temp_int" -ge 80 ] || [ "$cpu_usage" -ge 85 ] || [ "$gpu_temp" -ge 80 ] || [ "$gpu_usage" -ge 85 ]; then
        emoji="🥵"
    elif [ "$cpu_temp_int" -ge 65 ] || [ "$cpu_usage" -ge 60 ] || [ "$gpu_temp" -ge 65 ] || [ "$gpu_usage" -ge 60 ]; then
        emoji="😅"
    fi

    tooltip=" CPU: ${cpu_usage}%\n Temp: ${cpu_temp}°C\n󰢮 GPU: ${gpu_usage}%\n G.Temp: ${gpu_temp}°C\n RAM: ${ram_usage}%\n Disco: ${disk_usage}%"
fi

echo "{\"text\": \"$emoji\", \"tooltip\": \"$tooltip\"}"
