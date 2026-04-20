#!/bin/bash

COMPOSE_FILE="./docker-compose-5gc.yaml"
# 核心网网元容器名称
NETWORK_FUNCTIONS=("oiwireless-amf" "oiwireless-smf" "oiwireless-upf")
MAX_RETRIES=5
WAIT_SECONDS=3

# 检查容器是否正常（运行中且不包含 AddressSanitizer 错误）
check_nf_healthy() {
    local container=$1
    local status

    # 检查容器是否在运行
    status=$(docker inspect --format='{{.State.Status}}' "$container" 2>/dev/null)
    if [ "$status" != "running" ]; then
        echo "not_running"
        return
    fi

    # 检查最近日志是否有 AddressSanitizer 错误
    local asan_count
    asan_count=$(docker logs --tail 50 "$container" 2>&1 | grep -c "AddressSanitizer" || true)
    if [ "$asan_count" -gt 0 ]; then
        echo "address_sanitizer"
        return
    fi

    echo "healthy"
}

# 获取不正常的网元列表
get_unhealthy_nfs() {
    local unhealthy=()
    for nf in "${NETWORK_FUNCTIONS[@]}"; do
        local result
        result=$(check_nf_healthy "$nf")
        if [ "$result" != "healthy" ]; then
            unhealthy+=("$nf")
        fi
    done
    echo "${unhealthy[@]}"
}

echo "正在启动核心网..."
docker compose -f "$COMPOSE_FILE" up -d

# 等待容器初始化
sleep "$WAIT_SECONDS"

for ((retry = 1; retry <= MAX_RETRIES; retry++)); do
    unhealthy_nfs=($(get_unhealthy_nfs))

    if [ ${#unhealthy_nfs[@]} -eq 0 ]; then
        echo "核心网启动成功！所有网元运行正常。"
        exit 0
    fi

    echo "核心网正在启动中（第 ${retry}/${MAX_RETRIES} 次检查）"
    for nf in "${unhealthy_nfs[@]}"; do
        local result
        result=$(check_nf_healthy "$nf")
        echo "  - ${nf}: ${result}，正在重启..."
        docker restart "$nf" >/dev/null 2>&1
    done

    # 等待重启后的网元初始化
    sleep "$WAIT_SECONDS"
done

# 超过最大重试次数，最终检查
unhealthy_nfs=($(get_unhealthy_nfs))
if [ ${#unhealthy_nfs[@]} -gt 0 ]; then
    echo "启动核心网失败，请重启电脑或者联系管理员"
    echo "异常网元: ${unhealthy_nfs[*]}"
    exit 1
fi

echo "核心网启动成功！所有网元运行正常。"
exit 0
