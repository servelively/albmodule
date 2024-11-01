## Requirements

No requirements.

## Providers

| Name | Version |
|------|---------|
| <a name="provider_aws"></a> [aws](#provider\_aws) | n/a |

## Modules

No modules.

## Resources

| Name | Type |
|------|------|
| [aws_lb.lb](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/lb) | resource |
| [aws_lb_listener.frontend_http_tcp](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/lb_listener) | resource |
| [aws_lb_listener.frontend_https](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/lb_listener) | resource |
| [aws_lb_listener_certificate.https_listener](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/lb_listener_certificate) | resource |
| [aws_lb_listener_rule.https_listener_rule](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/lb_listener_rule) | resource |
| [aws_lb_target_group.main](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/lb_target_group) | resource |
| [aws_lb_target_group_attachment.lb_asssign_tg](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/lb_target_group_attachment) | resource |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_lb_access_logs"></a> [lb\_access\_logs](#input\_lb\_access\_logs) | Map containing access logging configuration for load balancer. | `map(string)` | `{}` | no |
| <a name="input_lb_create"></a> [lb\_create](#input\_lb\_create) | Controls if the Load Balancer should be created | `bool` | `true` | no |
| <a name="input_lb_drop_invalid_header_fields"></a> [lb\_drop\_invalid\_header\_fields](#input\_lb\_drop\_invalid\_header\_fields) | Indicates whether invalid header fields are dropped in application load balancers. Defaults to false. | `bool` | `false` | no |
| <a name="input_lb_enable_cross_zone_load_balancing"></a> [lb\_enable\_cross\_zone\_load\_balancing](#input\_lb\_enable\_cross\_zone\_load\_balancing) | Indicates whether cross zone load balancing should be enabled in application load balancers. | `bool` | `false` | no |
| <a name="input_lb_enable_deletion_protection"></a> [lb\_enable\_deletion\_protection](#input\_lb\_enable\_deletion\_protection) | If true, deletion of the load balancer will be disabled via the AWS API. This will prevent Terraform from deleting the load balancer. Defaults to false. | `bool` | `false` | no |
| <a name="input_lb_enable_http2"></a> [lb\_enable\_http2](#input\_lb\_enable\_http2) | Indicates whether HTTP/2 is enabled in application load balancers. | `bool` | `true` | no |
| <a name="input_lb_extra_ssl_certs"></a> [lb\_extra\_ssl\_certs](#input\_lb\_extra\_ssl\_certs) | A list of maps describing any extra SSL certificates to apply to the HTTPS listeners. Required key/values: certificate\_arn, https\_listener\_index (the index of the listener within https\_listeners which the cert applies toward). | `list(map(string))` | `[]` | no |
| <a name="input_lb_http_tcp_listeners"></a> [lb\_http\_tcp\_listeners](#input\_lb\_http\_tcp\_listeners) | A list of maps describing the HTTP listeners or TCP ports for this ALB. Required key/values: port, protocol. Optional key/values: target\_group\_index (defaults to http\_tcp\_listeners[count.index]) | `any` | `[]` | no |
| <a name="input_lb_http_tcp_listeners_tags"></a> [lb\_http\_tcp\_listeners\_tags](#input\_lb\_http\_tcp\_listeners\_tags) | A map of tags to add to all tcp listeners | `map(string)` | <pre>{<br/>  "Terraform": "True"<br/>}</pre> | no |
| <a name="input_lb_https_listener_rules"></a> [lb\_https\_listener\_rules](#input\_lb\_https\_listener\_rules) | A list of maps describing the Listener Rules for this ALB. Required key/values: actions, conditions. Optional key/values: priority, https\_listener\_index (default to https\_listeners[count.index]) | `any` | `[]` | no |
| <a name="input_lb_https_listener_rules_tags"></a> [lb\_https\_listener\_rules\_tags](#input\_lb\_https\_listener\_rules\_tags) | A map of tags to add to all https listener rules | `map(string)` | `{}` | no |
| <a name="input_lb_https_listeners"></a> [lb\_https\_listeners](#input\_lb\_https\_listeners) | A list of maps describing the HTTPS listeners for this ALB. Required key/values: port, certificate\_arn. Optional key/values: ssl\_policy (defaults to ELBSecurityPolicy-2016-08), target\_group\_index (defaults to https\_listeners[count.index]) | `any` | `[]` | no |
| <a name="input_lb_https_listeners_tags"></a> [lb\_https\_listeners\_tags](#input\_lb\_https\_listeners\_tags) | A map of tags to add to all https listeners | `map(string)` | <pre>{<br/>  "Terraform": "True"<br/>}</pre> | no |
| <a name="input_lb_idle_timeout"></a> [lb\_idle\_timeout](#input\_lb\_idle\_timeout) | The time in seconds that the connection is allowed to be idle. | `number` | `60` | no |
| <a name="input_lb_internal"></a> [lb\_internal](#input\_lb\_internal) | Boolean determining if the load balancer is internal or externally facing. | `bool` | `false` | no |
| <a name="input_lb_ip_address_type"></a> [lb\_ip\_address\_type](#input\_lb\_ip\_address\_type) | The type of IP addresses used by the subnets for your load balancer. The possible values are ipv4 and dualstack. | `string` | `"ipv4"` | no |
| <a name="input_lb_lb_tags"></a> [lb\_lb\_tags](#input\_lb\_lb\_tags) | A map of tags to add to load balancer | `map(string)` | `{}` | no |
| <a name="input_lb_listener_ssl_policy_default"></a> [lb\_listener\_ssl\_policy\_default](#input\_lb\_listener\_ssl\_policy\_default) | The security policy if using HTTPS externally on the load balancer. [See](https://docs.aws.amazon.com/elasticloadbalancing/latest/classic/elb-security-policy-table.html). | `string` | `"ELBSecurityPolicy-2016-08"` | no |
| <a name="input_lb_load_balancer_create_timeout"></a> [lb\_load\_balancer\_create\_timeout](#input\_lb\_load\_balancer\_create\_timeout) | Timeout value when creating the ALB. | `string` | `"20m"` | no |
| <a name="input_lb_load_balancer_delete_timeout"></a> [lb\_load\_balancer\_delete\_timeout](#input\_lb\_load\_balancer\_delete\_timeout) | Timeout value when deleting the ALB. | `string` | `"20m"` | no |
| <a name="input_lb_load_balancer_type"></a> [lb\_load\_balancer\_type](#input\_lb\_load\_balancer\_type) | The type of load balancer to create. Possible values are application or network. | `string` | `"application"` | no |
| <a name="input_lb_load_balancer_update_timeout"></a> [lb\_load\_balancer\_update\_timeout](#input\_lb\_load\_balancer\_update\_timeout) | Timeout value when updating the ALB. | `string` | `"20m"` | no |
| <a name="input_lb_name"></a> [lb\_name](#input\_lb\_name) | The resource name and Name tag of the load balancer. | `string` | `null` | no |
| <a name="input_lb_name_prefix"></a> [lb\_name\_prefix](#input\_lb\_name\_prefix) | The resource name prefix and Name tag of the load balancer. Cannot be longer than 6 characters | `string` | `null` | no |
| <a name="input_lb_security_groups"></a> [lb\_security\_groups](#input\_lb\_security\_groups) | The security groups to attach to the load balancer. e.g. ["sg-edcd9784","sg-edcd9785"] | `list(string)` | `[]` | no |
| <a name="input_lb_subnet_mapping"></a> [lb\_subnet\_mapping](#input\_lb\_subnet\_mapping) | A list of subnet mapping blocks describing subnets to attach to network load balancer | `list(map(string))` | `[]` | no |
| <a name="input_lb_subnets"></a> [lb\_subnets](#input\_lb\_subnets) | A list of subnets to associate with the load balancer. e.g. ['subnet-1a2b3c4d','subnet-1a2b3c4e','subnet-1a2b3c4f'] | `list(string)` | `null` | no |
| <a name="input_lb_tags"></a> [lb\_tags](#input\_lb\_tags) | A map of tags to add to all resources | `map(string)` | `{}` | no |
| <a name="input_lb_target_group_tags"></a> [lb\_target\_group\_tags](#input\_lb\_target\_group\_tags) | n/a | `map(string)` | <pre>{<br/>  "Terrafrom": "true"<br/>}</pre> | no |
| <a name="input_lb_target_groups"></a> [lb\_target\_groups](#input\_lb\_target\_groups) | A list of maps containing key/value pairs that define the target groups to be created. Order of these maps is important and the index of these are to be referenced in listener definitions. Required key/values: name, backend\_protocol, backend\_port | `any` | `[]` | no |
| <a name="input_lb_vpc_id"></a> [lb\_vpc\_id](#input\_lb\_vpc\_id) | VPC id where the load balancer and other resources will be deployed. | `string` | `null` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_lb_arn"></a> [lb\_arn](#output\_lb\_arn) | The ID and ARN of the load balancer we created. |
| <a name="output_lb_arn_suffix"></a> [lb\_arn\_suffix](#output\_lb\_arn\_suffix) | ARN suffix of our load balancer - can be used with CloudWatch. |
| <a name="output_lb_dns_name"></a> [lb\_dns\_name](#output\_lb\_dns\_name) | The DNS name of the load balancer. |
| <a name="output_lb_http_tcp_listener_arns"></a> [lb\_http\_tcp\_listener\_arns](#output\_lb\_http\_tcp\_listener\_arns) | The ARN of the TCP and HTTP load balancer listeners created. |
| <a name="output_lb_http_tcp_listener_ids"></a> [lb\_http\_tcp\_listener\_ids](#output\_lb\_http\_tcp\_listener\_ids) | The IDs of the TCP and HTTP load balancer listeners created. |
| <a name="output_lb_https_listener_arns"></a> [lb\_https\_listener\_arns](#output\_lb\_https\_listener\_arns) | The ARNs of the HTTPS load balancer listeners created. |
| <a name="output_lb_https_listener_ids"></a> [lb\_https\_listener\_ids](#output\_lb\_https\_listener\_ids) | The IDs of the load balancer listeners created. |
| <a name="output_lb_id"></a> [lb\_id](#output\_lb\_id) | The ID and ARN of the load balancer we created. |
| <a name="output_lb_target_group_arn_suffixes"></a> [lb\_target\_group\_arn\_suffixes](#output\_lb\_target\_group\_arn\_suffixes) | ARN suffixes of our target groups - can be used with CloudWatch. |
| <a name="output_lb_target_group_arns"></a> [lb\_target\_group\_arns](#output\_lb\_target\_group\_arns) | ARNs of the target groups. Useful for passing to your Auto Scaling group. |
| <a name="output_lb_target_group_attachments"></a> [lb\_target\_group\_attachments](#output\_lb\_target\_group\_attachments) | ARNs of the target group attachment IDs. |
| <a name="output_lb_target_group_names"></a> [lb\_target\_group\_names](#output\_lb\_target\_group\_names) | Name of the target group. Useful for passing to your CodeDeploy Deployment Group. |
| <a name="output_lb_zone_id"></a> [lb\_zone\_id](#output\_lb\_zone\_id) | The zone\_id of the load balancer to assist with creating DNS records. |
