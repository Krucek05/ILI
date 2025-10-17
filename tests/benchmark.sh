#!/bin/bash
# Performance benchmarks for ILI Project

echo "=================================="
echo "ILI Performance Benchmarks"
echo "Started: $(date)"
echo "=================================="
echo ""

# Check if script exists
if [ ! -f "xlogin00-fit-ili.sh" ]; then
    echo "Error: Script xlogin00-fit-ili.sh not found"
    exit 1
fi

# Cleanup before benchmark
echo "Preparing clean environment..."
bash tests/cleanup.sh 2>/dev/null || true
echo ""

# Benchmark 1: Full script execution time
echo "Benchmark 1: Full Script Execution"
echo "-----------------------------------"
echo "Running script with wget, curl, vim packages..."
{ time bash xlogin00-fit-ili.sh wget curl vim > /tmp/benchmark_output.log 2>&1; } 2>&1 | grep real
echo ""

# Benchmark 2: Repository metadata generation
echo "Benchmark 2: Repository Metadata Generation"
echo "--------------------------------------------"
if [ -d /var/www/html/ukol ]; then
    cd /var/www/html/ukol
    echo "Regenerating repository metadata..."
    { time createrepo --update . > /dev/null 2>&1; } 2>&1 | grep real
    cd - > /dev/null
fi
echo ""

# Benchmark 3: YUM repository query
echo "Benchmark 3: YUM Repository Query"
echo "----------------------------------"
echo "Querying packages from ukol repository..."
{ time yum --disablerepo="*" --enablerepo="ukol" list available > /dev/null 2>&1; } 2>&1 | grep real
echo ""

# Benchmark 4: HTTP access speed
echo "Benchmark 4: HTTP Access Speed"
echo "-------------------------------"
if command -v curl &> /dev/null; then
    echo "Fetching repomd.xml via HTTP..."
    { time curl -s http://localhost/ukol/repodata/repomd.xml > /dev/null 2>&1; } 2>&1 | grep real
else
    echo "curl not available, skipping..."
fi
echo ""

# Benchmark 5: Mount/Unmount operations
echo "Benchmark 5: Mount/Unmount Operations"
echo "--------------------------------------"
echo "Testing unmount speed..."
{ time umount /var/www/html/ukol 2>/dev/null; } 2>&1 | grep real

echo "Testing mount -a speed..."
{ time mount -a 2>/dev/null; } 2>&1 | grep real
echo ""

# System information
echo "System Information:"
echo "-------------------"
echo "CPU: $(grep 'model name' /proc/cpuinfo | head -1 | cut -d: -f2 | xargs)"
echo "Memory: $(free -h | grep Mem | awk '{print $2}') total"
echo "Disk (tmp): $(df -h /var/tmp | tail -1 | awk '{print $2}') total, $(df -h /var/tmp | tail -1 | awk '{print $4}') available"
echo ""

echo "=================================="
echo "Benchmarks Complete"
echo "Completed: $(date)"
echo "=================================="
