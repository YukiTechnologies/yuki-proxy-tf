Yuki proxy terraform installation

Prerequisites:
1. aws cli installed `brew install awscli` check version (`aws --version`)
2. terraform installed `brew install terraform` check version (`terraform -v`)
3. make sure that there are less than 5 VPCs and Elastic IPs in your region.


Set the variables:

| Parameter                               |         Description          | Required |      Default       |
|:----------------------------------------|:----------------------------:|---------:|:------------------:|
| `aws.profile`                           |     AWS account profile      |      yes |        none        |
| `aws.region`                            |      AWS account region      |      yes |        none        |
| `proxy_environment_variables.PROXY_HOST`|     Your Snowflake host      |      yes |        none        |
| `container_image`                       |      Should be provided      |      yes |        none        |
| `dd_api_key`                            |      DataDog API key         |       no |        none        |


Installation:
1. run `terraform init`
2. run `terraform apply`

Deletion, in order to destroy the entire stack you should run:
1. `terraform destroy`
