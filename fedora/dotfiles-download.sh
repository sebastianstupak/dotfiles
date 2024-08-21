#!/bin/bash

# Ensure the script is run with superuser privileges
if [ "$EUID" -ne 0 ]; then
  echo "Please run as root (e.g., using sudo)"
  exit 1
fi

# Install Git
dnf install -y git

# Check if a global Git username is already set
git_username=$(git config --global user.name)
git_email=$(git config --global user.email)

# If the Git username or email is not set, prompt for them
if [ -z "$git_username" ]; then
  read -p "Enter your GitHub username: " username
  git config --global user.name "$username"
else
  echo "Git username is already set to '$git_username'"
fi

if [ -z "$git_email" ]; then
  read -p "Enter your GitHub email: " email
  git config --global user.email "$email"
else
  echo "Git email is already set to '$git_email'"
fi

# Prompt for the directory under /home where the 'code' folder will be created
read -p "Enter the name of the directory under /home where 'code' should be created (e.g., your username): " user_dir

# Define the full path to the target directory
target_dir="/home/$user_dir/code"

# Check if the user-specified directory exists, if not, create it
if [ ! -d "/home/$user_dir" ]; then
  echo "Directory /home/$user_dir does not exist. Creating it..."
  mkdir -p "/home/$user_dir"
  chown "$user_dir:$user_dir" "/home/$user_dir"
fi

# Create the 'code' directory under the user-specified directory
if [ ! -d "$target_dir" ]; then
  echo "Creating the 'code' directory at $target_dir..."
  mkdir -p "$target_dir"
  chown "$user_dir:$user_dir" "$target_dir"
fi

# Navigate to the 'code' directory
cd "$target_dir"

# Clone the dotfiles repository
git clone https://github.com/sebastianstupak/dotfiles.git

# Ensure ownership and permissions for the cloned repository
chown -R "$user_dir:$user_dir" "$target_dir/dotfiles"

# Make all .sh files in the dotfiles directory executable
find "$target_dir/dotfiles" -name "*.sh" -exec chmod +x {} \;

echo "Dotfiles downloaded and permissions set."
