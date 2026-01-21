terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}
# ----------------------------------------------------------------------------------------------------------------------
# IP Sets
# ----------------------------------------------------------------------------------------------------------------------
resource "aws_wafv2_ip_set" "Allow_IPSets_Rule" {
  name               = "ons_allow_ipset1"
  description        = "Allowed IPs"
  scope              = var.waf_scope
  ip_address_version = "IPV4"
  addresses          = []
}

resource "aws_wafv2_ip_set" "Block_IPSets_Rule" {
  name               = "ons_block_ipset1"
  description        = "Blocked IPs"
  scope              = var.waf_scope
  ip_address_version = "IPV4"
  addresses          = []
}

resource "aws_wafv2_ip_set" "host_allow_ips" {
  name               = "ons_host_allow_ipset1"
  description        = "Host IP Allowlist"
  scope              = var.waf_scope
  ip_address_version = "IPV4"
  addresses          = ["203.248.117.82/32", "203.248.117.83/32", "203.248.117.37/32"]
}
# ----------------------------------------------------------------------------------------------------------------------
# Regex Pattern Sets
# ----------------------------------------------------------------------------------------------------------------------
resource "aws_wafv2_regex_pattern_set" "ons_regex_ip_deny" {
  name        = "ons_regex_ip_deny1"
  description = "IP Deny Pattern"
  scope       = var.waf_scope

  regular_expression {
    regex_string = "^((25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\\.){3}(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)$"
  }
}

resource "aws_wafv2_regex_pattern_set" "ons_regex_user_agent" {
  name        = "ons_regex_user_agent1"
  description = "Blocked User Agents"
  scope       = var.waf_scope

  regular_expression {
    regex_string = ".*acunetix.*|.*nikto.*|.*nmap.*|.*nuclei.*|.*openvaS.*|.*sqlmap.*|.*wpscan.*|.*zmeu.*|.*zgrab.*"
  }
}

resource "aws_wafv2_regex_pattern_set" "ons_regex_uri_path" {
  name        = "ons_regex_uri_path1"
  description = "Blocked URI Paths"
  scope       = var.waf_scope

  regular_expression {
    regex_string = ".*\\.env.*"
  }
  regular_expression {
    regex_string = ".*\\/boaform\\/admin\\/formLogin.*"
  }
  regular_expression {
    regex_string = ".*\\/etc\\/hosts.*|.*\\/etc\\/passwd.*|.*\\/windows\\/win\\.ini.*"
  }
  regular_expression {
    regex_string = ".*\\/xmlrpc\\.php.*|.*phpmyadmin.*|.*phpunit.*"
  }
}

# ----------------------------------------------------------------------------------------------------------------------
# Rule Group
# ----------------------------------------------------------------------------------------------------------------------
resource "aws_wafv2_rule_group" "ONS_custom_rule_group" {
  name        = "ONS-WAF-Custom-RuleGroup1"
  description = "Custom WAF RuleGroup for ONS"
  scope       = var.waf_scope
  capacity    = 150

  visibility_config {
    cloudwatch_metrics_enabled = true
    metric_name                = "ONS-WAF-Custom-RuleGroup"
    sampled_requests_enabled   = true
  }

  rule {
    name     = "ONS-WAF-Host-IP-Allow1"
    priority = 0
    action {
      block {}
    }
    statement {
      not_statement {
        statement {
          ip_set_reference_statement {
            arn = aws_wafv2_ip_set.host_allow_ips.arn
          }
        }
      }
    }
    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "ONS-WAF-Host-IP-Allow1"
      sampled_requests_enabled    = true
    }
  }

  rule {
    name     = "ONS-URIpath"
    priority = 1

    statement {
      regex_pattern_set_reference_statement {
        arn = aws_wafv2_regex_pattern_set.ons_regex_uri_path.arn
        field_to_match {
          uri_path {}
        }
        text_transformation {
          priority = 0
          type     = "NONE"
        }
      }
    }

    action {
      block {}
    }

    visibility_config {
      sampled_requests_enabled   = true
      cloudwatch_metrics_enabled = true
      metric_name                = "ONS-URIpath"
    }
  }

  rule {
    name     = "ONS-UserAgent"
    priority = 2

    statement {
      regex_pattern_set_reference_statement {
        arn = aws_wafv2_regex_pattern_set.ons_regex_user_agent.arn
        field_to_match {
          single_header {
            name = "user-agent"
          }
        }
        text_transformation {
          priority = 0
          type     = "NONE"
        }
      }
    }

    action {
      block {}
    }

    visibility_config {
      sampled_requests_enabled   = true
      cloudwatch_metrics_enabled = true
      metric_name                = "ONS-UserAgent"
    }
  }

  rule {
    name     = "ONS-IPPatternDeny"
    priority = 3

    statement {
      regex_pattern_set_reference_statement {
        arn = aws_wafv2_regex_pattern_set.ons_regex_ip_deny.arn
        field_to_match {
          single_header {
            name = "host"
          }
        }
        text_transformation {
          priority = 0
          type     = "NONE"
        }
      }
    }

    action {
      count {}
    }

    visibility_config {
      sampled_requests_enabled   = true
      cloudwatch_metrics_enabled = true
      metric_name                = "ONS-IPPatternDeny"
    }
  }
}

# ----------------------------------------------------------------------------------------------------------------------
# Web ACL
# ----------------------------------------------------------------------------------------------------------------------
resource "aws_wafv2_web_acl" "WafWebAcl" {
  name        = var.waf_name
  scope       = var.waf_scope
  description = "WAF for ${var.waf_name}"
  default_action {
    allow {}
  }
  visibility_config {
    cloudwatch_metrics_enabled = true
    metric_name                = var.waf_name
    sampled_requests_enabled    = true
  }

  # Allowed IPs Rule
  rule {
    name     = "ONS-Allow_IPSets_Rule"
    priority = 0
    action {
      allow {}
    }
    statement {
      ip_set_reference_statement {
        arn = aws_wafv2_ip_set.Allow_IPSets_Rule.arn
      }
    }
    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "ONS-Allow_IPSets_Rule"
      sampled_requests_enabled    = true
    }
  }

  # Blocked IPs Rule
  rule {
    name     = "ONS-Block_IPSets_Rule"
    priority = 1
    action {
      block {}
    }
    statement {
      ip_set_reference_statement {
        arn = aws_wafv2_ip_set.Block_IPSets_Rule.arn
      }
    }
    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "ONS-Block_IPSets_Rule"
      sampled_requests_enabled    = true
    }
  }

  # Custom RuleGroup 
  rule {
    name     = "ONS-WAF-Custom-RuleGroup"
    priority = 2
    override_action {
      none {}
    }
    statement {
      rule_group_reference_statement  {
        arn = aws_wafv2_rule_group.ONS_custom_rule_group.arn
      }
    }
    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "ONS-WAF-Custom-RuleGroup"
      sampled_requests_enabled    = true
    }
  }

  # Common Rule Set
  rule {
    name     = "AWS-AWSManagedRulesCommonRuleSet"
    priority = 3
    override_action {
      none {}
    }
    statement {
      managed_rule_group_statement {
        name        = "AWSManagedRulesCommonRuleSet"
        vendor_name = "AWS"
        version = "Version_1.17"

        rule_action_override {
          action_to_use {
            count {}
          }
          name = "NoUserAgent_HEADER"
        }
        rule_action_override {
          action_to_use {
            block {}
          }
          name = "UserAgent_BadBots_HEADER"
        }
        rule_action_override {
          action_to_use {
            block {}
          }
          name = "SizeRestrictions_QUERYSTRING"
        }
        rule_action_override {
          action_to_use {
            block {}
          }
          name = "SizeRestrictions_Cookie_HEADER"
        }
        rule_action_override {
          action_to_use {
            count {}
          }
          name = "SizeRestrictions_BODY"
        }
        rule_action_override {
          action_to_use {
            count {}
          }
          name = "SizeRestrictions_URIPATH"
        }
        rule_action_override {
          action_to_use {
            block {}
          }
          name = "EC2MetaDataSSRF_BODY"
        }
        rule_action_override {
          action_to_use {
            block {}
          }
          name = "EC2MetaDataSSRF_COOKIE"
        }
        rule_action_override {
          action_to_use {
            block {}
          }
          name = "EC2MetaDataSSRF_URIPATH"
        }
        rule_action_override {
          action_to_use {
            block {}
          }
          name = "EC2MetaDataSSRF_QUERYARGUMENTS"
        }
        rule_action_override {
          action_to_use {
            block {}
          }
          name = "GenericLFI_QUERYARGUMENTS"
        }
        rule_action_override {
          action_to_use {
            block {}
          }
          name = "GenericLFI_URIPATH"
        }
        rule_action_override {
          action_to_use {
            block {}
          }
          name = "GenericLFI_BODY"
        }
        rule_action_override {
          action_to_use {
            block {}
          }
          name = "RestrictedExtensions_URIPATH"
        }
        rule_action_override {
          action_to_use {
            block {}
          }
          name = "RestrictedExtensions_QUERYARGUMENTS"
        }
        rule_action_override {
          action_to_use {
            block {}
          }
          name = "GenericRFI_QUERYARGUMENTS"
        }
        rule_action_override {
          action_to_use {
            block {}
          }
          name = "GenericRFI_BODY"
        }
        rule_action_override {
          action_to_use {
            block {}
          }
          name = "GenericRFI_URIPATH"
        }
        rule_action_override {
          action_to_use {
            block {}
          }
          name = "CrossSiteScripting_COOKIE"
        }
        rule_action_override {
          action_to_use {
            count {}
          }
          name = "CrossSiteScripting_QUERYARGUMENTS"
        }
        rule_action_override {
          action_to_use {
            count {}
          }
          name = "CrossSiteScripting_BODY"
        }
        rule_action_override {
          action_to_use {
            block {}
          }
          name = "CrossSiteScripting_URIPATH"
        }
      }
    }
    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "AWS-AWSManagedRulesCommonRuleSet"
      sampled_requests_enabled    = true
    }
  }

  # Known Bad Inputs Rule Set
  rule {
    name     = "AWS-AWSManagedRulesKnownBadInputsRuleSet"
    priority = 4
    override_action {
      none {}
    }
    statement {
      managed_rule_group_statement {
        name        = "AWSManagedRulesKnownBadInputsRuleSet"
        vendor_name = "AWS"
        version = "Version_1.24"

        rule_action_override {
          action_to_use {
            block {}
          }
          name = "JavaDeserializationRCE_BODY"
        }
        rule_action_override {
          action_to_use {
            block {}
          }
          name = "JavaDeserializationRCE_URIPATH"
        }
        rule_action_override {
          action_to_use {
            block {}
          }
          name = "JavaDeserializationRCE_QUERYSTRING"
        }
        rule_action_override {
          action_to_use {
            block {}
          }
          name = "JavaDeserializationRCE_HEADER"
        }
        rule_action_override {
          action_to_use {
            block {}
          }
          name = "Host_localhost_HEADER"
        }
        rule_action_override {
          action_to_use {
            block {}
          }
          name = "PROPFIND_METHOD"
        }
        rule_action_override {
          action_to_use {
            block {}
          }
          name = "ExploitablePaths_URIPATH"
        }
        rule_action_override {
          action_to_use {
            block {}
          }
          name = "Log4JRCE_QUERYSTRING"
        }
        rule_action_override {
          action_to_use {
            block {}
          }
          name = "Log4JRCE_BODY"
        }
        rule_action_override {
          action_to_use {
            block {}
          }
          name = "Log4JRCE_URIPATH"
        }
        rule_action_override {
          action_to_use {
            block {}
          }
          name = "Log4JRCE_HEADER"
        }
        rule_action_override {
          action_to_use {
            block {}
          }
          name = "ReactJSRCE_BODY"
        }
      }
    }
    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "AWS-AWSManagedRulesKnownBadInputsRuleSet"
      sampled_requests_enabled    = true
    }
  }

  # AdminProtection Rule Set
  rule {
    name     = "AWS-AWSManagedRulesAdminProtectionRuleSet"
    priority = 5
    override_action {
      none {}
    }
    statement {
      managed_rule_group_statement {
        name        = "AWSManagedRulesAdminProtectionRuleSet"
        vendor_name = "AWS"
        version = "Version_1.1"

        rule_action_override {
          action_to_use {
            count {}
          }
          name = "AdminProtection_URIPATH"
        }
      }
    }
    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "AWS-AWSManagedRulesAdminProtectionRuleSet"
      sampled_requests_enabled    = true
    }
  }

 # Linux Rule Set
  rule {
    name     = "AWS-AWSManagedRulesLinuxRuleSet"
    priority = 6
    override_action {
      none {}
    }
    statement {
      managed_rule_group_statement {
        name        = "AWSManagedRulesLinuxRuleSet"
        vendor_name = "AWS"
        version = "Version_2.6"

        rule_action_override {
          action_to_use {
            block {}
          }
          name = "LFI_URIPATH"
        }
        rule_action_override {
          action_to_use {
            block {}
          }
          name = "LFI_QUERYSTRING"
        }
        rule_action_override {
          action_to_use {
            block {}
          }
          name = "LFI_HEADER"
        }
      }
    }
    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "AWS-AWSManagedRulesLinuxRuleSet"
      sampled_requests_enabled    = true
    }
  }

  # Unix Rule Set
  rule {
    name     = "AWS-AWSManagedRulesUnixRuleSet"
    priority = 7
    override_action {
      none {}
    }
    statement {
      managed_rule_group_statement {
        name        = "AWSManagedRulesUnixRuleSet"
        vendor_name = "AWS"
        version = "Version_3.0"

        rule_action_override {
          action_to_use {
            count {}
          }
          name = "UNIXShellCommandsVariables_QUERYSTRING"
        }
        rule_action_override {
          action_to_use {
            count {}
          }
          name = "UNIXShellCommandsVariables_BODY"
        }
        rule_action_override {
          action_to_use {
            count {}
          }
          name = "UNIXShellCommandsVariables_HEADER"
        }
      }
    }
    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "AWS-AWSManagedRulesUnixRuleSet"
      sampled_requests_enabled    = true
    }
  }

  # SQL Injection Rule Set
  rule {
    name     = "AWS-AWSManagedRulesSQLiRuleSet"
    priority = 8
    override_action {
      none {}
    }
    statement {
      managed_rule_group_statement {
        name        = "AWSManagedRulesSQLiRuleSet"
        vendor_name = "AWS"
        version = "Version_1.3"

        rule_action_override {
          action_to_use {
            block {}
          }
          name = "SQLiExtendedPatterns_QUERYARGUMENTS"
        }
        rule_action_override {
          action_to_use {
            count {}
          }
          name = "SQLi_QUERYARGUMENTS"
        }
        rule_action_override {
          action_to_use {
            count {}
          }
          name = "SQLi_BODY"
        }
        rule_action_override {
          action_to_use {
            block {}
          }
          name = "SQLi_COOKIE"
        }
        rule_action_override {
          action_to_use {
            block {}
          }
          name = "SQLi_URIPATH"
        }
      }
    }
    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "AWS-AWSManagedRulesSQLiRuleSet"
      sampled_requests_enabled    = true
    }
  }

  # AmazonIpReputationList Rule Set
  rule {
    name     = "AWS-AWSManagedRulesAmazonIpReputationList"
    priority = 9
    override_action {
      none {}
    }
    statement {
      managed_rule_group_statement {
        name        = "AWSManagedRulesAmazonIpReputationList"
        vendor_name = "AWS"

        rule_action_override {
          action_to_use {
            count {}
          }
          name = "AWSManagedIPReputationList"
        }
        rule_action_override {
          action_to_use {
            count {}
          }
          name = "AWSManagedReconnaissanceList"
        }
        rule_action_override {
          action_to_use {
            count {}
          }
          name = "AWSManagedIPDDoSList"
        }
      }
    }
    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "AWS-AWSManagedRulesAmazonIpReputationList"
      sampled_requests_enabled    = true
    }
  }

  # Anonymous IP List Rule
  rule {
    name     = "AWS-AWSManagedRulesAnonymousIpList"
    priority = 10
    override_action {
      none {}
    }
    statement {
      managed_rule_group_statement {
        name        = "AWSManagedRulesAnonymousIpList"
        vendor_name = "AWS"
        
        rule_action_override {
          action_to_use {
            count {}
          }
          name = "AnonymousIPList"
        }
        rule_action_override {
          action_to_use {
            count {}
          }
          name = "HostingProviderIPList"
        }
      }
    }
    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "AWS-AWSManagedRulesAnonymousIpList"
      sampled_requests_enabled    = true
    }
  }
}

# ----------------------------------------------------------------------------------------------------------------------
# Web ACL Logging Configuration
# ----------------------------------------------------------------------------------------------------------------------
resource "aws_wafv2_web_acl_logging_configuration" "web_acl_logging" {
  log_destination_configs = [var.waf_s3_arn]
  resource_arn           = aws_wafv2_web_acl.WafWebAcl.arn

  depends_on = [
    aws_wafv2_web_acl.WafWebAcl
  ]
}
