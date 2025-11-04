# YOURLS host-based routing for cntently.com
resource "aws_lb_listener_rule" "yourls_https" {
  count        = local.create_certificate ? 1 : 0
  listener_arn = aws_lb_listener.https[0].arn
  priority     = 210

  condition {
    host_header { values = ["${var.root_domain}"] }
  }

  action {
    type             = "forward"
    target_group_arn = module.yourls.target_group_arn
  }
}

# HTTPS 404 for root cntently.com (forwards to /404)
resource "aws_lb_listener_rule" "root_https_404" {
  count        = local.create_certificate ? 1 : 0
  listener_arn = aws_lb_listener.https[0].arn
  priority     = 205

  condition {
    host_header { values = [var.root_domain] } # cntently.com
  }

  condition {
    path_pattern { values = ["/"] }
  }

  action {
    type = "redirect"
    redirect {
      host        = var.root_domain
      path        = "/404.php"
      port        = "443"
      protocol    = "HTTPS"
      status_code = "HTTP_301"
    }
  }
}


# HTTPS rule for app.cntently.com (UI)
resource "aws_lb_listener_rule" "yourls_https_app" {
  count        = local.create_certificate ? 1 : 0
  listener_arn = aws_lb_listener.https[0].arn
  priority     = 211

  condition {
    host_header { values = ["app.${var.root_domain}"] }
  }

  action {
    type             = "forward"
    target_group_arn = module.yourls.target_group_arn
  }
}

# HTTPS rule for api.cntently.com (API)
resource "aws_lb_listener_rule" "yourls_https_api" {
  count        = local.create_certificate ? 1 : 0
  listener_arn = aws_lb_listener.https[0].arn
  priority     = 212

  condition {
    host_header { values = ["api.${var.root_domain}"] }
  }

  action {
    type             = "forward"
    target_group_arn = module.yourls.target_group_arn
  }
}

# Only create HTTP forwarding rule when no certificate is enabled
resource "aws_lb_listener_rule" "yourls_http" {
  count        = local.create_certificate ? 0 : 1
  listener_arn = aws_lb_listener.http.arn
  priority     = 310

  condition {
    host_header { values = [var.root_domain] }
  }

  action {
    type             = "forward"
    target_group_arn = module.yourls.target_group_arn
  }
}

# HTTP rule for app.cntently.com (redirect or forward based on TLS setting)
resource "aws_lb_listener_rule" "yourls_http_app" {
  count        = local.create_certificate ? 0 : 1
  listener_arn = aws_lb_listener.http.arn
  priority     = 311

  condition {
    host_header { values = ["app.${var.root_domain}"] }
  }

  action {
    type             = "forward"
    target_group_arn = module.yourls.target_group_arn
  }
}

# HTTP rule for api.cntently.com (redirect or forward based on TLS setting)
resource "aws_lb_listener_rule" "yourls_http_api" {
  count        = local.create_certificate ? 0 : 1
  listener_arn = aws_lb_listener.http.arn
  priority     = 312

  condition {
    host_header { values = ["api.${var.root_domain}"] }
  }

  action {
    type             = "forward"
    target_group_arn = module.yourls.target_group_arn
  }
}

