// MongoDB 初始化脚本
// 为 Rocket.Chat 创建数据库和用户

db = db.getSiblingDB('rocketchat');

// 创建 Rocket.Chat 用户
db.createUser({
  user: 'rocketchat',
  pwd: 'ChangeThisMongoPassword123!',
  roles: [
    {
      role: 'dbOwner',
      db: 'rocketchat'
    }
  ]
});

// 创建必要的索引以提高性能
db.users.createIndex({ "username": 1 }, { unique: true });
db.users.createIndex({ "emails.address": 1 });
db.rocketchat_room.createIndex({ "name": 1 });
db.rocketchat_message.createIndex({ "rid": 1, "ts": 1 });
db.rocketchat_subscription.createIndex({ "u._id": 1, "rid": 1 });

print('MongoDB 初始化完成');