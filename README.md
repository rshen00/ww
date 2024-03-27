# High Avaialble Scalable and Resilient AWS Infrastructure
## Description
This is the playbook to deploy a high available scalable and resilient AWS infrastructure based of EC2 AMI’s by provisioned by terraform. This will be exposed to the public internet on port 443 with SSL enabled.
## Usage
```console
% export AWS_ACCESS_KEY_ID=<aws_access_key>
% export AWS_SECRET_ACCESS_KEY=<aws_secret_key>
% export TF_VAR_AWS_VPC_ID=vpc-0000000000000
% export TF_VAR_AWS_SUBNET_A=subnet-111111111111
% export TF_VAR_AWS_SUBNET_B=subnet-22222222222
% export TF_VAR_AWS_SUBNET_C=subnet-33333333333
% export TF_VAR_AWS_SUBNET_D=subnet-44444444444
% export TF_VAR_AWS_PUBLIC_SUBNET_A=subnet-55555555555
% export TF_VAR_AWS_PUBLIC_SUBNET_B=subnet-66666666666
% export TF_VAR_AWS_PUBLIC_SUBNET_C=subnet-77777777777
% export TF_VAR_AWS_PUBLIC_SUBNET_D=subnet-88888888888
% export TF_VAR_AWS_ACM_CERT_ARN=<aws_acm_cert_arn>
% export TF_VAR_AWS_AMI_ID=ami-11111111111111
% terraform init
% terraform plan 
% terraform apply
```
## High Level Architecture 
The key components of this design include the use of Auto Scaling Groups (ASG), Application Load Balancer for SSL termination, place EC2's in different availability zone/subnet of the vpc, and Security group combined with placing EC2'sin private subnet to make them secure. Further enhancements can be using Route 53 DNS service and multi-region deployment, but these are outside the current scope.
## Decisions on Desgin
### Auto Scaling Group (ASG)
The min_size, max_size, and desired_capacity in ASG are set based on the problem requirements. The scaling policy is picked based on the cpu utilization when it is above 50, though the requirements didn't specify any. Multiple availability zones is used to ensure high availability of EC2 instances.
Launch Template is chosen for the ASG. With in the Launch Template:
- EC2 Instance Type: t3a.xlarge, to meet the requirement of minimum of 3 CPU and minimum of 12GB. As there's no specifition of workload type, the general purpose instance is the best pick here. Since it is spcified with arch=amd64, Graviton processors can not be selected. AMD processor is selected to deliver even more cost savings.
- Block Device: EBS is selected for the easy-to-use, scalable and high-performance. As the requirement specifies > 250MB/s of throughput, gp3 needs to be selected as 250MB/s is the maxium throughput of gp2.
### Load Balancers
Though both Classic Load Balancer and Application Load Balancer can fulfill the requirement to termindate SSL on port 443 and forward to EC2 instance port 8192, Classic Load Balancer is the prior generation LB and for now is only recommended classic EC2, Application Load Balancer(ALB) is selected. Moreover, ALB is more flexible and has more features(e.g., host and path/quer routing, support of websocket, etc), which provides more headroom for the potential future work of the infrastructure. 
As there is no need for the static ip and extreme network performance for this use case, Network Load Balancer is not necessarily selected.
Also ALB is placed in mulitple public subnets to ensure the high availability
