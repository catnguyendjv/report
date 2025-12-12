#!/bin/bash

# work/ ディレクトリ内のリポジトリの状態を表示するスクリプト

echo "=== Work Directory Repository Status ==="
echo ""

# work ディレクトリに移動
WORK_DIR="./work"
if [ ! -d "$WORK_DIR" ]; then
    echo "Error: $WORK_DIR directory not found"
    exit 1
fi

# work ディレクトリ内のサブディレクトリを取得
for dir in "$WORK_DIR"/*/; do
    if [ -d "$dir" ]; then
        dir_name=$(basename "$dir")
        echo "--- $dir_name ---"
        
        # .git ディレクトリが存在するかチェック
        if [ -d "$dir/.git" ]; then
            cd "$dir" || continue
            
            # 現在のブランチを取得
            current_branch=$(git branch --show-current 2>/dev/null)
            echo "Branch: $current_branch"
            
            # リモートトラッキング設定をチェック
            upstream=$(git rev-parse --abbrev-ref --symbolic-full-name @{u} 2>/dev/null)
            if [ -n "$upstream" ]; then
                echo "Upstream: $upstream"
                
                # リモートとの差分をチェック
                ahead=$(git rev-list --count "$upstream"..HEAD 2>/dev/null || echo "0")
                behind=$(git rev-list --count HEAD.."$upstream" 2>/dev/null || echo "0")
                
                if [ "$ahead" -gt 0 ] || [ "$behind" -gt 0 ]; then
                    echo -e "Status: \033[33m$ahead ahead, $behind behind\033[0m"
                else
                    echo "Status: Up to date"
                fi
            else
                echo "Upstream: No tracking branch"
                echo -e "Status: \033[33mNot tracking remote\033[0m"
            fi
            
            # ワーキングディレクトリの状態をチェック
            if ! git diff-index --quiet HEAD -- 2>/dev/null; then
                echo -e "Working Dir: \033[31mModified files present\033[0m"
            elif [ -n "$(git ls-files --others --exclude-standard 2>/dev/null)" ]; then
                echo -e "Working Dir: \033[31mUntracked files present\033[0m"
            else
                echo "Working Dir: Clean"
            fi
            
            # 最新のコミット情報
            last_commit=$(git log -1 --pretty=format:"%h - %s (%cr)" 2>/dev/null)
            echo "Last Commit: $last_commit"
            
            cd - > /dev/null
        else
            echo "Not a Git repository"
        fi
        echo ""
    fi
done

echo "=== Summary ==="
echo "Total repositories found: $(find "$WORK_DIR" -maxdepth 2 -name ".git" -type d | wc -l)"