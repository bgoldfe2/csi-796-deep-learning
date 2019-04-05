echo ". /home/ubuntu/anaconda3/etc/profile.d/conda.sh" >> ~/.bashrc
echo "conda activate" >> ~/.bashrc
source ~/.bashrc
jupyter notebook --generate-config


c = get_config()
c.NotebookApp.certfile = u'/home/ubuntu/ssl/cert.pem'
c.NotebookApp.keyfile = u'/home/ubuntu/ssl/cert.key'
c.IPKernelApp.pylab = 'inline'
c.NotebookApp.ip = '*'

c.NotebookApp.open_browser = False
c.NotebookApp.password = 'sha1:b592a9cf2ec6:b99edb2fd3d0727e336185a0b0eab561aa533a43'

printf '%s\n%s\n' "$(cat B.txt)" "$(cat A.txt)" > /tmp/C.txt && mv /tmp/C.txt ./A.txt
