
# Prerequisites
This module is dependent on a few things:

- IAM creds/role used in the `var.AWS_*` vars to build the resources.

# Notes
- The test instance for macOS is using physical infra on EC2 which comes with a little more limitations than VM instances. See the [AWS developer documenation](https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/ec2-mac-instances.html#mac-instance-considerations) for noted differences between standard EC2 instances.
