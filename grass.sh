#!/bin/bash

# 检查是否以root用户运行脚本
if [ "$(id -u)" != "0" ]; then
    echo "此脚本需要以root用户权限运行。"
    echo "请尝试使用 'sudo -i' 命令切换到root用户，然后再次运行此脚本。"
    exit 1
fi

# 更新软件包索引
update_packages() {
    echo "更新软件包索引..."
    sudo apt update
}

# 脚本保存路径
SCRIPT_PATH="$HOME/grass.sh"

# 安装依赖项
install_dependencies() {
    echo "安装证书..."
    sudo apt install -y ca-certificates

    echo "安装 curl..."
    sudo apt install -y curl

    echo "安装 gnupg..."
    sudo apt install -y gnupg

    echo "安装 lsb-release..."
    sudo apt install -y lsb-release

    # 检查并安装 pip
    if ! command -v pip &> /dev/null; then
        echo "pip 未安装，正在安装 pip..."
        sudo apt install -y python3-pip
    else
        echo "pip 已安装，跳过安装步骤。"
    fi

    # 添加 Docker 的 GPG 密钥和存储库
    echo "添加 Docker 的 GPG 密钥和存储库..."
    curl -fsSL https://download.docker.com/linux/debian/gpg | sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg
    echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/debian $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

    # 更新软件包索引
    echo "更新软件包索引..."
    sudo apt update

    # 检查并安装 Docker
    if ! command -v docker &> /dev/null; then
        echo "正在安装 Docker..."
        sudo apt-get install -y docker.io
    else
        echo "Docker 已安装，跳过安装步骤。"
    fi
}

# 克隆仓库
clone_repo() {
    echo "克隆仓库..."
    git clone https://github.com/sdohuajia/Grass
}

# 进入仓库目录并编辑 data.txt 文件
edit_data_txt() {
    if [ -d "Grass" ]; then
        echo "进入 'Grass' 目录..."
        cd Grass

        # 提示用户替换为 grass 用户的 ID
        echo "请确保 'data.txt' 文件中的用户 ID 替换为 'grass' 用户的 ID。"
        echo "在编辑完成并保存后，按任意键继续。"

        # 编辑 data.txt 文件
        nano data.txt

        # 检查用户是否退出编辑器
        if [ $? -eq 0 ]; then
            echo "文件编辑完成，继续执行下一步。"
        else
            echo "编辑失败或用户未保存，脚本将退出。"
            exit 1
        fi
    else
        echo "仓库目录 'Grass' 不存在。"
        exit 1
    fi
}

# 构建 Docker 镜像
build_docker_image() {
    echo "构建 Docker 镜像..."
    docker build -t grass-mining .
}

# 运行 Docker 容器
run_docker_container() {
    echo "运行 Docker 容器..."
    docker run -d --name grass-mining-container grass-mining
}

# 检查 Docker 是否正在运行
check_docker_status() {
    echo "检查 Docker 容器状态..."
    docker ps

    read -p "请输入 Docker 容器 ID: " container_id

    if [ -z "$container_id" ]; then
        echo "未输入容器 ID。"
        return
    fi

    echo "查看 Docker 容器日志..."
    docker logs "$container_id"
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
        echo "退出脚本，请按键盘 ctrl+c 退出即可"
        echo "请选择要执行的操作:"
        echo "1) 安装并配置 Grass"
        echo "2) 检查 Docker 容器状态"
        echo "3) 退出"

        read -p "请输入选项 (1-3): " option

        case $option in
            1)
                update_packages
                install_dependencies
                clone_repo
                edit_data_txt
                build_docker_image
                run_docker_container
                ;;
            2)
                check_docker_status
                ;;
            3)
                echo "退出脚本。"
                exit 0
                ;;
            *)
                echo "无效选项，请选择 1 到 3 之间的数字。"
                ;;
        esac

        read -p "按任意键返回主菜单..."
    done
}

# 执行主菜单
main_menu
