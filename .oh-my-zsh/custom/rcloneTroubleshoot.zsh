# Function to spawn an rclone troubleshooting pod with web UI
rclone_troubleshoot() {
  local namespace="default"
  local image="rclone/rclone:latest"
  local pod_name="rclone-troubleshoot-$(date +%s)"
  local pv_size="1Gi"
  local web_ui_port="8080"
  local custom_pvc=""
  local command=""
  local config_map=""

  # Parse arguments
  while [[ $# -gt 0 ]]; do
    case "$1" in
      -n|--namespace)
        namespace="$2"
        shift 2
        ;;
      -i|--image)
        image="$2"
        shift 2
        ;;
      -p|--pod-name)
        pod_name="$2"
        shift 2
        ;;
      -s|--pv-size)
        pv_size="$2"
        shift 2
        ;;
      -u|--ui-port)
        web_ui_port="$2"
        shift 2
        ;;
      -c|--custom-pvc)
        custom_pvc="$2"
        shift 2
        ;;
      -cfg|--config-map)
        config_map="$2"
        shift 2
        ;;
      -cmd|--command)
        command="$2"
        shift 2
        ;;
      -h|--help)
        echo "rclone Troubleshooting Pod Creator"
        echo "Usage: rclone_troubleshoot [options]"
        echo ""
        echo "Options:"
        echo "  -n, --namespace NAME    Kubernetes namespace (default: default)"
        echo "  -i, --image NAME        Container image (default: rclone/rclone:latest)"
        echo "  -p, --pod-name NAME     Pod name (default: rclone-troubleshoot-timestamp)"
        echo "  -s, --pv-size SIZE      PV size (default: 1Gi) - ignored if --custom-pvc is used"
        echo "  -u, --ui-port PORT      Local port for web UI (default: 8080)"
        echo "  -c, --custom-pvc NAME   Use existing PVC instead of creating new one"
        echo "  -cfg, --config-map NAME Use existing ConfigMap containing rclone.conf"
        echo "  -cmd, --command CMD     Custom rclone command to run (default: rclone rcd --rc-web-gui)"
        echo "  -h, --help              Show this help message"
        return 0
        ;;
      *)
        echo "Unknown option: $1"
        echo "Use --help for usage information"
        return 1
        ;;
    esac
  done

  # Default command if not specified
  if [[ -z "$command" ]]; then
    command="rclone rcd --rc-web-gui --rc-addr=0.0.0.0:5572 --rc-no-auth"
  fi

  echo "Creating rclone troubleshooting pod with the following settings:"
  echo "Pod name: $pod_name"
  echo "Namespace: $namespace"
  echo "Image: $image"
  
  if [[ -n "$config_map" ]]; then
    echo "Using rclone config from ConfigMap: $config_map"
  fi
  
  if [[ -z "$custom_pvc" ]]; then
    echo "PV Size: $pv_size (new PVC will be created)"
    
    # Create PVC YAML
    cat <<EOF | kubectl apply -f -
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: ${pod_name}-data
  namespace: ${namespace}
spec:
  accessModes:
    - ReadWriteOnce
  resources:
    requests:
      storage: ${pv_size}
EOF

    # PVC has been created
    echo "PVC ${pod_name}-data created"
    pvc_name="${pod_name}-data"
  else
    echo "Using existing PVC: $custom_pvc"
    pvc_name="$custom_pvc"
  fi

  # Create the pod with mounted PV
  if [[ -n "$config_map" ]]; then
    # Create pod with both PV and ConfigMap
    cat <<EOF | kubectl apply -f -
apiVersion: v1
kind: Pod
metadata:
  name: ${pod_name}
  namespace: ${namespace}
  labels:
    app: rclone-troubleshoot
spec:
  containers:
  - name: rclone
    image: ${image}
    ports:
    - containerPort: 5572
      name: webui
    command:
    - "/bin/sh"
    - "-c"
    - "apk add --no-cache bash curl wget vim nano less tmux && mkdir -p /etc/rclone && echo '# rclone config' > /root/.bashrc && echo 'export RCLONE_CONFIG=/etc/rclone/rclone.conf' >> /root/.bashrc && rclone rcd --rc-web-gui --rc-addr=0.0.0.0:5572 --rc-no-auth"
    volumeMounts:
    - name: data-volume
      mountPath: /data
    - name: rclone-config
      mountPath: "/etc/rclone/rclone.conf"
      subPath: "rclone.conf"
    env:
    - name: RCLONE_CONFIG
      value: "/etc/rclone/rclone.conf"
  volumes:
  - name: data-volume
    persistentVolumeClaim:
      claimName: ${pvc_name}
  - name: rclone-config
    configMap:
      name: ${config_map}
      items:
      - key: rclone.conf
        path: rclone.conf
EOF
  else
    # Create pod with only PV (no ConfigMap)
    cat <<EOF | kubectl apply -f -
apiVersion: v1
kind: Pod
metadata:
  name: ${pod_name}
  namespace: ${namespace}
  labels:
    app: rclone-troubleshoot
spec:
  containers:
  - name: rclone
    image: ${image}
    ports:
    - containerPort: 5572
      name: webui
    command:
    - "/bin/sh"
    - "-c"
    - "apk add --no-cache bash curl wget vim nano less tmux && mkdir -p /etc/rclone && touch /etc/rclone/rclone.conf && echo '# rclone config' > /root/.bashrc && echo 'export RCLONE_CONFIG=/etc/rclone/rclone.conf' >> /root/.bashrc && rclone rcd --rc-web-gui --rc-addr=0.0.0.0:5572 --rc-no-auth"
    volumeMounts:
    - name: data-volume
      mountPath: /data
    env:
    - name: RCLONE_CONFIG
      value: "/etc/rclone/rclone.conf"
  volumes:
  - name: data-volume
    persistentVolumeClaim:
      claimName: ${pvc_name}
EOF
  fi

  # Wait for pod to be ready
  echo "Waiting for pod ${pod_name} to be ready..."
  kubectl wait --for=condition=ready pod/${pod_name} -n ${namespace} --timeout=120s || {
    echo "Error: Pod failed to reach ready state within timeout period"
    return 1
  }

  # Create help file with all instructions
  cat <<EOF | kubectl exec -i ${pod_name} -n ${namespace} -- tee /data/help.txt > /dev/null
=== rclone Troubleshooting Commands ===
Basic Commands:
  rclone version                      # Display version info
  rclone listremotes                  # List configured remotes
  rclone config                       # Enter interactive config
  rclone config file                  # Show config file location

Configuration:
  rclone config show                  # Show current configuration
  rclone config create remote type    # Create a new remote
  rclone config delete remote         # Delete an existing remote

Storage Operations:
  rclone ls remote:path               # List objects
  rclone lsd remote:path              # List directories only
  rclone mkdir remote:path            # Make directory
  rclone rmdir remote:path            # Remove empty directory
  rclone purge remote:path            # Remove directory and contents
  rclone size remote:path             # Calculate size of objects

File Transfer:
  rclone copy /local/path remote:path    # Copy from local to remote
  rclone copy remote:path /local/path    # Copy from remote to local
  rclone sync /local/path remote:path    # Sync from local to remote
  rclone sync remote:path /local/path    # Sync from remote to local
  rclone move /local/path remote:path    # Move from local to remote

Mount Commands:
  rclone mount remote:path /local/mount  # Mount a remote as a local filesystem

Web UI Info:
  Web UI is running on port 5572 inside the pod
  It has been port-forwarded to localhost:${web_ui_port} on your machine
  Access it at: http://localhost:${web_ui_port}

Data Volume:
  Your data volume is mounted at /data
  Configuration is stored in /etc/rclone/rclone.conf

Running Persistent Commands with tmux:
  # Basic tmux commands:
  # Create a new session:   tmux
  # Detach from session:    Press Ctrl+b, then d
  # List sessions:          tmux ls
  # Reattach to session:    tmux attach -t 0
  # Create named session:   tmux new -s session_name
  # Attach to named:        tmux attach -t session_name
  # Split screen vertical:  Ctrl+b then %
  # Split screen horizonal: Ctrl+b then "
  # Navigate between panes: Ctrl+b then arrow key
  # View this help again:   cat /data/help.txt
  # Scroll in tmux:         Ctrl+b then [  (use arrow keys, q to exit)

Data Transfer Operations:
  # Copy a file FROM your local workstation TO the pod's data volume
  kubectl cp /path/to/local/file ${namespace}/${pod_name}:/data/filename

  # Copy a file FROM the pod's data volume TO your local workstation
  kubectl cp ${namespace}/${pod_name}:/data/filename /path/to/local/destination

Common Remote Types:
  # S3:
  rclone config create s3remote s3 access_key_id YOUR_KEY secret_access_key YOUR_SECRET region YOUR_REGION

  # Google Drive:
  rclone config create gdrive drive

  # SFTP:
  rclone config create sftp sftp host example.com user youruser port 22

For help on a specific command:
  rclone help command
===================================
EOF

  # Setup port forwarding to web UI
  echo "Setting up port forward for web UI..."
  # Start the port forwarding in the background
  kubectl port-forward pod/${pod_name} ${web_ui_port}:5572 -n ${namespace} &
  PF_PID=$!
  
  # Sleep briefly to ensure port forward is established
  sleep 2
  
  # Check if port forward process is still running
  if ps -p $PF_PID > /dev/null; then
    echo "Port forward established successfully on port ${web_ui_port}"
    echo "Web UI available at: http://localhost:${web_ui_port}"
    
    # Store the PID for cleanup later
    echo $PF_PID > /tmp/rclone_pf_${pod_name}.pid
  else
    echo "Warning: Port forward failed to establish"
    echo "You can manually set it up with: kubectl port-forward pod/${pod_name} ${web_ui_port}:5572 -n ${namespace}"
  fi

  echo ""
  echo "rclone Troubleshooting Pod Ready!"
  echo "Created help file at /data/help.txt"
  echo ""
  echo "Connect to the pod:"
  echo "  kubectl exec -it ${pod_name} -n ${namespace} -- bash"
  echo ""
  echo "Access the web UI:"
  echo "  http://localhost:${web_ui_port}"
  echo ""
  echo "Data Volume:"
  echo "  Your data is stored persistently at /data in the pod"
  echo "  Configuration is saved at /etc/rclone/rclone.conf"
  echo ""
  echo "Data Transfer Operations:"
  echo "  # Copy a file FROM your local workstation TO the pod's data volume"
  echo "  kubectl cp /path/to/local/file ${namespace}/${pod_name}:/data/filename"
  echo ""
  echo "  # Copy a file FROM the pod's data volume TO your local workstation"
  echo "  kubectl cp ${namespace}/${pod_name}:/data/filename /path/to/local/destination"
  echo ""
  echo "To stop port forwarding when done:"
  echo "  kill \$(cat /tmp/rclone_pf_${pod_name}.pid)"
  echo "==================================="
  
  # Connect to the pod with bash by default and show the help file
  kubectl exec -it ${pod_name} -n ${namespace} -- /bin/bash -c "cat /data/help.txt && echo -e \"\\n\\nPress ENTER to continue to shell...\" && read && exec bash"
}

# Function to clean up the rclone troubleshooting resources
rclone_cleanup() {
  local pod_name=$1
  local namespace=${2:-default}
  
  if [[ -z "$pod_name" ]]; then
    echo "Please provide a pod name to clean up"
    echo "Usage: rclone_cleanup POD_NAME [NAMESPACE]"
    return 1
  fi
  
  # Kill the port-forwarding process if it exists
  if [[ -f "/tmp/rclone_pf_${pod_name}.pid" ]]; then
    echo "Stopping port forwarding..."
    kill $(cat /tmp/rclone_pf_${pod_name}.pid) 2>/dev/null || true
    rm /tmp/rclone_pf_${pod_name}.pid
  fi
  
  # Delete the pod
  echo "Deleting pod ${pod_name}..."
  kubectl delete pod ${pod_name} -n ${namespace}
  
  # Find and delete the associated PVC if it exists
  if kubectl get pvc ${pod_name}-data -n ${namespace} &>/dev/null; then
    echo "Deleting PVC ${pod_name}-data..."
    kubectl delete pvc ${pod_name}-data -n ${namespace}
  else
    echo "No matching PVC found for ${pod_name}"
  fi
  
  echo "Cleanup complete!"
}

# Create the aliases for the functions
alias rclone-debug='rclone_troubleshoot'
alias rclone-cleanup='rclone_cleanup'
