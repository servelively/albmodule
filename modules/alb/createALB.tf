resource "aws_lb" "lb" {
  count = var.lb_create ? 1 : 0

  name        = var.lb_name
  name_prefix = var.lb_name_prefix
  load_balancer_type = var.lb_load_balancer_type
  internal           = var.lb_internal
  security_groups    = var.lb_security_groups
  subnets            = var.lb_subnets

  idle_timeout                     = var.lb_idle_timeout
  enable_cross_zone_load_balancing = var.lb_enable_cross_zone_load_balancing
  enable_deletion_protection       = var.lb_enable_deletion_protection
  enable_http2                     = var.lb_enable_http2
  ip_address_type                  = var.lb_ip_address_type
  drop_invalid_header_fields       = var.lb_drop_invalid_header_fields

  # See notes in README (ref: https://github.com/terraform-providers/terraform-provider-aws/issues/7987)
  dynamic "access_logs" {
    for_each = length(keys(var.lb_access_logs)) == 0 ? [] : [var.lb_access_logs]

    content {
      enabled = lookup(access_logs.value, "enabled", lookup(access_logs.value, "bucket", null) != null)
      bucket  = lookup(access_logs.value, "bucket", null)
      prefix  = lookup(access_logs.value, "prefix", null)
    }
  }

  dynamic "subnet_mapping" {
    for_each = var.lb_subnet_mapping

    content {
      subnet_id            = subnet_mapping.value.subnet_id
      allocation_id        = lookup(subnet_mapping.value, "allocation_id", null)
      private_ipv4_address = lookup(subnet_mapping.value, "private_ipv4_address", null)
      ipv6_address         = lookup(subnet_mapping.value, "ipv6_address", null)
    }
  }

  tags = merge(
    var.lb_lb_tags,
    var.lb_tags,
  )

  timeouts {
    create = var.lb_load_balancer_create_timeout
    update = var.lb_load_balancer_update_timeout
    delete = var.lb_load_balancer_delete_timeout
  }
}

resource "aws_lb_target_group" "main" {
  count = var.lb_create ? length(var.lb_target_groups) : 0

  name        = lookup(var.lb_target_groups[count.index], "name", null)

  vpc_id           = var.lb_vpc_id
  port             = lookup(var.lb_target_groups[count.index], "backend_port", null)
  protocol         = lookup(var.lb_target_groups[count.index], "backend_protocol", null) != null ? upper(lookup(var.lb_target_groups[count.index], "backend_protocol")) : null
  protocol_version = lookup(var.lb_target_groups[count.index], "protocol_version", null) != null ? upper(lookup(var.lb_target_groups[count.index], "protocol_version")) : null
  target_type      = lookup(var.lb_target_groups[count.index], "target_type", null)

  deregistration_delay               = lookup(var.lb_target_groups[count.index], "deregistration_delay", null)
  slow_start                         = lookup(var.lb_target_groups[count.index], "slow_start", null)
  proxy_protocol_v2                  = lookup(var.lb_target_groups[count.index], "proxy_protocol_v2", false)
  lambda_multi_value_headers_enabled = lookup(var.lb_target_groups[count.index], "lambda_multi_value_headers_enabled", false)
  load_balancing_algorithm_type      = lookup(var.lb_target_groups[count.index], "load_balancing_algorithm_type", null)

  dynamic "health_check" {
    for_each = length(keys(lookup(var.lb_target_groups[count.index], "health_check", {}))) == 0 ? [] : [lookup(var.lb_target_groups[count.index], "health_check", {})]

    content {
      enabled             = lookup(health_check.value, "enabled", null)
      interval            = lookup(health_check.value, "interval", null)
      path                = lookup(health_check.value, "path", null)
      port                = lookup(health_check.value, "port", null)
      healthy_threshold   = lookup(health_check.value, "healthy_threshold", null)
      unhealthy_threshold = lookup(health_check.value, "unhealthy_threshold", null)
      timeout             = lookup(health_check.value, "timeout", null)
      protocol            = lookup(health_check.value, "protocol", null)
      matcher             = lookup(health_check.value, "matcher", null)
    }
  }

  dynamic "stickiness" {
    for_each = length(keys(lookup(var.lb_target_groups[count.index], "stickiness", {}))) == 0 ? [] : [lookup(var.lb_target_groups[count.index], "stickiness", {})]

    content {
      enabled         = lookup(stickiness.value, "enabled", null)
      cookie_duration = lookup(stickiness.value, "cookie_duration", null)
      type            = lookup(stickiness.value, "type", null)
    }
  }

  tags = merge(
    var.lb_tags,
    var.lb_target_group_tags,
    lookup(var.lb_target_groups[count.index], "tags", {}),
    {
      "Name" = lookup(var.lb_target_groups[count.index], "name", lookup(var.lb_target_groups[count.index], "name_prefix", ""))
    },
  )

  depends_on = [aws_lb.lb]

  lifecycle {
    create_before_destroy = true
  }
}

locals {
  target_group_attachments = merge(flatten([
    for index, group in var.lb_target_groups : [
      for k, targets in group : {
        for target_key, target in targets : join(".", [index, target_key]) => merge({ tg_index = index }, target)
      }
      if k == "targets"
    ]
  ])...)
}

resource "aws_lb_target_group_attachment" "lb_asssign_tg" {
  for_each = var.lb_create && local.target_group_attachments != null ? local.target_group_attachments : {}

  target_group_arn  = aws_lb_target_group.main[each.value.tg_index].arn
  target_id         = each.value.target_id
  port              = lookup(each.value, "port", null)
  availability_zone = lookup(each.value, "availability_zone", null)
}

resource "aws_lb_listener_rule" "https_listener_rule" {
  count = var.lb_create ? length(var.lb_https_listener_rules) : 0

  listener_arn = aws_lb_listener.frontend_https[lookup(var.lb_https_listener_rules[count.index], "https_listener_index", count.index)].arn
  priority     = lookup(var.lb_https_listener_rules[count.index], "priority", null)

  # authenticate-cognito actions
  dynamic "action" {
    for_each = [
      for action_rule in var.lb_https_listener_rules[count.index].actions :
      action_rule
      if action_rule.type == "authenticate-cognito"
    ]

    content {
      type = action.value["type"]
      authenticate_cognito {
        authentication_request_extra_params = lookup(action.value, "authentication_request_extra_params", null)
        on_unauthenticated_request          = lookup(action.value, "on_authenticated_request", null)
        scope                               = lookup(action.value, "scope", null)
        session_cookie_name                 = lookup(action.value, "session_cookie_name", null)
        session_timeout                     = lookup(action.value, "session_timeout", null)
        user_pool_arn                       = action.value["user_pool_arn"]
        user_pool_client_id                 = action.value["user_pool_client_id"]
        user_pool_domain                    = action.value["user_pool_domain"]
      }
    }
  }

  # authenticate-oidc actions
  dynamic "action" {
    for_each = [
      for action_rule in var.lb_https_listener_rules[count.index].actions :
      action_rule
      if action_rule.type == "authenticate-oidc"
    ]

    content {
      type = action.value["type"]
      authenticate_oidc {
        # Max 10 extra params
        authentication_request_extra_params = lookup(action.value, "authentication_request_extra_params", null)
        authorization_endpoint              = action.value["authorization_endpoint"]
        client_id                           = action.value["client_id"]
        client_secret                       = action.value["client_secret"]
        issuer                              = action.value["issuer"]
        on_unauthenticated_request          = lookup(action.value, "on_unauthenticated_request", null)
        scope                               = lookup(action.value, "scope", null)
        session_cookie_name                 = lookup(action.value, "session_cookie_name", null)
        session_timeout                     = lookup(action.value, "session_timeout", null)
        token_endpoint                      = action.value["token_endpoint"]
        user_info_endpoint                  = action.value["user_info_endpoint"]
      }
    }
  }

  # redirect actions
  dynamic "action" {
    for_each = [
      for action_rule in var.lb_https_listener_rules[count.index].actions :
      action_rule
      if action_rule.type == "redirect"
    ]

    content {
      type = action.value["type"]
      redirect {
        host        = lookup(action.value, "host", null)
        path        = lookup(action.value, "path", null)
        port        = lookup(action.value, "port", null)
        protocol    = lookup(action.value, "protocol", null)
        query       = lookup(action.value, "query", null)
        status_code = action.value["status_code"]
      }
    }
  }

  # fixed-response actions
  dynamic "action" {
    for_each = [
      for action_rule in var.lb_https_listener_rules[count.index].actions :
      action_rule
      if action_rule.type == "fixed-response"
    ]

    content {
      type = action.value["type"]
      fixed_response {
        message_body = lookup(action.value, "message_body", null)
        status_code  = lookup(action.value, "status_code", null)
        content_type = action.value["content_type"]
      }
    }
  }

  # forward actions
  dynamic "action" {
    for_each = [
      for action_rule in var.lb_https_listener_rules[count.index].actions :
      action_rule
      if action_rule.type == "forward"
    ]

    content {
      type             = action.value["type"]
      target_group_arn = aws_lb_target_group.main[lookup(action.value, "target_group_index", count.index)].id
    }
  }

  # Path Pattern condition
  dynamic "condition" {
    for_each = [
      for condition_rule in var.lb_https_listener_rules[count.index].conditions :
      condition_rule
      if length(lookup(condition_rule, "path_patterns", [])) > 0
    ]

    content {
      path_pattern {
        values = condition.value["path_patterns"]
      }
    }
  }

  # Host header condition
  dynamic "condition" {
    for_each = [
      for condition_rule in var.lb_https_listener_rules[count.index].conditions :
      condition_rule
      if length(lookup(condition_rule, "host_headers", [])) > 0
    ]

    content {
      host_header {
        values = condition.value["host_headers"]
      }
    }
  }

  # Http header condition
  dynamic "condition" {
    for_each = [
      for condition_rule in var.lb_https_listener_rules[count.index].conditions :
      condition_rule
      if length(lookup(condition_rule, "http_headers", [])) > 0
    ]

    content {
      dynamic "http_header" {
        for_each = condition.value["http_headers"]

        content {
          http_header_name = http_header.value["http_header_name"]
          values           = http_header.value["values"]
        }
      }
    }
  }

  # Http request method condition
  dynamic "condition" {
    for_each = [
      for condition_rule in var.lb_https_listener_rules[count.index].conditions :
      condition_rule
      if length(lookup(condition_rule, "http_request_methods", [])) > 0
    ]

    content {
      http_request_method {
        values = condition.value["http_request_methods"]
      }
    }
  }

  # Query string condition
  dynamic "condition" {
    for_each = [
      for condition_rule in var.lb_https_listener_rules[count.index].conditions :
      condition_rule
      if length(lookup(condition_rule, "query_strings", [])) > 0
    ]

    content {
      dynamic "query_string" {
        for_each = condition.value["query_strings"]

        content {
          key   = lookup(query_string.value, "key", null)
          value = query_string.value["value"]
        }
      }
    }
  }

  # Source IP address condition
  dynamic "condition" {
    for_each = [
      for condition_rule in var.lb_https_listener_rules[count.index].conditions :
      condition_rule
      if length(lookup(condition_rule, "source_ips", [])) > 0
    ]

    content {
      source_ip {
        values = condition.value["source_ips"]
      }
    }
  }

  tags = merge(
    var.lb_tags,
    var.lb_https_listener_rules_tags,
    lookup(var.lb_https_listener_rules[count.index], "tags", {}),
  )
}

resource "aws_lb_listener" "frontend_http_tcp" {
  count = var.lb_create ? length(var.lb_http_tcp_listeners) : 0
  load_balancer_arn = aws_lb.lb[0].arn
  port     = var.lb_http_tcp_listeners[count.index]["port"]
  protocol = var.lb_http_tcp_listeners[count.index]["protocol"]

  dynamic "default_action" {
    for_each = length(keys(var.lb_http_tcp_listeners[count.index])) == 0 ? [] : [var.lb_http_tcp_listeners[count.index]]

    # Defaults to forward action if action_type not specified
    content {
      type             = lookup(default_action.value, "action_type", "forward")
      target_group_arn = contains([null, "", "forward"], lookup(default_action.value, "action_type", "")) ? aws_lb_target_group.main[lookup(default_action.value, "target_group_index", count.index)].id : null

      dynamic "redirect" {
        for_each = length(keys(lookup(default_action.value, "redirect", {}))) == 0 ? [] : [lookup(default_action.value, "redirect", {})]

        content {
          path        = lookup(redirect.value, "path", null)
          host        = lookup(redirect.value, "host", null)
          port        = lookup(redirect.value, "port", null)
          protocol    = lookup(redirect.value, "protocol", null)
          query       = lookup(redirect.value, "query", null)
          status_code = redirect.value["status_code"]
        }
      }

      dynamic "fixed_response" {
        for_each = length(keys(lookup(default_action.value, "fixed_response", {}))) == 0 ? [] : [lookup(default_action.value, "fixed_response", {})]

        content {
          content_type = fixed_response.value["content_type"]
          message_body = lookup(fixed_response.value, "message_body", null)
          status_code  = lookup(fixed_response.value, "status_code", null)
        }
      }
    }
  }

  tags = merge(
    var.lb_tags,
    var.lb_http_tcp_listeners_tags,
    lookup(var.lb_http_tcp_listeners[count.index], "tags", {}),
  )
}

resource "aws_lb_listener" "frontend_https" {
  count = var.lb_create ? length(var.lb_https_listeners) : 0
  load_balancer_arn = aws_lb.lb[0].arn

  port            = var.lb_https_listeners[count.index]["port"]
  protocol        = lookup(var.lb_https_listeners[count.index], "protocol", "HTTPS")
  certificate_arn = var.lb_https_listeners[count.index]["certificate_arn"]
  ssl_policy      = lookup(var.lb_https_listeners[count.index], "ssl_policy", var.lb_listener_ssl_policy_default)

  dynamic "default_action" {
    for_each = length(keys(var.lb_https_listeners[count.index])) == 0 ? [] : [var.lb_https_listeners[count.index]]

    # Defaults to forward action if action_type not specified
    content {
      type             = lookup(default_action.value, "action_type", "forward")
      target_group_arn = contains([null, "", "forward"], lookup(default_action.value, "action_type", "")) ? aws_lb_target_group.main[lookup(default_action.value, "target_group_index", count.index)].id : null

      dynamic "redirect" {
        for_each = length(keys(lookup(default_action.value, "redirect", {}))) == 0 ? [] : [lookup(default_action.value, "redirect", {})]

        content {
          path        = lookup(redirect.value, "path", null)
          host        = lookup(redirect.value, "host", null)
          port        = lookup(redirect.value, "port", null)
          protocol    = lookup(redirect.value, "protocol", null)
          query       = lookup(redirect.value, "query", null)
          status_code = redirect.value["status_code"]
        }
      }

      dynamic "fixed_response" {
        for_each = length(keys(lookup(default_action.value, "fixed_response", {}))) == 0 ? [] : [lookup(default_action.value, "fixed_response", {})]

        content {
          content_type = fixed_response.value["content_type"]
          message_body = lookup(fixed_response.value, "message_body", null)
          status_code  = lookup(fixed_response.value, "status_code", null)
        }
      }

      # Authentication actions only available with HTTPS listeners
      dynamic "authenticate_cognito" {
        for_each = length(keys(lookup(default_action.value, "authenticate_cognito", {}))) == 0 ? [] : [lookup(default_action.value, "authenticate_cognito", {})]

        content {
          # Max 10 extra params
          authentication_request_extra_params = lookup(authenticate_cognito.value, "authentication_request_extra_params", null)
          on_unauthenticated_request          = lookup(authenticate_cognito.value, "on_authenticated_request", null)
          scope                               = lookup(authenticate_cognito.value, "scope", null)
          session_cookie_name                 = lookup(authenticate_cognito.value, "session_cookie_name", null)
          session_timeout                     = lookup(authenticate_cognito.value, "session_timeout", null)
          user_pool_arn                       = authenticate_cognito.value["user_pool_arn"]
          user_pool_client_id                 = authenticate_cognito.value["user_pool_client_id"]
          user_pool_domain                    = authenticate_cognito.value["user_pool_domain"]
        }
      }

      dynamic "authenticate_oidc" {
        for_each = length(keys(lookup(default_action.value, "authenticate_oidc", {}))) == 0 ? [] : [lookup(default_action.value, "authenticate_oidc", {})]

        content {
          # Max 10 extra params
          authentication_request_extra_params = lookup(authenticate_oidc.value, "authentication_request_extra_params", null)
          authorization_endpoint              = authenticate_oidc.value["authorization_endpoint"]
          client_id                           = authenticate_oidc.value["client_id"]
          client_secret                       = authenticate_oidc.value["client_secret"]
          issuer                              = authenticate_oidc.value["issuer"]
          on_unauthenticated_request          = lookup(authenticate_oidc.value, "on_unauthenticated_request", null)
          scope                               = lookup(authenticate_oidc.value, "scope", null)
          session_cookie_name                 = lookup(authenticate_oidc.value, "session_cookie_name", null)
          session_timeout                     = lookup(authenticate_oidc.value, "session_timeout", null)
          token_endpoint                      = authenticate_oidc.value["token_endpoint"]
          user_info_endpoint                  = authenticate_oidc.value["user_info_endpoint"]
        }
      }
    }
  }

  dynamic "default_action" {
    for_each = contains(["authenticate-oidc", "authenticate-cognito"], lookup(var.lb_https_listeners[count.index], "action_type", {})) ? [var.lb_https_listeners[count.index]] : []
    content {
      type             = "forward"
      target_group_arn = aws_lb_target_group.main[lookup(default_action.value, "target_group_index", count.index)].id
    }
  }

  tags = merge(
    var.lb_tags,
    var.lb_https_listeners_tags,
    lookup(var.lb_https_listeners[count.index], "tags", {}),
  )
}

resource "aws_lb_listener_certificate" "https_listener" {
  count = var.lb_create ? length(var.lb_extra_ssl_certs) : 0
  listener_arn    = aws_lb_listener.frontend_https[var.lb_extra_ssl_certs[count.index]["https_listener_index"]].arn
  certificate_arn = var.lb_extra_ssl_certs[count.index]["certificate_arn"]
}