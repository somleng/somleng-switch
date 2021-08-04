# Dynamic DNS (DDNS) Configuration

The following steps are adapted from [this article](https://aws.amazon.com/blogs/compute/building-a-dynamic-dns-for-route-53-using-cloudwatch-events-and-lambda/)

## Configure a Route 53 Private Hosted Zone

Using the AWS Web Console create a new Route 53 private hosted zone. This private hosted zone will only be used within your VPC so consider naming it something like `internal.your-domain.com.` to differentiate between the internal and external hosted zones. Also remember to include the trailing dot.

## Enable DNS hostnames on your VPC

Using the AWS Web Console [enable DNS hostnames on your VPC.](http://docs.aws.amazon.com/AmazonVPC/latest/UserGuide/vpc-dns.html#vpc-dns-updating)

## Download the source code for the lambda function

Download the lambda function source code from [Github](https://github.com/awslabs/aws-lambda-ddns-function). For more information about what the lambda function does, read [this article](https://aws.amazon.com/blogs/compute/building-a-dynamic-dns-for-route-53-using-cloudwatch-events-and-lambda/).

## Create an IAM policy for the lambda function

```
aws iam create-policy --policy-name ddns-lambda-policy --policy-document file:////path/to/ddns-pol.json --profile <profile-name>
```

## Create an IAM role for the lambda function

```
aws iam create-role --role-name ddns-lambda-role --assume-role-policy-document file:////path/to/ddns-trust.json --profile <profile-name>
```

## Attach the policy to the role

```
aws iam attach-role-policy --role-name ddns-lambda-role --policy-arn <enter-your-policy-arn-here> --profile <profile-name>
```

## Create the lambda function

Create a ZIP archive of the for the lambda function

```
zip union.zip union.py
```

Create the lambda function on AWS

```
aws lambda create-function --function-name ddns_lambda --runtime python2.7 --role <enter-your-role-arn-here> --handler union.lambda_handler --timeout 300 --zip-file fileb:////path/to/union.zip --profile <profile-name> --region <region-name>
```

## Create the CloudWatch events rule

```
aws events put-rule --event-pattern "{\"source\":[\"aws.ec2\"],\"detail-type\":[\"EC2 Instance State-change Notification\"],\"detail\":{\"state\":[\"running\",\"shutting-down\",\"stopped\"]}}" --state ENABLED --name ec2_lambda_ddns_rule --profile <profile-name> --region <region-name>
```

## Set the target of the rule to the lambda function

```
aws events put-targets --rule ec2_lambda_ddns_rule --targets Id=<enter-unique-id-here>,Arn=<enter-your-lambda-function-arn-here> --profile <profile-name> --region <region-name>
```

Note the `Id` parameter can be any unique id e.g. `id123456789012`

## Add permissions required for rule to execute the lambda function

```
aws lambda add-permission --function-name ddns_lambda --statement-id <enter-unique-id-here> --action lambda:InvokeFunction --principal events.amazonaws.com --source-arn <enter-your-cloudwatch-events-rule-arn-here> --profile <profile-name> --region <region-name>
```

Note that you need to provide a unique value for the `--statement-id` input parameter. E.g. `45`

## Validating Results

When a new instance is booted within your VPC the lambda function will check if the instance has the `ZONE` and `CNAME` tags and update your hosted zone with the correct records. You can view the logs of the lamda function the CloudWatch Web Console.
