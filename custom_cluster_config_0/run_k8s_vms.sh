#!/bin/bash

# Define VM names (ensure the full path to the VMX files or use VM names without extensions)
VM_LOCATION="$HOME/VMs"
VM_NAMES=("k8s_master.vmwarevm" "k8s_node_0.vmwarevm" "k8s_node_1.vmwarevm")

# Corresponding IP addresses for the VMs
VM_IPS=("192.168.232.140" "192.168.232.141" "192.168.232.142")

# Function to check if a VM exists
check_vm_exists() {
  ls -al $VM_LOCATION | grep -q "$1" && return 0 || return 1
}

# Function to start a VM
start_vm() {
  local VM_NAME="$1"
  if check_vm_exists "$VM_NAME"; then
    echo "Starting VM: $VM_LOCATION/$VM_NAME..."
    vmrun start "$VM_LOCATION/$VM_NAME" nogui
  else
    echo "Error: VM '$VM_NAME' not found."
  fi
}

# Function to stop a VM
stop_vm() {
  local VM_NAME="$1"
  if check_vm_exists "$VM_NAME"; then
    echo "Stopping VM: $VM_LOCATION/$VM_NAME..."
    vmrun stop "$VM_LOCATION/$VM_NAME" nogui
  else
    echo "Error: VM '$VM_NAME' not found."
  fi
}

# Function to wait for a VM to be running
wait_for_vm() {
  local VM_NAME=$1
  while true; do
    STATUS=$(vmrun list | grep "$VM_NAME")
    if [[ -n "$STATUS" ]]; then
      echo "VM '$VM_NAME' is now running!"
      break
    fi
    sleep 2
  done
}

# Parse command-line arguments for --start and --stop
if [[ "$1" == "--start" ]]; then
  # Start VMs in parallel
  for VM in "${VM_NAMES[@]}"; do
    start_vm "$VM" &
  done

  # Wait for all background jobs to finish
  wait

  # Confirm VMs are running
  for VM in "${VM_NAMES[@]}"; do
    wait_for_vm "$VM"
  done

  echo "k8s VMs are running!"

  # Start a tmux session and connect to each VM in separate windows
  tmux new-session -d -s k8s_vms

  # Create a new window for each VM and SSH into it
  for i in "${!VM_IPS[@]}"; do
    tmux new-window -t k8s_vms:$(($i + 1)) -n "VM$(($i + 1))" "ssh user@${VM_IPS[$i]}"
  done

  # Attach to the tmux session
  tmux attach-session -t k8s_vms

elif [[ "$1" == "--stop" ]]; then
  # Stop VMs in parallel
  for VM in "${VM_NAMES[@]}"; do
    stop_vm "$VM" &
  done

  # Wait for all background jobs to finish
  wait

  echo "k8s VMs are stopped!"

else
  echo "Usage: $0 --start | --stop"
  echo "  --start  : Start all VMs and open a tmux session"
  echo "  --stop   : Stop all VMs"
fi
