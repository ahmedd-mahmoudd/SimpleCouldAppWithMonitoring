#!/bin/bash

# Variables
KEY_PATH="TaskTracker.pem"     # Path to your EC2 key pair
USER="ubuntu"                      # EC2 username
HOST= "ec2-54-174-196-52.compute-1.amazonaws.com"         # EC2 public IP or DNS
LOCAL_PATH="."     # Path to the local code directory
REMOTE_PATH="/home/ubuntu"     # Path on the EC2 instance where code will be placed
DOCKER_IMAGE="task-tracker"          # Docker image name
DOCKER_CONTAINER="task-tracker-container" # Docker container name
PORT="80"                            # Application port

# Function to display usage information
usage() {
    echo "Usage: $0 {transfer|build|run|stop}"
    exit 1
}

# Transfer code to EC2 using scp
transfer_code() {
    echo "Transferring code to EC2 instance..."
    scp -i TaskTracker.pem -r ./* ubuntu@ec2-54-174-196-52.compute-1.amazonaws.com:/home/ubuntu >&2
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
    ssh -i "$KEY_PATH" "$USER@$HOST" << EOF
        cd $REMOTE_PATH
        docker build -t $DOCKER_IMAGE .
EOF
    if [ $? -eq 0 ]; then
        echo "Docker image built successfully!"
    else
        echo "Error during Docker image build." >&2
        exit 1
    fi
}

# Run the Docker container on EC2
run_container() {
    echo "Running Docker container on EC2 instance..."
    ssh -i "$KEY_PATH" "$USER@$HOST" << EOF
        if docker ps -f name=$DOCKER_CONTAINER | grep $DOCKER_CONTAINER > /dev/null; then
            echo "Error: Container '$DOCKER_CONTAINER' is already running." >&2
            exit 1
        else
            docker run -d -p $PORT:$PORT --name $DOCKER_CONTAINER $DOCKER_IMAGE
        fi
EOF
    if [ $? -eq 0 ]; then
        echo "Docker container started successfully on port $PORT!"
    else
        echo "Error during Docker container start." >&2
        exit 1
    fi
}

# Stop the running Docker container on EC2
stop_container() {
    echo "Stopping Docker container on EC2 instance..."
    ssh -i "$KEY_PATH" "$USER@$HOST" << EOF
        if docker ps -f name=$DOCKER_CONTAINER | grep $DOCKER_CONTAINER > /dev/null; then
            docker stop $DOCKER_CONTAINER
            docker rm $DOCKER_CONTAINER
            echo "Docker container stopped and removed successfully."
        else
            echo "Error: No running container found with the name '$DOCKER_CONTAINER'." >&2
        fi
EOF
    if [ $? -eq 0 ]; then
        echo "Docker container stopped and removed successfully!"
    else
        echo "Error during Docker container stop." >&2
        exit 1
    fi
}

# Main script logic
echo "What do you want to do? (transfer/build/run/stop):"
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
    *)
        echo "Invalid option. Please choose 'transfer', 'build', 'run', or 'stop'."
        exit 1
        ;;
esac
