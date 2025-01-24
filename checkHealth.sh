#!/bin/bash
# System Health Check
echo "System Health Report - $(date)"
echo "Disk Usage:"
df -h | grep '^/dev'

echo "Memory Usage:"
free -h

echo "Running Services:"
systemctl list-units --type=service --state=running

echo "Recent System Updates:"
grep 'upgrade' /var/log/dpkg.log 2>/dev/null || echo "No recent updates found (or log access restricted)."
