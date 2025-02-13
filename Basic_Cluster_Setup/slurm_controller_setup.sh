#!/bin/bash

# Set Variables
CONTROLLER_IP="192.168.82.163"
COMPUTE_IP="192.168.82.196"
SLURM_VERSION="21.08.8"
SLURM_DIR="/root/slurm-${SLURM_VERSION}"

# Step 1: Download SLURM
echo "Downloading SLURM ${SLURM_VERSION}..."
wget https://download.schedmd.com/slurm/slurm-${SLURM_VERSION}.tar.bz2

# Step 2: Install Dependencies
echo "Installing required dependencies..."
apt update
apt install -y build-essential munge libmunge-dev libmunge2 libmysqlclient-dev libssl-dev libpam0g-dev libnuma-dev perl

# Step 3: Extract SLURM
echo "Extracting SLURM ${SLURM_VERSION}..."
tar -xvjf slurm-${SLURM_VERSION}.tar.bz2

# Step 4: Navigate to SLURM directory
cd slurm-${SLURM_VERSION}

# Step 5: Configure SLURM
echo "Configuring SLURM..."
./configure --prefix=${SLURM_DIR}

# Step 6: Compile and Install SLURM
echo "Compiling SLURM..."
make
echo "Installing SLURM..."
make install

# Step 7: Clone for Compute Node
# NOTE: This can be done manually or via other automation (e.g., copying the installation folder to compute nodes).

# Step 8: Create Munge Key
echo "Creating Munge Key..."
create-munge-key

# Step 9: Set Permissions for Munge Key
echo "Setting permissions for Munge Key..."
chown munge: /etc/munge/munge.key
chmod 400 /etc/munge/munge.key

# Step 10: Transfer Munge Key to Compute Node (Use SCP for actual transfer)
echo "Transferring Munge Key to Compute Node..."
scp -r /etc/munge/munge.key <user-name>@${COMPUTE_IP}:/tmp
ssh <user-name>@${COMPUTE_IP} "chown -R munge: /etc/munge /var/log/munge && chmod 0700 /etc/munge /var/log/munge"

# Step 11: Enable and Start Munge
echo "Enabling and starting Munge..."
systemctl enable munge
systemctl start munge

# Step 12: Create SLURM Directories
echo "Creating SLURM directories..."
mkdir /etc/slurm-llnl

# Step 13: Copy SLURM Configuration Files
echo "Copying SLURM configuration files..."
cp slurm.conf.example /root/slurm-${SLURM_VERSION}/etc/
cp slurm.conf /etc/slurm/
cp slurm.conf /etc/slurm-llnl/

# Step 14: Modify slurm.conf (replace with actual settings in the file)
echo "Modifying slurm.conf..."
cat <<EOL > /etc/slurm/slurm.conf
ClusterName=cluster
SlurmctldHost=${CONTROLLER_IP}
AuthType=auth/munge
ProctrackType=proctrack/cgroup  # or linuxproc if you face issues
SlurmUser=root
AccountingStorageType=accounting_storage/slurmdbd
NodeName=controller CPUs=4 State=UNKNOWN
NodeName=compute[1-2] CPUs=4 State=UNKNOWN
PartitionName=newpartition Nodes=ALL Default=YES MaxTime=INFINITE State=UP
EOL

# Step 15: Configure slurmdbd.conf
echo "Configuring slurmdbd.conf..."
cat <<EOL > /etc/slurm-llnl/slurmdbd.conf
DbdAddr=${CONTROLLER_IP}
DbdHost=controller
SlurmUser=root
StoragePass=dhpcsa
StorageUser=root
EOL

# Step 16: Copy systemd service files
echo "Copying SLURM systemd service files..."
cp slurmctld.service /etc/systemd/system/
cp slurmd.service /etc/systemd/system/

# Step 17: Install mailutils
echo "Installing mailutils..."
apt-get install -y mailutils

# Step 18: Copy SLURM Configuration to Compute Node (use SCP to compute node)
scp /etc/slurm-llnl/slurm.conf <user-name>@${COMPUTE_IP}:/tmp
scp /etc/slurm-llnl/slurm.conf /etc/slurm/
scp /etc/slurm-llnl/slurm.conf /etc/slurm-llnl/

# Step 19: Install MariaDB (for SLURM database)
echo "Installing MariaDB..."
apt install -y mariadb-server

# Step 20: Configure MariaDB
echo "Configuring MariaDB..."
mysql -u root -p <<EOF
CREATE USER 'root'@'controller1' IDENTIFIED BY 'root';
GRANT ALL PRIVILEGES ON *.* TO 'root'@'controller1';
FLUSH PRIVILEGES;
EOF

# Step 21: Set up slurmdbd.service
echo "Setting up slurmdbd service..."
cp slurmdbd.service /etc/systemd/system/

# Step 22: Install SLURM on Compute Nodes
# Note: This can be done by copying the necessary SLURM configuration and services to compute nodes as follows:

# Transfer Munge Key to Compute Node
scp -r /tmp/munge.key ${COMPUTE_IP}:/etc/munge/

# Set permissions on the Compute Node
ssh ${COMPUTE_IP} "chown -R munge: /etc/munge /var/log/munge/ && chmod 0700 /etc/munge /var/log/munge/"

# Copy SLURM configuration files to Compute Node
scp -r /tmp/slurm.conf ${COMPUTE_IP}:/root/slurm-${SLURM_VERSION}/etc/
scp -r slurmd.service ${COMPUTE_IP}:/etc/systemd/system/
scp -r /tmp/slurm.conf ${COMPUTE_IP}:/etc/slurm/
scp -r /tmp/slurm.conf ${COMPUTE_IP}:/etc/slurm-llnl/

# Enable and start SLURM services on Compute Node
ssh ${COMPUTE_IP} "systemctl enable slurmd && systemctl start slurmd"

# Final step: Start SLURM Controller Service
systemctl enable slurmctld
systemctl start slurmctld

echo "SLURM installation completed on Controller Node!"
