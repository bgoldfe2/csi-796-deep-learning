S3_KEY_JUPYTER = 's3://YourPathTo/juypter_notebook_config.py'
S3_KEY_INSTALL = 's3://YourPathTo/certificate_and_s3fsfuse.sh'


SecurityGroup = t.add_resource(
    ec2.SecurityGroup(
        'simpleSg',
        GroupDescription='Simple Security Group: Enable SSH access via port 22',
        SecurityGroupIngress=[ec2.SecurityGroupRule(IpProtocol='tcp',
                                                    FromPort='22',
                                                    ToPort='22',
                                                    CidrIp='0.0.0.0/0')
                                        ]
    )
)

ec2_instance = t.add_resource(ec2.Instance(
    'Ec2Instance',
    ImageId = "ami-999844e0",
    InstanceType = 't2.micro', # for testing
    SecurityGroupIds = [GetAtt('simpleSg', 'GroupId')],
    Tags=[{"Key" : "Name", "Value" : "deep_learning_EC2"}],
    KeyName = 'YourPemKeyName',
    SubnetId = 'YourSubNetID', # e.g. ' eu-west-1a'
    IamInstanceProfile = Ref(instance_profile),
    UserData = Base64(
                     Join(
                         '',
                         ['#!/bin/bash -xe \n',
                          'cd /home/ec2-user \n',
                          'mkdir -p /mnt/jupyter-notebooks \n',
                          'chmod 777 /mnt/jupyter-notebooks \n',
                          'su ec2-user -c "aws s3 cp ', S3_KEY_JUPYTER_CONF, ' /home/ec2-user/.jupyter/jupyter_notebook_config.py" \n',
                          'su ec2-user -c "aws s3 cp ', S3_KEY_INSTALL, ' /home/ec2-user/certificate_and_s3fuse.sh" \n',
                          'sh /home/ec2-user/certificate_and_s3fuse.sh  \n',
                          'cd /mnt/jupyter-notebooks \n',
                          'su ec2-user -c "jupyter notebook" \n'
                          ])
               )
))
