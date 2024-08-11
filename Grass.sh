#!/bin/bash

# 更新包列表
update_system() {
    echo "更新包列表..."
    sudo apt update
}

# 安装 git 和 Python3 及 pip
install_dependencies() {
    echo "安装 git..."
    sudo apt install -y git
    
    echo "安装 Python3 和 pip..."
    sudo apt install -y python3 python3-pip
    
# 检查 tmux 是否安装，如果没有则安装
    if ! command -v tmux &> /dev/null; then
        echo "tmux 未安装，正在安装..."
        sudo apt install -y tmux
    else
        echo "tmux 已安装。"
    fi
}

# 打开 proxy.txt 文件供用户编辑
edit_proxy_file() {
    echo "打开 proxy.txt 文件供编辑，编辑完成后请保存并退出 nano..."
    nano proxy.txt
    
    echo "请按任意键继续执行下一步..."
    read -n 1 -s
}

# 克隆仓库并安装依赖
clone_and_run() {
    echo "克隆仓库并安装依赖..."
    git clone https://github.com/sdohuajia/Grass.git && cd Grass && pip install -r requirements.txt

    echo "运行 main.py..."
    python3 main.py
}

# 主菜单函数
main_menu() {
    while true; do
        clear
        echo "脚本由大赌社区哈哈哈哈编写，推特 @ferdie_jhovie，免费开源，请勿相信收费"
        echo "================================================================"
        echo "节点社区 Telegram 群组: https://t.me/niuwuriji"
        echo "节点社区 Telegram 频道: https://t.me/niuwuriji"
        echo "节点社区 Discord 社群: https://discord.gg/GbMV5EcNWF"
        echo "退出脚本，请按键盘 ctrl + C 退出即可"
        echo "请选择要执行的操作:"
        echo "1) 安装并执行节点"
        echo "0) 退出"
        read -p "输入选项 (0-1): " choice

        case $choice in
            1)
                update_system
                install_dependencies
                edit_proxy_file
                clone_and_run
                ;;
            0)
                echo "退出脚本..."
                exit 0
                ;;
            *)
                echo "无效选项，请重新选择。"
                ;;
        esac
    done
}

# 运行主菜单
main_menu
