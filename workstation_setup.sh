# ASSUMES Ubuntu 16.04

# Conf to get Yubikey working
# https://www.yubico.com/support/knowledge-base/categories/articles/can-set-linux-system-use-u2f/
curl https://raw.githubusercontent.com/Yubico/libu2f-host/master/70-u2f.rules | sudo tee /etc/udev/rules.d/70-u2f.rules > /dev/null
sudo udevadm control --reload-rules

# Install Essentials
sudo apt-get update
sudo apt-get -y install build-essential git tmux xclip redshift-gtk

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
sudo apt-get -y install python3-pip python3-dev python-pip python-dev python-virtualenv

# Misc stuff related to data science
sudo apt-get -y install pandoc

# Install Go
wget https://dl.google.com/go/go1.10.3.linux-amd64.tar.gz
tar -C /usr/local -xzf go1.10.3.linux-amd64.tar.gz 
cat >> ~/.profile <<"EOF"
export PATH=$PATH:/usr/local/go/bin
EOF

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
sudo apt-get -y install code # or code-insiders

# Video editing
sudo add-apt-repository ppa:openshot.developers/ppa
sudo apt-get update
sudo apt-get -y install openshot-qt

# udev rules for phone for Android development
sudo touch /etc/udev/rules.d/51-android.rules
sudo bash -c 'cat > /etc/udev/rules.d/51-android.rules <<EOF
SUBSYSTEM=="usb", ATTR{idVendor}=="18d1", MODE="0666", GROUP="plugdev"
'

# Create an alias to restart network manager (helps fix silly wifi issues)
cat >> ~/.bashrc <<EOF

alias netfix='sudo service network-manager restart'
EOF

# Function to install CUDA
install_cuda () {
  echo "-- install_cuda --"
  sudo apt-get -y install linux-headers-$(uname -r)
  sudo touch /etc/modprobe.d/blacklist-nouveau.conf
  sudo bash -c 'cat > /etc/modprobe.d/blacklist-nouveau.conf <<EOF
blacklist nouveau
options nouveau modeset=0
EOF
'
  sudo update-initramfs -u
  wget 'https://developer.nvidia.com/compute/cuda/8.0/Prod2/local_installers/cuda-repo-ubuntu1604-8-0-local-ga2_8.0.61-1_amd64-deb'
  sudo dpkg -i cuda-repo-ubuntu1604-8-0-local-ga2_8.0.61-1_amd64-deb
  sudo apt-get update
  sudo apt-get -y install cuda # Note specific version
  wget 'https://developer.nvidia.com/compute/cuda/8.0/Prod2/patches/2/cuda-repo-ubuntu1604-8-0-local-cublas-performance-update_8.0.61-1_amd64-deb'
  sudo dpkg -i cuda-repo-ubuntu1604-8-0-local-cublas-performance-update_8.0.61-1_amd64-deb

  echo "Download the following from NVidia website after logging in"
  echo "https://developer.nvidia.com/rdp/cudnn-download":
  echo "1. cuDNN v6.0 Runtime Library for Ubuntu16.04 (Deb)"
  echo "2. cuDNN v6.0 Developer Library for Ubuntu16.04 (Deb)"

  echo "Press any key after you have downloaded the above 2 deb files."
  read input
  sudo dpkg -i libcudnn6_6.0.21-1+cuda8.0_amd64.deb
  sudo dpkg -i libcudnn6-dev_6.0.21-1+cuda8.0_amd64.deb

  sudo apt-get -y install libcupti-dev

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
  if [ -d "~/Venv" ] ; then
    mkdir ~/Venv
  fi
  virtualenv --system-site-packages ~/Venv/mlpy2venv
  source ~/Venv/mlpy2venv/bin/activate
  easy_install -U pip
  pip --no-cache-dir install \
    Pillow \
    h5py \
    ipykernel \
    jupyter \
    nbconvert \
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

  cat >> ~/.bashrc <<EOF

mlpy2 () {
  cd ~/Project
  source ~/Venv/mlpy2venv/bin/activate
}
EOF
}

mlpy3venv() {
  if [ -d "~/Venv" ] ; then
    mkdir ~/Venv
  fi
  virtualenv --system-site-packages -p python3 ~/Venv/mlpy3venv
  source ~/Venv/mlpy3venv/bin/activate
  easy_install -U pip
  pip3 --no-cache-dir install \
    Pillow \
    h5py \
    ipykernel \
    jupyter \
    nbconvert \
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

  cat >> ~/.bashrc <<EOF

mlpy3 () {
  cd ~/Project
  source ~/Venv/mlpy3venv/bin/activate
}
EOF
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