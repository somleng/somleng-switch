# S3 Configuration

Adapted from [this blog post](https://blogs.aws.amazon.com/security/post/Tx2B3QUWAA7KOU/How-to-Manage-Secrets-for-Amazon-EC2-Container-Service-Based-Applications-by-Usi)

Sensitive configuration can be stored on S3. When the docker container runs the `docker-entrypoint.sh` it downloads the configuration before starting the docker container.

In order for this to work you need to set up an S3 bucket in your AWS account in which to store the configuration and restrict the access to the VPC.

First, create a bucket in S3 using the AWS web console in which to store your configuration.

Next, create a VPC Endpoint to S3. Use the following command following command replacing `<your-aws-profile>` with your configured profile in `~/.aws/credentials`, `VPC_ID` and `ROUTE_TABLE_ID` with the values found in your VPC configuration via the AWS web console and `REGION` with the name of your region e.g. `ap-southeast-1`

```
$ aws ec2 --profile <your-aws-profile> create-vpc-endpoint --vpc-id VPC_ID --route-table-ids ROUTE_TABLE_ID --service-name com.amazonaws.REGION.s3 --region REGION
```

You should see the output similar to the following:

```json
{
  "VpcEndpoint": {
  "PolicyDocument": "{\"Version\":\"2008-10-17\",\"Statement\":[{\"Sid\":\"\",\"Effect\":\"Allow\",\"Principal\":\"*\",\"Action\":
\"*\",\"Resource\":\"*\"}]}",
  "VpcId": "vpc-1a2b3c4d",
  "State": "available",
  "ServiceName": "com.amazonaws.us-east-1.s3",
  "RouteTableIds": [
    "rtb-11aa22bb"
  ],
  "VpcEndpointId": "vpce-3ecf2a57",
  "CreationTimestamp": "2016-05-15T09:40:50Z"
  }
}
```

Take note of the `VpcEndpointId` which is required for the next step.

Note you need to add both route tables to the VpcEndpoint. That is the route table for the public subnets and the route table for the private subnets.

To update the VpcEndpoint with the other route table, use the following command:

```
$ aws ec2 --profile <your-aws-profile> modify-vpc-endpoint --vpc-endpoint-id VPC_ENDPOINT_ID --add-route-table-ids ROUTE_TABLE_ID --region REGION
```

You can check that your VpcEndpoint is correct in the AWS VPC Console under Endpoints or use the following command:

```
$ aws ec2 --profile <your-aws-profile> describe-vpc-endpoints --vpc-endpoint-ids VPC_ENDPOINT_ID --region REGION
```

Next, create a file called `policy.json` with the following contents replacing `SECRETS_BUCKET_NAME` with your the name of your new bucket and `VPC_ID` with the `VpcEndpointId` from the previous step.

This policy prevents unencrypted uploads and restricts access to the bucket to the VPC.

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "DenyUnEncryptedObjectUploads",
      "Effect": "Deny",
      "Principal": "*",
      "Action": "s3:PutObject",
      "Resource": "arn:aws:s3:::SECRETS_BUCKET_NAME/*",
      "Condition": {
        "StringNotEquals": {
          "s3:x-amz-server-side-encryption": "AES256"
        }
      }
    },
    {
      "Sid": " DenyUnEncryptedInflightOperations",
      "Effect": "Deny",
      "Principal": "*",
      "Action": "s3:*",
      "Resource": "arn:aws:s3:::SECRETS_BUCKET_NAME/*",
      "Condition": {
        "Bool": {
          "aws:SecureTransport": false
        }
      }
    },
    {
      "Sid": "Access-to-specific-VPCE-only",
      "Effect": "Deny",
      "Principal": "*",
      "Action": [ "s3:GetObject", "s3:PutObject", "s3:DeleteObject" ],
      "Resource": "arn:aws:s3:::SECRETS_BUCKET_NAME/*",
      "Condition": {
        "StringNotEquals": {
          "aws:sourceVpce": "VPCE_ID"
        }
      }
    }
  ]
}
```

Next, add the policy to the bucket. Use the following command replacing `SECRETS_BUCKET_NAME` with the name of your bucket.

```
$ aws s3api put-bucket-policy --profile <your-aws-profile> --bucket SECRETS_BUCKET_NAME --policy file:////home/user/path/to/policy.json
```

You can check that your policy was uploaded successfully with the following command.

```
$ aws s3api get-bucket-policy --profile <your-aws-profile> --bucket SECRETS_BUCKET_NAME
```

Next, allow your Elastic Beanstalk Instances to access S3. Using the AWS web console, navigate to IAM roles and add a policy to the role `aws-elasticbeanstalk-ec2-role` to allow Amazon S3 Full Access.

Finally, upload your sensitive configuration to S3 from your EC2 Instance. Note you cannot do this from your development machine because we have already resticted access to the VPC.

```
$ aws s3 cp --recursive freeswitch_conf_dir s3://SECRETS_BUCKET_NAME/FREESWITCH_CONF_DIR --sse
```

When updating configuration, download your custom configuration from S3, update it, reupload it to S3 and re-deploy the application. The following commands are useful:

```
$ aws s3 cp --recursive s3://SECRETS_BUCKET_NAME/freeswitch/conf freeswitch_conf
$ aws s3 cp --recursive freeswitch_conf s3://SECRETS_BUCKET_NAME/freeswitch/conf --sse
```

