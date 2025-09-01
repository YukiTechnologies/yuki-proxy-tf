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

# Write redis-shake.toml with direct connections via VPC peering
cat > redis-shake.toml <<EOF
[sync_reader]
cluster = false
address = "hosted-proxies-001.fvofcj.0001.use1.cache.amazonaws.com:6379"
password = ""

[redis_writer]
cluster = true
address = "${to_address}:6379"
password = ""

[advanced]
rdb_restore_command_behavior = "rewrite"
dial_timeout = 30   # Shorter timeouts to fail fast on network issues
read_timeout = 60   # Reduced timeout to avoid hangs
write_timeout = 60  # Reduced timeout to avoid hangs
ncpu = 2           # Use 2 CPU cores for processing
log_level = "info"  # Maintain detailed logging
EOF

# Build the image
docker build -t redis-shake-local .

# Create interval-based migration script that runs indefinitely
cat > interval_migration.sh <<'EOF'
#!/bin/bash
echo "$(date): Starting Redis migration with 5-minute intervals (running indefinitely)"

# Configuration
INTERVAL_DURATION=300  # 5 minutes per interval
REST_DURATION=10       # 10 second rest between intervals
CYCLE_COUNT=0

# Run indefinitely until manually stopped
while true; do
    CYCLE_COUNT=$((CYCLE_COUNT + 1))
    echo "$(date): ===== Starting migration cycle #$CYCLE_COUNT ====="
    
    # Clean up any existing containers
    docker rm -f redis-shake-run 2>/dev/null || true
    
    # Start redis-shake container
    echo "$(date): Starting redis-shake for $INTERVAL_DURATION seconds..."
    docker run -d --name redis-shake-run redis-shake-local > /tmp/container_id.txt 2>&1
    CONTAINER_ID=$(cat /tmp/container_id.txt)
    echo "$(date): Started container $CONTAINER_ID"
    
    # Let it run for the specified interval
    START_TIME=$(date +%s)
    MONITOR_INTERVAL=15  # Check every 15 seconds
    
    while docker ps --format "table {{.Names}}" | grep -q "redis-shake-run"; do
        CURRENT_TIME=$(date +%s)
        ELAPSED=$((CURRENT_TIME - START_TIME))
        
        # Show progress every 30 seconds
        if [ $((ELAPSED % 30)) -eq 0 ] && [ $ELAPSED -gt 0 ]; then
            echo "$(date): Migration running... elapsed: $${ELAPSED}s / $${INTERVAL_DURATION}s"
            # Show recent logs
            docker logs redis-shake-run 2>/dev/null | tail -3
        fi
        
        # Stop after the interval duration
        if [ $ELAPSED -ge $INTERVAL_DURATION ]; then
            echo "$(date): 5-minute interval completed, stopping redis-shake..."
            docker kill redis-shake-run 2>/dev/null || true
            break
        fi
        
        sleep $MONITOR_INTERVAL
    done
    
    # Show final logs from this cycle
    echo "$(date): Final logs from cycle #$CYCLE_COUNT:"
    docker logs redis-shake-run 2>/dev/null | tail -5
    
    # Clean up
    docker rm redis-shake-run 2>/dev/null || true
    
    # Rest between cycles
    echo "$(date): Cycle #$CYCLE_COUNT completed. Resting for $${REST_DURATION}s..."
    echo "$(date): ===== End of cycle #$CYCLE_COUNT ====="
    echo
    
    sleep $REST_DURATION
done
EOF

chmod +x interval_migration.sh

# Run the interval migration script
./interval_migration.sh
