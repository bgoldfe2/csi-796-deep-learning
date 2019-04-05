# Converted from EC2InstanceSample.template located at:
# http://aws.amazon.com/cloudformation/aws-cloudformation-templates/

from troposphere import Base64, Join, FindInMap, GetAtt
from troposphere import Parameter, Output, Ref, Template, cloudformation
import troposphere.ec2 as ec2
import urllib.request

template = Template()

external_ip = urllib.request.urlopen('https://ident.me').read().decode('utf8') + "/32"


keyname_param = template.add_parameter(Parameter(
    "KeyName",
    Description="Name of an existing EC2 KeyPair to enable SSH "
                "access to the instance",
    Type="String",
))

ext_ip_param = template.add_parameter(Parameter(
        "ExternalIP",
        Type="String",
        Default=external_ip,
        Description="external ip of client",
    ))

SecurityGroup = template.add_resource(
    ec2.SecurityGroup(
        'simpleSg',
        GroupDescription='Simple Security Group: Enable SSH access via port 22',
        SecurityGroupIngress=[
            ec2.SecurityGroupRule(
                IpProtocol='tcp',
                FromPort='22',
                ToPort='22',
                CidrIp=Ref(ext_ip_param)),
            ec2.SecurityGroupRule(
                IpProtocol='tcp',
                FromPort='8888',
                ToPort='8888',
                CidrIp=Ref(ext_ip_param))
            ]
    )
)

template.add_mapping('RegionMap', {
    "us-east-1": {"AMI": "ami-060865e8b5914b4c4"},

})

ec2_instance = template.add_resource(ec2.Instance(
    "Ec2Instance",
    ImageId=FindInMap("RegionMap", Ref("AWS::Region"), "AMI"),
    InstanceType="p2.xlarge",
    KeyName=Ref(keyname_param),
    SecurityGroups=[Ref(SecurityGroup)],
    UserData=Base64(Join('', [
        'echo #!/bin/bash >>\n',
        'sudo -u ubuntu pwd && sudo -u ubuntu whoami\n',
        'echo ". /home/ubuntu/anaconda3/etc/profile.d/conda.sh" >> /home/ubuntu/.bashrc\n',
        'echo "conda activate" >> /home/ubuntu/.bashrc\n',
        'sudo -u ubuntu source /home/ubuntu/.bashrc\n',
        'conda activate tensorflow_p36\n',
        'mkdir ssl\n',
        'cd ssl\n',
        'openssl req -x509 -nodes -days 365 -newkey rsa:1024 -keyout "cert.key" -out "cert.pem" -batch\n',
        '#jupyter notebook --generate-config\n',
        'echo "about to append"\n',
        'ed -s /home/ubuntu/.jupyter/jupyter_notebook_config.py <<EOT\n',
        '1i\n',
        'c = get_config()\n',
        "c.NotebookApp.certfile = u'/home/ubuntu/ssl/cert.pem'\n",
        "c.NotebookApp.keyfile = u'/home/ubuntu/ssl/cert.key'\n",
        "c.IPKernelApp.pylab = 'inline'\n",
        "'c.NotebookApp.ip = '*'\n",
        'c.NotebookApp.open_browser = False\n',
        "c.NotebookApp.password = 'sha1:b592a9cf2ec6:b99edb2fd3d0727e336185a0b0eab561aa533a43'\n",
        '.\n',
        'w\n',
        'q\n',
        'EOT\n',
        'echo "after the append"\n',
        'sudo pip install keras --upgrade\n',
        'rm -f ~/.keras/keras.json\n'

    ])),
))

template.add_output([
    Output(
        "InstanceId",
        Description="InstanceId of the newly created EC2 instance",
        Value=Ref(ec2_instance),
    ),
    Output(
        "AZ",
        Description="Availability Zone of the newly created EC2 instance",
        Value=GetAtt(ec2_instance, "AvailabilityZone"),
    ),
    Output(
        "PublicIP",
        Description="Public IP address of the newly created EC2 instance",
        Value=GetAtt(ec2_instance, "PublicIp"),
    ),
    Output(
        "PrivateIP",
        Description="Private IP address of the newly created EC2 instance",
        Value=GetAtt(ec2_instance, "PrivateIp"),
    ),
    Output(
        "PublicDNS",
        Description="Public DNSName of the newly created EC2 instance",
        Value=GetAtt(ec2_instance, "PublicDnsName"),
    ),
    Output(
        "PrivateDNS",
        Description="Private DNSName of the newly created EC2 instance",
        Value=GetAtt(ec2_instance, "PrivateDnsName"),
    ),
])
outfile = template.to_yaml()
print(outfile)

f= open("0_createDeepLearningEC2.yaml","w+")
f.write(outfile)
f.close()
