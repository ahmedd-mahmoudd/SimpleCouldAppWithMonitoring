#!/bin/bash

IMAGE_NAME="task-tracker"
CONTAINER_NAME="task-tracker-container"
PORT="80"

# Function to build the Docker image
build_image() {
    echo "Building the Docker image..."
    if docker build -t $IMAGE_NAME .; then
        echo "Docker image '$IMAGE_NAME' built successfully."
    else
        echo "Error: Failed to build the Docker image." >&2
        exit 1
    fi
}

# Function to run the Docker container
run_container() {
    # Check if the container is already running
    if docker ps -f name=$CONTAINER_NAME | grep $CONTAINER_NAME > /dev/null; then
        echo "Error: Container '$CONTAINER_NAME' is already running." >&2
        exit 1
    fi

    echo "Starting the Docker container..."
    if docker run -d -p $PORT:$PORT --name $CONTAINER_NAME $IMAGE_NAME; then
        echo "Docker container '$CONTAINER_NAME' started successfully on port $PORT."
        echo "Access the application at http://localhost:$PORT"
    else
        echo "Error: Failed to start the Docker container." >&2
        exit 1
    fi
}

# Function to stop and remove the Docker container
stop_container() {
    # Check if the container is running
    if docker ps -f name=$CONTAINER_NAME | grep $CONTAINER_NAME > /dev/null; then
        echo "Stopping the Docker container..."
        if docker stop $CONTAINER_NAME; then
            echo "Container '$CONTAINER_NAME' stopped successfully."
            echo "Removing the container..."
            docker rm $CONTAINER_NAME
            echo "Container '$CONTAINER_NAME' removed."
        else
            echo "Error: Failed to stop the Docker container." >&2
            exit 1
        fi
    else
        echo "Error: No running container found with the name '$CONTAINER_NAME'." >&2
    fi
}

# Main script logic
echo "What do you want to do? (build/run/stop):"
read ACTION

case "$ACTION" in
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
        echo "Invalid option. Please choose 'build', 'run', or 'stop'."
        exit 1
        ;;
esac
