# ASSUMES Ubuntu 17.10

# Install build-essential, Git, Tmux
sudo apt-get update
sudo apt-get install build-essential git tmux

# Install Python stuff
sudo apt-get update
sudo apt-get install python3-pip python3-dev python-virtualenv
sudo apt-get install python-pip python-dev python-virtualenv

# Tmux conf
cp .tmux.conf ~

# Git config
git config --global user.name "Sumit Gouthaman"
git config --global user.email "sumitgt007@gmail.com"

# Install VS Code
curl https://packages.microsoft.com/keys/microsoft.asc | gpg --dearmor > microsoft.gpg
sudo mv microsoft.gpg /etc/apt/trusted.gpg.d/microsoft.gpg
sudo sh -c 'echo "deb [arch=amd64] https://packages.microsoft.com/repos/vscode stable main" > /etc/apt/sources.list.d/vscode.list'
sudo apt-get update
sudo apt-get install code # or code-insiders

# Function to install CUDA
install_cuda () {
  echo "-- install_cuda --"
  sudo apt-get install linux-headers-$(uname -r)
  sudo touch /etc/modprobe.d/blacklist-nouveau.conf
  sudo bash -c 'cat > /etc/modprobe.d/blacklist-nouveau.conf <<EOF
blacklist nouveau
options nouveau modeset=0
EOF
'
  sudo update-initramfs -u
  wget 'https://developer.download.nvidia.com/compute/cuda/repos/ubuntu1604/x86_64/cuda-repo-ubuntu1604_8.0.61-1_amd64.deb'
  sudo dpkg -i cuda-repo-ubuntu1604_8.0.61-1_amd64.deb
  sudo apt-get update
  sudo apt-get install cuda=8.0.61-1 # Note specific version

  echo "Download the following from NVidia website after logging in"
  echo "https://developer.nvidia.com/compute/machine-learning/cudnn/secure/v6/prod/8.0_20170307/Ubuntu16_04_x64/libcudnn6_6.0.20-1+cuda8.0_amd64-deb"
  echo "https://developer.nvidia.com/compute/machine-learning/cudnn/secure/v6/prod/8.0_20170307/Ubuntu16_04_x64/libcudnn6-dev_6.0.20-1+cuda8.0_amd64-deb"

  echo "Press any key after you have downloaded the above 2 deb files."
  read input
  sudo dpkg -i libcudnn6_6.0.21-1+cuda8.0_amd64.deb
  sudo dpkg -i libcudnn6-dev_6.0.21-1+cuda8.0_amd64.deb

  sudo apt-get install libcupti-dev

  cat >> ~/.profile <<EOF
if [ -d "/usr/local/cuda-8.0/bin" ] ; then
    export LD_LIBRARY_PATH="/usr/local/cuda-8.0/bin"
fi
if [ -d "/usr/local/cuda-8.0" ] ; then
    export CUDA_HOME="/usr/local/cuda-8.0"
fi
EOF

  source ~/.profile

  echo "A restart is needed before using CUDA. Press any key to acknowledge."
  read input
}

mlpy2venv() {
  if [ -d "~/Projects" ] ; then
    mkdir ~/Projects
  fi
  virtualenv --system-site-packages ~/Projects/mlpy2venv
  source ~/Projects/mlpy2venv/bin/activate
  easy_install -U pip
  pip --no-cache-dir install \
    Pillow \
    h5py \
    ipykernel \
    jupyter \
    matplotlib \
    numpy \
    pandas \
    scipy \
    sklearn \
    && \
    python -m ipykernel.kernelspec
  pip install --upgrade tensorflow-gpu
  pip install --upgrade https://storage.googleapis.com/tensorflow/linux/cpu/protobuf-3.1.0-cp27-none-linux_x86_64.whl
  deactivate
}

# CUDA drivers
# Does the system have a NVIDIA GPU
CUDA_CAPABLE=0
if lspci | grep -i nvidia; then
  CUDA_CAPABLE=1
fi

if [ $CUDA_CAPABLE -ne 0 ]; then
  # Install CUDA
  install_cuda
  # Install tensorflow and ml packages in a virtual env
  mlpy2venv

  echo "Restart your computer now"
else
  echo "System is not CUDA capable. Will not install CUDA, CUDnn and TF-GPU."
fi