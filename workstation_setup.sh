# ASSUMES Ubuntu 16.04

# Conf to get Yubikey working
# https://www.yubico.com/support/knowledge-base/categories/articles/can-set-linux-system-use-u2f/
curl https://raw.githubusercontent.com/Yubico/libu2f-host/master/70-u2f.rules | sudo tee /etc/udev/rules.d/70-u2f.rules > /dev/null
# REBOOT

# Install Essentials
sudo apt-get update
sudo apt-get install build-essential git tmux xclip

# Create SSH key
ssh-keygen -t rsa -b 4096 -C "sumitgt007@gmail.com"
ssh-add ~/.ssh/id_rsa
xclip -sel clip < ~/.ssh/id_rsa.pub
# Add to github
echo "SSH public key copied to clipboard. Add it to your github account now."
echo "Press any key to continue."
read any_key

# Create GPG key
echo "NOTE: Choose (RSA and RSA), length 4096"
gpg --gen-key
gpg_key_id=$(gpg --list-secret-keys --keyid-format LONG | sed -n -e 's/^sec .*4096R\///p' | sed -n -e 's/\s.*//p')
gpg --armor --export $gpg_key_id | xclip -sel clip
# Add to github
echo "GPG public key copied to clipboard. Add it to your github account now."
echo "Press any key to continue."
read any_key
# Configure git for key signing
git config --global commit.gpgsign true
git config --global user.signingkey $gpg_key_id


# Install Python stuff
sudo apt-get update
sudo apt-get install python3-pip python3-dev python-pip python-dev python-virtualenv

# Tmux conf
cat > ~/.tmux.conf <<EOF
set -g mouse on
EOF

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
    keras \
    tqdm \
    && \
    python -m ipykernel.kernelspec
  pip install --upgrade tensorflow-gpu
  pip install --upgrade https://storage.googleapis.com/tensorflow/linux/cpu/protobuf-3.1.0-cp27-none-linux_x86_64.whl
  deactivate
}

mlpy3venv() {
  if [ -d "~/Projects" ] ; then
    mkdir ~/Projects
  fi
  virtualenv --system-site-packages -p python3 ~/Projects/mlpy3venv
  source ~/Projects/mlpy3venv/bin/activate
  easy_install -U pip
  pip3 --no-cache-dir install \
    Pillow \
    h5py \
    ipykernel \
    jupyter \
    matplotlib \
    numpy \
    pandas \
    scipy \
    sklearn \
    keras \
    tqdm \
    && \
    python -m ipykernel.kernelspec
  pip3 install --upgrade tensorflow-gpu
  # pip3 install --upgrade https://storage.googleapis.com/tensorflow/linux/cpu/protobuf-3.1.0-cp35-none-linux_x86_64.whl
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
  # Install tensorflow and ml packages in a virtual env (python 3)
  mlpy3venv

  echo "Restart your computer now"
else
  echo "System is not CUDA capable. Will not install CUDA, CUDnn and TF-GPU."
fi