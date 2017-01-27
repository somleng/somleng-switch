# Deployment

## AWS Elastic Beanstalk

### Create a VPC

Follow [this guide](https://github.com/dwilkie/twilreapi/blob/master/docs/AWS_VPC_SETUP.md) to setup a VPC for your AWS account.

### Create a new Elastic Beanstalk Application

Create a Multi-Container Docker Elastic Beanstalk under your VPC. For security purposes this application will hosted on the private subnets so they cannot be accessed from the Internet.

When prompted for the VPC details enter the VPC id. When prompted for EC2 and ELB subnets enter your PRIVATE subnets. When asked if you want to associate a public IP address, choose No. When asked if you want the load balancer to be public, also choose No. The following commands are useful.

```
$ eb platform select --profile <profile-name>
$ eb create --vpc -i t2.micro -k <key-pair-name> --profile <profile-name>
```

### Update the Load Balancer Configuration

By default the load balancer will be configured to listen on port `80`. This needs to be updated to listen on port `9050` the default port which [Twilreapi](https://github.com/dwilkie/twilreapi) sends DRb requests to Somleng.

To update the load balancer

```
$ eb config
```

And change the configuration to look like the following:

```
  aws:elb:listener:80:
    ListenerEnabled: 'false'
  aws:elb:listener:9050:
    InstancePort: '9050'
    InstanceProtocol: TCP
    ListenerEnabled: 'true'
    ListenerProtocol: TCP
    PolicyNames: null
    SSLCertificateId: null
  aws:elb:loadbalancer:
    CrossZone: 'true'
    LoadBalancerHTTPPort: 'OFF'
    LoadBalancerHTTPSPort: 'OFF'
    LoadBalancerPortProtocol: HTTP
    LoadBalancerSSLPortProtocol: HTTPS
```

Note that you're adding another section for `aws:elb:listener:9050` and turning the listener `aws:elb:listener:80:` off. You're also turning the LoadBalancerHTTPPort 'OFF'

### Update the security group for the EC2 instances

By default the EC2 instance security group will be configured to only allow HTTP traffic on port `80`. This needs to be updated to port `9050` to allow traffic to the EC2 instance(s).

To update the ELB security group select it from the AWS EC2 Console and edit the inbound rule to allow traffic on TCP port `9050`.

### Update the security group for the ELB

By default the ELB security group will be configured to only allow inbound and outbound HTTP traffic on port `80`. This needs to be updated to port `9050` to allow inbound and outbound traffic to the ELB.

To update the ELB security group browse to the Load Balancer from the AWS EC2 Console the click the link to the ELB security group. Edit the inbound rule to allow traffic on TCP port `9050`. Edit the outbound rule to allow traffic on TCP port `9050`.

### Adhearsion Configuration

Follow [this guide](https://github.com/dwilkie/freeswitch-config/tree/master/docs/S3_CONFIGURATION.md) to securely store Adhearsion ENV Variables on S3.

Upload and download your configuration with the following commands

```
$ aws s3 cp somleng_config.txt s3://SECRETS_BUCKET_NAME/somleng_config.txt --sse
$ aws s3 cp s3://SECRETS_BUCKET_NAME/somleng_config.txt .
```
