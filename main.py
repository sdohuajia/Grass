import os
import subprocess
import asyncio
import json
import ssl
import time
import uuid
from loguru import logger
from websockets_proxy import Proxy, proxy_connect
import websockets
import argparse

WEBSOCKET_URLS = [
    "wss://proxy.wynd.network:4650",
    "wss://proxy.wynd.network:4444"
]

PING_INTERVAL = 3  # PING 间隔时间（秒）


def check_tmux():
    # 检查是否安装了 tmux
    result = subprocess.run(['which', 'tmux'], stdout=subprocess.PIPE)
    if result.returncode != 0:
        print("tmux 未安装。正在安装 tmux...")
        subprocess.run(['sudo', 'apt-get', 'install', '-y', 'tmux'])


def manage_tmux_session(session_name):
    # 杀死已有的 tmux 会话（如果存在）
    subprocess.run(['tmux', 'kill-session', '-t', session_name], stderr=subprocess.DEVNULL, stdout=subprocess.DEVNULL)
    
    # 创建一个新的 tmux 会话
    subprocess.run(['tmux', 'new-session', '-d', '-s', session_name])


def get_user_input():
    uid = input("请输入你的 Grass UID: ").strip()
    proxy_file = input("请输入你的 proxy.txt 文件路径: ").strip()
    return uid, proxy_file


def load_proxies(proxy_file):
    proxies = []
    with open(proxy_file, 'r') as file:
        for line in file:
            ip, port, username, password = line.strip().split(':')
            proxies.append(f'socks5://{username}:{password}@{ip}:{port}')
    return proxies


async def connect_to_wss(socks5_proxy, user_id):
    ssl_context = ssl.create_default_context()
    ssl_context.check_hostname = False
    ssl_context.verify_mode = ssl.CERT_NONE

    async def send_ping(websocket):
        while True:
            try:
                await websocket.send(json.dumps({
                    "id": str(uuid.uuid4()),
                    "version": "1.0.0",
                    "action": "PING",
                    "data": {}
                }))
                await asyncio.sleep(PING_INTERVAL)
            except websockets.exceptions.ConnectionClosed:
                logger.warning("WebSocket 连接在 ping 期间关闭，尝试重新连接。")
                break
            except asyncio.CancelledError:
                logger.warning("Ping 任务被取消。")
                break

    for uri in WEBSOCKET_URLS:
        while True:
            try:
                proxy = Proxy.from_url(socks5_proxy)
                async with proxy_connect(uri, proxy=proxy, ssl=ssl_context, extra_headers={
                    "Origin": "chrome-extension://lkbnfiajjmbhnfledhphioinpickokdi",
                    "User-Agent": "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/125.0.0.0 Safari/537.36"
                }) as websocket:
                    logger.info(f"连接到 WebSocket URI: {uri}")

                    ping_task = asyncio.create_task(send_ping(websocket))

                    async for message in websocket:
                        message = json.loads(message)
                        logger.info(f"收到消息: {message}")

                        if message.get("action") == "AUTH":
                            auth_response = json.dumps({
                                "id": message["id"],
                                "origin_action": "AUTH",
                                "result": {
                                    "browser_id": str(uuid.uuid4()),
                                    "user_id": user_id,
                                    "user_agent": "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/125.0.0.0 Safari/537.36",
                                    "timestamp": int(time.time()),
                                    "device_type": "extension",
                                    "version": "4.20.2",
                                    "extension_id": "lkbnfiajjmbhnfledhphioinpickokdi"
                                }
                            })
                            logger.debug(f"发送 AUTH 响应: {auth_response}")
                            await websocket.send(auth_response)

                        elif message.get("action") == "PONG":
                            pong_response = json.dumps({
                                "id": message["id"],
                                "origin_action": "PONG"
                            })
                            logger.debug(f"发送 PONG 响应: {pong_response}")
                            await websocket.send(pong_response)
            except websockets.exceptions.ConnectionClosedOK:
                logger.info("WebSocket 连接正常关闭，尝试重新连接。")
            except Exception as e:
                logger.error(f"连接 WebSocket URI 时出错: {uri} - {e}")
                logger.error(f"使用的代理: {socks5_proxy}")
            await asyncio.sleep(5)  # 等待后再重试

async def main(user_id, socks5_proxy_list):
    tasks = [connect_to_wss(proxy, user_id) for proxy in socks5_proxy_list]
    await asyncio.gather(*tasks)

if __name__ == '__main__':
    if 'TMUX' in os.environ:
        parser = argparse.ArgumentParser()
        parser.add_argument('--user-id', type=str, required=True)
        parser.add_argument('--proxy-file', type=str, required=True)
        args = parser.parse_args()

        asyncio.run(main(args.user_id, load_proxies(args.proxy_file)))
    else:
        check_tmux()
        manage_tmux_session('GrassV2')
        user_id, proxy_file = get_user_input()
        
        command = f'python3 {__file__} --user-id {user_id} --proxy-file {proxy_file}'
        subprocess.run(['tmux', 'send-keys', '-t', 'GrassV2', f'{command} C-m'])
