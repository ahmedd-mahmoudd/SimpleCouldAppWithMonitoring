#!/bin/bash

# Variables
KEY_PATH="TaskTracker.pem"     # Path to your EC2 key pair
USER="ubuntu"                      # EC2 username
HOST="54.174.196.52"         # EC2 public IP or DNS
LOCAL_PATH="."     # Path to the local code directory
REMOTE_PATH="/home/ubuntu"     # Path on the EC2 instance where code will be placed
DOCKER_COMPOSE_FILE="docker-compose.yml" # Docker Compose file name
DATE=$(date +%Y%m%d)                 # Get the current date (format: YYYYMMDD)

# Function to display usage information
usage() {
    echo "Usage: $0 {transfer|build|run|stop|test}"
    exit 1
}

# Transfer code to EC2 using scp
transfer_code() {
    echo "Transferring code to EC2 instance..."
    scp -i "$KEY_PATH" -r ./* "$USER@$HOST:$REMOTE_PATH" >&2
    if [ $? -eq 0 ]; then
        echo "Code transferred successfully!"
    else
        echo "Error during code transfer." >&2
        exit 1
    fi
}

# Build the Docker image on EC2
build_image() {
    echo "Building Docker image on EC2 instance..."
    ssh -i "$KEY_PATH" -t "$USER@$HOST" << EOF
        cd $REMOTE_PATH
        sudo docker-compose -f $DOCKER_COMPOSE_FILE build
EOF
    if [ $? -eq 0 ]; then
        echo "Docker image built successfully!"
    else
        echo "Error during Docker image build." >&2
        exit 1
    fi
}

# Run the Docker containers using Docker Compose on EC2
run_container() {
    echo "Running Docker containers on EC2 instance using docker-compose..."
    ssh -i "$KEY_PATH" "$USER@$HOST" << EOF
        cd $REMOTE_PATH
        sudo docker-compose -f $DOCKER_COMPOSE_FILE up -d
EOF
    if [ $? -eq 0 ]; then
        echo "Docker containers started successfully using docker-compose!"
    else
        echo "Error during Docker containers start." >&2
        exit 1
    fi
}

# Stop the running Docker containers using Docker Compose on EC2
stop_container() {
    echo "Stopping Docker containers on EC2 instance using docker-compose..."
    ssh -i "$KEY_PATH" "$USER@$HOST" << EOF
        cd $REMOTE_PATH
        sudo docker-compose -f $DOCKER_COMPOSE_FILE down
EOF
    if [ $? -eq 0 ]; then
        echo "Docker containers stopped successfully using docker-compose!"
    else
        echo "Error during Docker containers stop." >&2
        exit 1
    fi
}

test_connection(){
    echo "Testing the web server connection"
    ssh -i "$KEY_PATH" "$USER@$HOST" "curl -s -o /dev/null -w '%{http_code}' http://localhost:80"
    
    if [ $? -eq 0 ]; then
        HTTP_STATUS=$(ssh -i "$KEY_PATH" "$USER@$HOST" "curl -s -o /dev/null -w '%{http_code}' http://localhost:80")
        if [ "$HTTP_STATUS" -eq 200 ]; then
            echo "The server is up and running (HTTP status: 200 OK)"
        else
            echo "The server is up, but returned a non-200 status code: $HTTP_STATUS"
            exit 1
        fi
    else
        echo "Error: Unable to connect to the web server" >&2
        exit 1
    fi
}

# Main script logic
echo "What do you want to do? (transfer/build/run/stop/test):"
read ACTION

case "$ACTION" in
    transfer)
        transfer_code
        ;;
    build)
        build_image
        ;;
    run)
        run_container
        ;;
    stop)
        stop_container
        ;;
    test)
    test_connection
    ;;
    *)
        echo "Invalid option. Please choose 'transfer', 'build', 'run', or 'stop'."
        exit 1
        ;;
esac
