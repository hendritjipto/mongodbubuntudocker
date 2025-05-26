#!/bin/bash

echo "⏳ Waiting for MongoDB to start..."
sleep 30

echo "🔧 Initiating replica set..."
mongosh --tls true --host localhost --tlsAllowInvalidHostnames <<EOF
rs.initiate(
  {
    _id: "mongo-replica",
    members: [
      { _id: 0, host: "mongo1.mongodb.lab:27017", priority: 8 },
      { _id: 1, host: "mongo2.mongodb.lab:27018", priority: 7 },
      { _id: 2, host: "mongo3.mongodb.lab:27019", priority: 6 }
    ]
  }
)
EOF

echo "✅ Replica set initiated."

echo "⏳ Waiting a bit for replica set to stabilize..."
sleep 30

echo "🔧 Creating admin user..."
mongosh --tls true --host localhost --tlsAllowInvalidHostnames <<EOF
use admin

db.createUser({
  user: "root",
  pwd: "example",
  roles: [ { role: "root", db: "admin" } ]
})
EOF

echo "✅ Admin user created."
echo "🏁 Replica set initialization complete."
