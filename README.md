# Overview

A demonstration of simple cloud service orchestration and principles.

The goal is abject simplcity because the needed operations are pretty simple,
they just need to be repeatable. I've used Terraform and Ansible because they
require almost no setup on the orchestration machine and no tooling on the
provisioned machines.

## Prerequisites

On the control terminal you only need:
```bash
$ sudo apt install terraform
$ pip install ansible
```
You'll also need
 1. AWS API credentials
 2. an RSA public/private keypair
the use of which are described below.

## Terraform

Terraform requires AWS provisioning credentials and expects to find them in
`~/.aws/credentials`:
```
[terraform]
aws_access_key_id = <access>
aws_secret_access_key = <secret>
```
though you do not need `aws-cli` installed as Terraform contains its own AWS API
"provider". To execute the provisioning, simply:
``` bash
$ terraform init
$ terraform apply
```
The init action only needs to be done on the first terraform run. It pulls down
the providers needed to access aws. To see what actions would happen before
applying them, run `terraform plan`. By default, `apply` asks for confirmation
before provisioning. The apply action is idempotent: future runs will not
provision new resources. To see the current state of the managed resources run
`terraform show`.

The `sabot.tf` file has a `terraform` preamble that establishes an aws work
context. The `provider` block specifies an aws user profile and region.

The `data` block retrives the id of the latest Ubuntu AMI in the target region.
This is more convenient than hardcoding ami-ids per region.

Three AWS resources are created by the plan:
  1. an EC2 security group in the default VPC
  2. a named SSH keypair to allow access to the EC2
  3. one EC2 instance

The resource blocks should be readable to one who has used boto3 or aws-cli.

Finally, Terraform emits the public IP address of the created instance.

## Ansible

By virtue of Ansible performing its actions through ssh, there is no additional
software needed on the provisioned system. All you need is the private ssh key
corresponding to the public key installed via Terraform.

The `hosts.yml` file is delightfully rococo and should contain the ip address
output by Terraform.

Because there is no real project here yet, the `server.yml` playbook only
installs Python and demonstrates the retrival of a github repository. This
playbook is run with
```bash
$ ansible-playbook server.yml
```

If we decide to use the mechanism described here, not much more Ansible code is
needed to hoist up the server suite.
