#!/bin/bash

# MongoDB Community Search 功能测试脚本
# 适用于 MongoDB 8.2+ 分片集群

echo "=== MongoDB Community Search 功能测试 ==="

# 等待集群完全启动
echo "等待MongoDB集群启动..."
sleep 30

# 初始化搜索功能
echo "初始化搜索功能..."
docker exec -it router-01 mongosh --port 27017 --file /scripts/init-search.js

echo ""
echo "=== 搜索功能测试 ==="

# 测试基本文本搜索
echo "1. 测试基本文本搜索："
docker exec -it router-01 mongosh --port 27017 --eval "
use searchTestDB;
print('搜索包含 MongoDB 的文档:');
db.documents.find({\$text: {\$search: 'MongoDB'}}, {score: {\$meta: 'textScore'}}).sort({score: {\$meta: 'textScore'}}).forEach(printjson);
"

echo ""
echo "2. 测试多关键词搜索："
docker exec -it router-01 mongosh --port 27017 --eval "
use searchTestDB;
print('搜索包含 search 和 AI 的文档:');
db.documents.find({\$text: {\$search: 'search AI'}}, {score: {\$meta: 'textScore'}}).sort({score: {\$meta: 'textScore'}}).forEach(printjson);
"

echo ""
echo "3. 测试聚合管道搜索："
docker exec -it router-01 mongosh --port 27017 --eval "
use searchTestDB;
print('使用聚合管道进行搜索:');
db.documents.aggregate([
  {\$match: {\$text: {\$search: 'database'}}},
  {\$addFields: {score: {\$meta: 'textScore'}}},
  {\$sort: {score: -1}},
  {\$project: {title: 1, category: 1, score: 1}}
]).forEach(printjson);
"

echo ""
echo "4. 检查搜索索引："
docker exec -it router-01 mongosh --port 27017 --eval "
use searchTestDB;
print('当前搜索索引:');
db.documents.getIndexes().forEach(printjson);
"

echo ""
echo "5. 检查分片分布："
docker exec -it router-01 mongosh --port 27017 --eval "
use searchTestDB;
print('集合分片分布:');
try {
  db.documents.getShardDistribution();
} catch(e) {
  print('集合未分片或分片信息不可用');
}
"

echo ""
echo "=== MongoDB Community Search 测试完成 ==="
echo ""
echo "要手动测试搜索功能，请使用以下连接字符串："
echo "mongodb://localhost:27017"
echo ""
echo "mongot 服务端口："
echo "- Shard 01: localhost:7700"
echo "- Shard 02: localhost:7701"
echo ""
echo "示例搜索查询："
echo "use searchTestDB;"
echo "db.documents.find({\$text: {\$search: 'your_search_term'}});"