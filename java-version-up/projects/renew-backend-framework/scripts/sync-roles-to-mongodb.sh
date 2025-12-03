#!/bin/bash
# sync-roles-to-mongodb.sh
# service-frameworkのRole enumからMongoDBへ権限を同期するスクリプト

set -e

# 設定
SERVICE_FRAMEWORK_PATH="${SERVICE_FRAMEWORK_PATH:-/home/gmaeda/projects/drjoy/tool-orchestrator/work/service-framework}"
MONGODB_URI="${MONGODB_URI:-mongodb://localhost:27017}"
DB_NAME="${DB_NAME:-drjoy}"
BACKUP_ENABLED="${BACKUP_ENABLED:-true}"

# 色付き出力
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${GREEN}=== service-framework → MongoDB Role Sync ===${NC}"
echo "Service Framework Path: $SERVICE_FRAMEWORK_PATH"
echo "MongoDB URI: $MONGODB_URI"
echo "Database: $DB_NAME"
echo ""

# Step 1: Javaファイルの存在確認
ROLE_FILE="$SERVICE_FRAMEWORK_PATH/src/main/java/jp/drjoy/service/framework/model/Role.java"
if [ ! -f "$ROLE_FILE" ]; then
    echo -e "${RED}Error: Role.java not found at $ROLE_FILE${NC}"
    exit 1
fi

echo -e "${GREEN}Step 1: Found Role.java${NC}"

# Step 2: バックアップ（オプション）
if [ "$BACKUP_ENABLED" = "true" ]; then
    echo -e "${YELLOW}Step 2: Creating backup...${NC}"
    BACKUP_DATE=$(date +%Y%m%d_%H%M%S)
    mongodump --uri="$MONGODB_URI" --db="$DB_NAME" --collection=roles --out="backup_$BACKUP_DATE"
    echo -e "${GREEN}Backup created: backup_$BACKUP_DATE${NC}"
fi

# Step 3: Roleの抽出とMongoDB投入
echo -e "${YELLOW}Step 3: Extracting roles and syncing to MongoDB...${NC}"

# 一時ファイルを作成してMongoDBコマンドを生成
TEMP_JS_FILE="/tmp/sync_roles_$$.js"
cat > "$TEMP_JS_FILE" << 'EOF'
// MongoDB sync script
use drjoy;

print("Starting role synchronization...");

var rolesFromEnum = [
EOF

# Role.javaからロール情報を抽出してJavaScript配列を生成
grep -E '^\s*\/\*\*.*\*\/\s*$|^\s*[A-Z_]+\("[A-Z_]+"\)' "$ROLE_FILE" | \
while IFS= read -r line1; do
    if [[ $line1 =~ ^\s*\/\*\* ]]; then
        # コメント行を読み込み
        DESCRIPTION=$(echo "$line1" | sed -E 's/^\s*\/\*\*\s*(.+)\s*\*\/\s*$/\1/' | sed 's/#[0-9]*: *//')
        read -r line2
        if [[ $line2 =~ ([A-Z_]+)\(\"([A-Z_]+)\"\) ]]; then
            ENUM_NAME="${BASH_REMATCH[1]}"
            CODE="${BASH_REMATCH[2]}"
            echo "  { name: \"$CODE\", description: \"$DESCRIPTION\", enumName: \"$ENUM_NAME\" }," >> "$TEMP_JS_FILE"
        fi
    fi
done

cat >> "$TEMP_JS_FILE" << 'EOF'
];

// 既存のロールを取得
var existingRoles = {};
db.roles.find().forEach(function(doc) {
    existingRoles[doc.name] = doc;
});

var stats = { added: 0, updated: 0, unchanged: 0 };

// enumのロールを同期
rolesFromEnum.forEach(function(role) {
    if (existingRoles[role.name]) {
        // 既存ロールの更新チェック
        var existing = existingRoles[role.name];
        if (existing.description !== role.description) {
            db.roles.updateOne(
                { name: role.name },
                { $set: { 
                    description: role.description,
                    updatedAt: new Date()
                }}
            );
            stats.updated++;
            print("Updated: " + role.name);
        } else {
            stats.unchanged++;
        }
        delete existingRoles[role.name];
    } else {
        // 新規ロール追加
        db.roles.insertOne({
            name: role.name,
            description: role.description,
            createdAt: new Date()
        });
        stats.added++;
        print("Added: " + role.name);
    }
});

// enumに存在しないDBのロールを警告
Object.keys(existingRoles).forEach(function(roleName) {
    if (!existingRoles[roleName].deleted) {
        print("WARNING: Role '" + roleName + "' exists in DB but not in enum");
    }
});

print("\n=== Sync Summary ===");
print("Added: " + stats.added);
print("Updated: " + stats.updated);
print("Unchanged: " + stats.unchanged);
print("Total in enum: " + rolesFromEnum.length);
print("Total in DB: " + db.roles.count());
EOF

# MongoDBスクリプトを実行
mongosh "$MONGODB_URI/$DB_NAME" < "$TEMP_JS_FILE"

# 一時ファイルを削除
rm -f "$TEMP_JS_FILE"

echo ""
echo -e "${GREEN}=== Synchronization Complete ===${NC}"

# Step 4: 検証
echo -e "${YELLOW}Step 4: Verification...${NC}"
ENUM_COUNT=$(grep -c '^\s*[A-Z_]+\("[A-Z_]+"\)' "$ROLE_FILE" || true)
DB_COUNT=$(mongosh --quiet "$MONGODB_URI/$DB_NAME" --eval "db.roles.count()")

echo "Roles in enum: $ENUM_COUNT"
echo "Roles in DB: $DB_COUNT"

if [ "$ENUM_COUNT" -ne "$DB_COUNT" ]; then
    echo -e "${YELLOW}Warning: Role count mismatch between enum and database${NC}"
else
    echo -e "${GREEN}Role counts match!${NC}"
fi

echo ""
echo -e "${GREEN}Sync completed successfully!${NC}"
echo "To rollback, restore from backup: backup_$BACKUP_DATE"