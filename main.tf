provider "aws" {
  region     = var.central-region
}

data "aws_caller_identity" "current" {}

module "lambda_function" {
  source = "terraform-aws-modules/lambda/aws"

  function_name = var.fuction-name
  handler       = "index.handler"
  runtime       = "nodejs16.x"
  publish       = true

  source_path = var.source-path

  allowed_triggers = {
    APIGatewayAny = {
      service    = "apigateway"
      source_arn = "arn:aws:execute-api:${var.central-region}:${data.aws_caller_identity.current.account_id}:${module.api_gateway.apigatewayv2_api_id}/*/*/${var.fuction-name}"
    }
  }

  tags = {
    Name = var.fuction-name
  }
}

module "api_gateway" {
  source = "terraform-aws-modules/apigateway-v2/aws"

  name          = "${var.fuction-name}-http"
  protocol_type = "HTTP"

  create_api_domain_name = false

  # Routes and integrations
  integrations = {
    "ANY /${var.fuction-name}" = {
      lambda_arn             = module.lambda_function.lambda_function_arn
      payload_format_version = "2.0"
      timeout_milliseconds   = 12000
    }
  }

  tags = {
    Name = "${var.fuction-name}-http"
  }
}
