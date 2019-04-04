#!/bin/bash


function main_py () {
    local -r install_dir=${1:-""}
    local -r env_filename="./sca_env.bash"

    cd "$install_dir" || return $?
    source "$env_filename" || return $?
    EC2_USER="ec2-user"
    PY_URL="ec2-54-91-197-254.compute-1.amazonaws.com"
    scp -i "$AWS_KEY_LOC" "$env_filename"    "${EC2_USER}@${PY_URL}:~" || return $?
    scp -i "$AWS_KEY_LOC" /home/a4dev/dev/MVP2/app.py    "${EC2_USER}@${PY_URL}:~" || return $?
    scp -r -i "$AWS_KEY_LOC" /home/a4dev/dev/MVP2/data/   "${EC2_USER}@${PY_URL}:~" || return $?
    scp -r -i "$AWS_KEY_LOC" /home/a4dev/dev/MVP2/analysis   "${EC2_USER}@${PY_URL}:~" || return $?

    ssh -i "$AWS_KEY_LOC" "${EC2_USER}@${PY_URL}" /bin/bash << EOF
        source "$env_filename"
        env | sort | grep -v PASSWORD
        sudo yum install -y wget bzip2
        echo "Downloading anaconda..."
        wget -q https://repo.anaconda.com/archive/Anaconda3-2018.12-Linux-x86_64.sh
        bash Anaconda3-2018.12-Linux-x86_64.sh -b
        echo "export PATH=\"/home/ec2-user/anaconda3/bin:\$PATH\"" >> "/home/ec2-user/.bashrc"
        source "/home/ec2-user/.bashrc"
        echo "PATH = '\$PATH'"
        conda -V
        python -V
        source activate
        conda create -y -n test368b python=3.6.8 psycopg2 scipy=1.1.0 pandas=0.23.4 nltk=3.3.0 scikit-learn=0.19.2 xlrd=1.1.0 xlsxwriter=1.1.0
        conda activate test368b
        python -m nltk.downloader stopwords punkt
        conda install -qy psycopg2
        python /home/ec2-user/app.py
EOF
}

main_py "$@"
