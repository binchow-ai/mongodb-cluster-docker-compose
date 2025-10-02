# MongoDB Community Search 集成指南

## 概述

本项目已集成 MongoDB Community Search (mongot) 功能，支持在 MongoDB 8.2+ 分片集群中进行全文搜索和向量搜索。

## 新增功能

### 1. MongoDB Community Search 支持
- **mongot 服务**: 为每个分片配置独立的搜索服务
- **全文搜索**: 支持中文和多语言文本搜索
- **搜索索引**: 自动创建和管理搜索索引
- **分片集群集成**: 无缝集成到现有的分片架构中

### 2. 服务架构
```
┌─────────────────┐    ┌─────────────────┐
│   mongos路由    │    │   mongos路由    │
│   (27017)       │    │   (27018)       │
└─────────────────┘    └─────────────────┘
         │                       │
    ┌────┴────────────────────────┴────┐
    │           Config Servers          │
    │  cfg1(27019) cfg2(27020) cfg3... │
    └─────────────┬───────────────────┘
                  │
    ┌─────────────┴───────────────────┐
    │          Sharded Cluster         │
    │                                  │
    │  ┌─────────────────────────────┐ │
    │  │     Shard 01 Replica Set    │ │
    │  │   + mongot-shard01:7700     │ │
    │  └─────────────────────────────┘ │
    │                                  │
    │  ┌─────────────────────────────┐ │
    │  │     Shard 02 Replica Set    │ │
    │  │   + mongot-shard02:7701     │ │
    │  └─────────────────────────────┘ │
    └──────────────────────────────────┘
```

## 快速开始

### 1. 启动集群
```bash
# 启动包含搜索功能的分片集群
docker-compose up -d

# 等待初始化完成（约30秒）
docker-compose logs -f router01
```

### 2. 验证部署
```bash
# 检查所有服务状态
docker-compose ps

# 验证分片状态
docker exec -it router-01 mongosh --port 27017 --eval "sh.status()"

# 验证搜索服务
curl -X GET http://localhost:7700/health  # Shard 01
curl -X GET http://localhost:7701/health  # Shard 02
```

### 3. 初始化搜索功能
```bash
# 运行搜索初始化脚本
docker exec -it router-01 mongosh --port 27017 --file /scripts/init-search.js

# 或运行完整测试
./scripts/test-search.sh
```

## 搜索功能使用

### 1. 基本文本搜索
```javascript
// 连接到MongoDB
use searchTestDB;

// 基本文本搜索
db.documents.find({
    $text: { $search: "MongoDB" }
});

// 带评分的搜索
db.documents.find(
    { $text: { $search: "MongoDB search" } },
    { score: { $meta: "textScore" } }
).sort({ score: { $meta: "textScore" } });
```

### 2. 高级搜索功能
```javascript
// 短语搜索
db.documents.find({
    $text: { $search: "\"MongoDB search\"" }
});

// 排除关键词
db.documents.find({
    $text: { $search: "database -mysql" }
});

// 聚合管道搜索
db.documents.aggregate([
    { $match: { $text: { $search: "AI vector" } } },
    { $addFields: { score: { $meta: "textScore" } } },
    { $sort: { score: -1 } },
    { $limit: 10 }
]);
```

### 3. 创建搜索索引
```javascript
// 创建文本索引
db.collection.createIndex({
    title: "text",
    content: "text",
    tags: "text"
}, {
    name: "search_index",
    default_language: "chinese"
});

// 创建复合索引
db.collection.createIndex({
    category: 1,
    title: "text",
    content: "text"
});
```

## 配置说明

### 1. Docker Compose 新增服务

#### mongot-shard01 服务
- **端口**: 7700
- **功能**: 为分片1提供搜索服务
- **连接**: shard01 replica set

#### mongot-shard02 服务
- **端口**: 7701
- **功能**: 为分片2提供搜索服务
- **连接**: shard02 replica set

### 2. 配置文件更新

#### MongoDB 配置 (mongod-shard*.conf)
```yaml
# 启用搜索索引管理
searchIndexManagement:
  enabled: true
```

#### mongot 配置 (mongot.conf)
```yaml
# MongoDB连接配置
mongodb:
  shard01_uri: "mongodb://shard01-a:27017,..."
  shard02_uri: "mongodb://shard02-a:27017,..."

# 搜索配置
search:
  enabled: true
  default_language: "chinese"
  max_results: 100
```

## 监控和维护

### 1. 健康检查
```bash
# 检查mongot服务状态
curl http://localhost:7700/health
curl http://localhost:7701/health

# 检查MongoDB搜索索引
docker exec -it router-01 mongosh --eval "
use yourDatabase;
db.yourCollection.getIndexes();
"
```

### 2. 日志查看
```bash
# MongoDB日志
docker-compose logs mongod-shard01
docker-compose logs mongod-shard02

# mongot日志
docker-compose logs mongot-shard01
docker-compose logs mongot-shard02
```

### 3. 性能监控
```bash
# 查看搜索性能统计
docker exec -it router-01 mongosh --eval "
db.adminCommand('serverStatus').metrics.queryExecutor
"
```

## 故障排除

### 1. 常见问题

#### mongot 服务无法启动
- 检查MongoDB服务是否正常运行
- 验证网络连接配置
- 查看mongot日志: `docker-compose logs mongot-shard01`

#### 搜索查询返回空结果
- 确认已创建文本索引
- 检查查询语法是否正确
- 验证数据是否存在

#### 性能问题
- 调整mongot内存配置
- 优化搜索索引
- 检查分片键分布

### 2. 调试命令
```bash
# 检查所有服务状态
docker-compose ps

# 重启特定服务
docker-compose restart mongot-shard01

# 查看详细日志
docker-compose logs -f mongot-shard01
```

## 生产环境建议

### 1. 安全配置
- 启用TLS加密
- 配置身份验证
- 限制网络访问

### 2. 性能优化
- 调整mongot内存分配
- 优化搜索索引策略
- 监控查询性能

### 3. 备份和恢复
- 包含搜索索引的备份策略
- mongot数据目录备份
- 灾难恢复计划

## 版本兼容性

- **MongoDB**: 8.2.0+
- **mongot**: latest (兼容MongoDB 8.2+)
- **Docker**: 20.10+
- **Docker Compose**: 2.0+

## 更多资源

- [MongoDB Search 官方文档](https://docs.mongodb.com/manual/text-search/)
- [MongoDB Community Search 指南](https://docs.mongodb.com/community-search/)
- [分片集群管理](https://docs.mongodb.com/manual/sharding/)