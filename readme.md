# MongoDB Replica Set with Custom DNS and Client (Docker Compose)

This project sets up a MongoDB **replica set** using Docker Compose with:

- 3 MongoDB nodes (`mongodb1`, `mongodb2`, `mongodb3`)
- A DNS server using `bind9` configured for MongoDB SRV resolution
- A custom Ubuntu client container (`ubuntuclient`) for monitoring or testing

The goal is to create mongodb+srv connections like `mongodb+srv://rs.mongodb.lab` that resolves to the replica set nodes, allowing for easy connection management and testing.

All services are run on a custom Docker image: `pix3lize/mdbubuntu`, and use static IPs on an internal network.

---

## 📦 Services Overview

### 🔧 MongoDB Nodes (`mongodb1`, `mongodb2`, `mongodb3`)
- Run as a replica set (`mongo-replica`)
- Use individual configuration files (`mongod1.conf`, etc.)
- Share a keyfile for authentication
- Persistent storage via named Docker volumes
- `mongodb1` also runs an init script to initiate the replica set

### 🧪 Ubuntu Client (`ubuntuclient`)
- Runs a long-lived Bash session (`tail -f /dev/null`)
- Used for manual access, DNS lookups, and monitoring
- Uses internal DNS from the `bind9` server

### 🌐 DNS Server (`bind9`)
- Configured using custom BIND config files in `./config`
- Resolves hostnames and MongoDB SRV records
- Exposes DNS on ports `30053` (TCP/UDP)
- Provides DNS resolution for all services

---

## 🗂️ Folder Structure

```
dockermongoubuntu/
├── config/                   # BIND9 DNS configuration
├── test/                     # Node.js test application
├── mongod1.conf              # MongoDB config for node 1
├── mongod2.conf              # MongoDB config for node 2
├── mongod3.conf              # MongoDB config for node 3
├── init-replica.sh           # Script to initialize replica set
├── docker-compose.yml        # Main orchestration file
├── mongodb-keyfile           # Keyfile for internal Mongo auth
└── readme.md                 # This file
```

---

## 🛠️ Requirements

- Docker & Docker Compose
- ARM64 architecture support (used in all services)

---

## 🚀 Getting Started

### 1. Start the Environment

```bash
docker compose up -d
```

### 2. Access the Client

```bash
docker exec -it ubuntuclient bash
```

You can run tools like `dig mongo1`, `mongo`, or `mongotop` from this container.

### 3. Extra parameter 
When connecting to MongoDB when TLS is not setup
```bash
mongosh "mongodb+srv://<username>:<password>@rs.mongodb.lab/?tls=false"
```
---

## 🔗 DNS Zone File Summary (`mongodb.lab`)

The DNS server (`bind9`) is configured with the following records:

### A Records

| Host      | IP              |
|-----------|-----------------|
| ns        | 192.168.147.10  |
| mongo1    | 192.168.147.3   |
| mongo2    | 192.168.147.4   |
| mongo3    | 192.168.147.5   |
| root (@)  | 192.168.147.1   |

### SRV Records (Replica Set Discovery)

| Service                          | Target Host        | Port   |
|----------------------------------|--------------------|--------|
| `_mongodb._tcp.rs.mongodb.lab.` | mongo1.mongodb.lab | 27017 |
| `_mongodb._tcp.rs.mongodb.lab.` | mongo2.mongodb.lab | 27018 |
| `_mongodb._tcp.rs.mongodb.lab.` | mongo3.mongodb.lab | 27019 |

### TXT Record

Indicates the replica set name and auth source:

```text
rs.mongodb.lab. TXT "replicaSet=mongo-replica&authSource=admin"
```
---

## 🕒 Simulating Network Latency
To simulate network latency affecting specific MongoDB nodes, you can run the following commands on your host machine.

The example to add 1000ms latency to `mongodb2` and `mongodb3` from `mongodb1`. Please run it on mongodb1 host:

```bash
tc qdisc add dev eth0 root handle 1: prio
tc qdisc add dev eth0 parent 1:3 handle 30: netem delay 1000ms
tc filter add dev eth0 protocol ip parent 1:0 prio 3 u32 match ip dst 192.168.147.4/32 flowid 1:3
tc filter add dev eth0 protocol ip parent 1:0 prio 3 u32 match ip dst 192.168.147.5/32 flowid 1:3
```

To remove the latency, run:

```bash
tc qdisc del dev eth0 root
```

---

## 🔐MongoDB Replica Set with TLS and Authentication

This setup creates a secure MongoDB replica set with:

- TLS encryption for all connections
- Internal member authentication via `keyFile`
- Client authentication using `x509` and SCRAM
- Priority-based replica election
- Initial replica set configuration and admin user setup

Both CA certificate `mongodb-ca.pem` and server certificate `mongodb-server.pem` for MongoDB is located on `/home/mdb`

In addition `mongodb-ca.pem` already installed as trusted CA for ubuntu image however, some application needs extra command to read CA from the system. 

Please run this command : 

```bash
docker compose -f docker-compose-tls.yml up -d
```

📝Notes
For the intial setup such as replication initiation we're using this command, as MongoDB allow localhost connection for the initial setup (replication init and create admin user)

```bash
mongosh --tls true --host localhost --tlsAllowInvalidHostnames
```

In addition, please find the mongodb config file 
```yaml
net:
  port: 27017
  bindIpAll: true
  
  tls:
    mode: requireTLS
    certificateKeyFile: /home/mdb/mongodb-server.pem
    CAFile: /home/mdb/mongodb-ca.pem
    allowConnectionsWithoutCertificates: true
    disabledProtocols: TLS1_0,TLS1_1

security:
  keyFile: /data/replica.key
  authorization: enabled
  clusterAuthMode: x509    
```

---


## 🧹 Cleanup

```bash
docker compose down -v
```

This removes all containers and volumes.

---

## 📄 License

This project is for testing, learning, and development purposes only.