Yuki proxy terraform installation

Prerequisites:
1. aws cli installed `brew install awscli` check version (`aws --version`)
2. terraform installed `brew install terraform` check version (`terraform -v`)
3. make sure that there are less than 5 VPCs and Elastic IPs in your region.


Set the variables:

| Parameter                             |         Description          | Required |      Default       |
|:--------------------------------------|:----------------------------:|---------:|:------------------:|
| `aws.profile`                         |     AWS account profile      |      Yes |        none        |
| `aws.region`                          |      AWS account region      |      Yes |        none        |
| `app.container.env.REDIS_HOST`        |          Redis host          |      yes |        none        |
| `app.container.env.PROXY_HOST`        |     Your Snowflake host      |      yes |        none        |
| `deployment.spec.tolerations.enabled` | Deployment toleration config |       no |       false        |
| `deployment.spec.affinity.enabled`    |  Deployment affinity config  |       no |       false        |
| `hpa.enabled`                         |      Service HPA config      |       no |        true        |


Installation:
1. run `terraform init`
2. run `terraform apply`

Deletion, in order to destroy the entire stack you should run:
1. `terraform destroy`
