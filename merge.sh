#!/bin/bash
set -e 

function title {
  echo 
  echo "###############################################################################"
  echo "## 👉$1👈"
  echo "###############################################################################" 
  echo 
}

function error_exit {
  echo -e "\n❌ 错误发生在: $1, 错误信息: $2, 请仔细阅读上方error-log 🔼"
  exit 1
}

# 获取当前分支名称
current_branch=$(git branch --show-current) || error_exit "获取当前分支" "无法获取当前分支名称"
title "当前分支: $current_branch "

# 颜色定义
GREEN_BOLD='\033[1;32m'
YELLOW_BOLD='\033[1;33m'
NC='\033[0m' # 重置颜色

# 缓存文件路径
CACHE_FILE="/tmp/last_target_branch_$(basename $(pwd)).txt"

# 检查是否有缓存的目标分支
if [[ -f "$CACHE_FILE" ]]; then
    last_target_branch=$(cat "$CACHE_FILE")
    echo -ne "是否要合并到上次相同的目标分支: ${GREEN_BOLD}${last_target_branch}${NC} [Y/n] "
    read -r use_last_branch
    
    if [[ "$use_last_branch" =~ ^[Yy]$ ]] || [[ -z "$use_last_branch" ]]; then
        target_branch=$last_target_branch
        echo -e "${GREEN_BOLD}使用上次的目标分支: $target_branch${NC}"
    else
        read -p "请输入新的目标分支名称: " target_branch
        echo -e "${GREEN_BOLD}用户选择: $target_branch${NC}"
    fi
else
    read -p "请输入目标分支名称: " target_branch
    echo -e "${GREEN_BOLD}用户选择: $target_branch${NC}"
fi

# 检查目标分支是否存在
git show-ref --verify --quiet refs/heads/$target_branch || error_exit "检查目标分支" "分支 $target_branch 不存在"

# 切换到目标分支
title "正在切换到目标分支: $target_branch..."
git checkout $target_branch || error_exit "切换分支" "无法切换到分支 $target_branch"

# 拉取最新代码
title "正在拉取目标分支远程最新代码..."
git pull origin $target_branch || error_exit "拉取代码" "拉取分支 $target_branch 最新代码失败"

# 合并当前分支到目标分支
title "合并个人分支: $current_branch "
git merge --no-ff --no-edit $current_branch || error_exit "合并分支" "合并 $current_branch 到 $target_branch 时出现冲突"

# 推送
title "正在推送代码..."
git push || error_exit "推送代码" "推送代码到 $target_branch 失败"

echo -e "${YELLOW_BOLD}✅ 合并完成！已从 $current_branch 合并到 $target_branch, 请使用 git log 查看合并记录${NC}"

# 切换回原分支
git checkout $current_branch || error_exit "切换回原分支" "无法切换回原分支 $current_branch"

echo -e "${YELLOW_BOLD}✅ 已自动切换分支回 $current_branch${NC}"

# 所有操作成功完成，保存缓存
function save_cache {
    echo "$target_branch" > "$CACHE_FILE"
}
save_cache
