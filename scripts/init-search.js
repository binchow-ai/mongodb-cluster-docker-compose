// MongoDB Search 初始化脚本
// 适用于 MongoDB 8.2+ Community Edition

print("=== MongoDB Search 初始化脚本 ===");

// 等待分片集群完全初始化
sleep(5000);

try {
    // 连接到路由节点
    print("连接到MongoDB分片集群...");
    
    // 检查分片状态
    var shardStatus = sh.status();
    print("分片集群状态检查完成");
    
    // 创建测试数据库和集合（如果不存在）
    use('searchTestDB');
    
    print("创建测试集合...");
    
    // 插入一些测试数据用于搜索演示
    db.documents.insertMany([
        {
            title: "MongoDB 搜索教程",
            content: "学习如何在MongoDB中使用全文搜索功能",
            tags: ["mongodb", "search", "tutorial"],
            category: "database",
            author: "MongoDB开发者"
        },
        {
            title: "Vector Search 入门",
            content: "向量搜索是AI应用的重要组成部分，可以实现语义搜索",
            tags: ["vector", "ai", "search"],
            category: "ai",
            author: "AI研究员"
        },
        {
            title: "分片集群配置",
            content: "如何正确配置MongoDB分片集群以获得最佳性能",
            tags: ["sharding", "performance", "config"],
            category: "database",
            author: "DBA专家"
        }
    ]);
    
    print("测试数据插入完成");
    
    // 创建文本索引用于搜索
    print("创建搜索索引...");
    db.documents.createIndex({
        title: "text",
        content: "text",
        tags: "text"
    }, {
        name: "text_search_index",
        default_language: "chinese"
    });
    
    print("搜索索引创建完成");
    
    // 验证搜索功能
    print("测试搜索功能...");
    var searchResult = db.documents.find({
        $text: { $search: "MongoDB" }
    }).toArray();
    
    print("搜索测试结果:", searchResult.length, "个文档");
    
    print("=== MongoDB Search 初始化完成 ===");
    
} catch (error) {
    print("初始化过程中发生错误:", error);
}