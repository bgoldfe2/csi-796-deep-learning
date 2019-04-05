from troposphere import ec2, Ref, Template, iam, Parameter, Base64, Join, FindInMap, Output, GetAtt
import boto3
from awacs import s3
from awacs.aws import Statement, Allow, Action, Policy, Principal
from awacs.sts import AssumeRole

# create template
STACK_NAME = 'MyDeepLearningEC2Stack'
t = Template()

# policy document to read from and write to S3
s3_doc = Policy(
    Statement=[
        Statement(
            Sid='WriteS3',
            Effect=Allow,
            Action=[s3.DeleteObject,
                    s3.PutObject,
                    s3.GetBucketPolicy,
                    s3.ListMultipartUploadParts,
                    s3.AbortMultipartUpload,
                    ],
            Resource=['arn:aws:s3:::YourBucketFolderForNotebooks/*']
        ),
        Statement(
            Sid='ReadS3',
            Effect=Allow,
            Action=[Action('s3', 'List*'),
                    Action('s3', 'Get*')
                    ],
            Resource=['arn:aws:s3:::*']
        )
    ]
)

# create policy from policy document
s3_access_policy = iam.Policy(
    's3AccessPolicy',
    PolicyName= 's3AccessPolicy',
    PolicyDocument=s3_doc
)

# create iam role with trust policy
# add s3 policy
s3_access_role = t.add_resource(iam.Role(
    "S3AccessRole",
    AssumeRolePolicyDocument=Policy(
        Statement=[
            Statement(
                Effect=Allow,
                Action=[AssumeRole],
                Principal=Principal("Service", ["ec2.amazonaws.com"])
            )
        ]
    ),
    Policies=[s3_access_policy]
))

# create instance profile
instance_profile = t.add_resource(iam.InstanceProfile("InstanceProfile", Roles=[Ref(s3_access_role)]))
