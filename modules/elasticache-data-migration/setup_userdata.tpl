#!/bin/bash
yum update -y
# Docker is pre-installed on ECS-optimized AMI
service docker start
usermod -aG docker ec2-user

cd /home/ec2-user
mkdir -p shake
cd shake

# Write Dockerfile
cat > Dockerfile <<EOF
FROM ghcr.io/tair-opensource/redisshake:latest
COPY redis-shake.toml /config/redis-shake.toml
ENTRYPOINT ["./redis-shake", "/config/redis-shake.toml"]
EOF

# Write redis-shake.toml with your config
cat > redis-shake.toml <<EOF
[scan_reader]
cluster = false
address = "${from_address}:6379"
password = ""

[redis_writer]
cluster = true
address = "${to_address}:6379"
password = ""

[advanced]
rdb_restore_command_behavior = "rewrite"
EOF

# Build & run
docker build -t redis-shake-local .
docker run --rm redis-shake-local