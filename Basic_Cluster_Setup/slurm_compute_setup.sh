#!/bin/bash

# Define variables
CONTROLLER_IP="192.168.82.163"
COMPUTE_IP="192.168.82.196"
USER_NAME="<user-name>"  # Replace with the actual user name
SLURM_VERSION="21.08.8"
SLURM_DIR="/root/slurm-${SLURM_VERSION}"

# Update the system
echo "Updating the system..."
sudo apt update
sudo apt install -y build-essential munge libmunge-dev libmysqlclient-dev libssl-dev libpam0g-dev libnuma-dev perl

# Step 1: Transfer Munge Key from the Controller Node to the Compute Node
echo "Transferring Munge key from Controller to Compute Node..."
scp ${USER_NAME}@${CONTROLLER_IP}:/etc/munge/munge.key /tmp/munge.key

# Step 2: Install Munge and set up Munge key
echo "Setting up Munge key on Compute Node..."
sudo cp /tmp/munge.key /etc/munge/
sudo chown -R munge: /etc/munge /var/log/munge/
sudo chmod 0700 /etc/munge /var/log/munge/

# Step 3: Enable and start the Munge service
echo "Enabling and starting Munge service..."
sudo systemctl enable munge
sudo systemctl start munge

# Step 4: Transfer SLURM Configuration Files from Controller Node
echo "Transferring SLURM configuration files from Controller Node..."
scp ${USER_NAME}@${CONTROLLER_IP}:/etc/slurm-llnl/slurm.conf /tmp/slurm.conf
scp ${USER_NAME}@${CONTROLLER_IP}:/etc/systemd/system/slurmd.service /tmp/slurmd.service

# Step 5: Copy SLURM configuration files to proper directories
echo "Copying SLURM configuration files to Compute Node..."
sudo cp /tmp/slurm.conf /etc/slurm/
sudo cp /tmp/slurm.conf /etc/slurm-llnl/
sudo cp /tmp/slurmd.service /etc/systemd/system/

# Step 6: Enable and start the SLURM daemon (slurmd) on Compute Node
echo "Enabling and starting slurmd service..."
sudo systemctl enable slurmd
sudo systemctl start slurmd

# Step 7: Verify SLURM status on the Compute Node
echo "Verifying SLURM status on Compute Node..."
sinfo
scontrol show nodes

# Step 8: Check SLURM and Munge logs in case of issues
echo "Checking system logs for any SLURM or Munge issues..."
sudo journalctl -u slurmd
sudo journalctl -u munge

# Final message
echo "SLURM setup completed on Compute Node ${COMPUTE_IP}. Please verify by running 'sinfo' and 'scontrol show nodes'."
