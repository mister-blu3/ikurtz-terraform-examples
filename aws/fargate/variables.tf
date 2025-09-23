// Define Valid Variables
variable "region" {
  description = "The AWS region where resources will be deployed, specifying the geographical location for resource allocation."
  type        = string
  default     = ""
}

variable "vpc_id" {
  description = "The ID of the VPC to use"
  type        = string
  default     = ""
}

variable "subnets" {
  description = "Configuration for public and private subnets"
  type = map(object({
    cidr        = string
    type        = string
    name_suffix = string
  }))
}

variable "tag_environment" {
  description = "The environment tag to be applied to resources, indicating the environment type (e.g., development, staging, production)."
  type        = string
  default     = ""
}

variable "tag_project" {
  description = "The project tag to be applied to resources, indicating the project name or identifier."
  type        = string
  default     = ""
}

variable "tag_owner" {
  description = "The owner tag to be applied to resources, indicating the responsible person or team's contact information."
  type        = string
  default     = ""
}

variable "description_prefix" {
  description = "The prefix to be used in descriptions for resources, helping to categorize or identify the purpose of the resource."
  type        = string
  default     = ""
}

variable "name_prefix" {
  description = "The prefix to be used in naming resources, ensuring consistent and identifiable resource names."
  type        = string
  default     = ""
}

variable "cloudmap_namespace" {
  description = "The namespace to be used for AWS Cloud Map services, typically defining the DNS namespace for service discovery."
  type        = string

  validation {
    condition     = can(regex(".*\\.local$", var.cloudmap_namespace))
    error_message = "The cloudmap_namespace must end with .local."
  }
}

variable "demo_app_version" {
  description = "The version of the demo application to be deployed, indicating the specific release or build found here: https://github.com/GoogleCloudPlatform/microservices-demo"
  type        = string
  default     = "v0.10.0"
}

variable "microservices" {
  description = "List of microservices with their configurations. Don't change this..."
  type = map(object({
    image    = string
    port     = number
    protocol = string
    cpu      = number
    memory   = number
    env_vars = list(object({
      name  = string
      value = string
    }))
  }))
  default = {
    "adservice" = {
      image    = "gcr.io/google-samples/microservices-demo/adservice:{IMAGE_VERSION}"
      port     = 9555
      protocol = "grpc"
      cpu      = 256
      memory   = 512
      env_vars = [
        {
          name  = "PORT"
          value = "9555"
        }
      ]
    },
    "cartservice" = {
      image    = "gcr.io/google-samples/microservices-demo/cartservice:{IMAGE_VERSION}"
      port     = 7070
      protocol = "http"
      cpu      = 256
      memory   = 512
      env_vars = [
        {
          name  = "REDIS_ADDR"
          value = "redis-cart.{CLOUDMAP_NAMESPACE}:6379"
        }
      ]
    },
    "checkoutservice" = {
      image    = "gcr.io/google-samples/microservices-demo/checkoutservice:{IMAGE_VERSION}"
      port     = 5050
      protocol = "grpc"
      cpu      = 256
      memory   = 512
      env_vars = [
        {
          name  = "PORT"
          value = "5050"
        },
        {
          name  = "PRODUCT_CATALOG_SERVICE_ADDR"
          value = "productcatalogservice.{CLOUDMAP_NAMESPACE}:3550"
        },
        {
          name  = "SHIPPING_SERVICE_ADDR"
          value = "shippingservice.{CLOUDMAP_NAMESPACE}:50051"
        },
        {
          name  = "PAYMENT_SERVICE_ADDR"
          value = "paymentservice.{CLOUDMAP_NAMESPACE}:50051"
        },
        {
          name  = "EMAIL_SERVICE_ADDR"
          value = "emailservice.{CLOUDMAP_NAMESPACE}:5000"
        },
        {
          name  = "CURRENCY_SERVICE_ADDR"
          value = "currencyservice.{CLOUDMAP_NAMESPACE}:7000"
        },
        {
          name  = "CART_SERVICE_ADDR"
          value = "cartservice.{CLOUDMAP_NAMESPACE}:7070"
        }
      ]
    },
    "currencyservice" = {
      image    = "gcr.io/google-samples/microservices-demo/currencyservice:{IMAGE_VERSION}"
      port     = 7000
      protocol = "grpc"
      cpu      = 256
      memory   = 512
      env_vars = [
        {
          name  = "PORT"
          value = "7000"
        },
        {
          name  = "DISABLE_PROFILER"
          value = "1"
        }
      ]
    },
    "emailservice" = {
      image    = "gcr.io/google-samples/microservices-demo/emailservice:{IMAGE_VERSION}"
      port     = 8080
      protocol = "http"
      cpu      = 256
      memory   = 512
      env_vars = [
        {
          name  = "PORT"
          value = "8080"
        },
        {
          name  = "DISABLE_PROFILER"
          value = "1"
        }
      ]
    },
    "frontend" = {
      image    = "gcr.io/google-samples/microservices-demo/frontend:{IMAGE_VERSION}"
      port     = 8080
      protocol = "http"
      cpu      = 256
      memory   = 512
      env_vars = [
        {
          name  = "PORT"
          value = "8080"
        },
        {
          name  = "PRODUCT_CATALOG_SERVICE_ADDR"
          value = "productcatalogservice.{CLOUDMAP_NAMESPACE}:3550"
        },
        {
          name  = "CURRENCY_SERVICE_ADDR"
          value = "currencyservice.{CLOUDMAP_NAMESPACE}:7000"
        },
        {
          name  = "CART_SERVICE_ADDR"
          value = "cartservice.{CLOUDMAP_NAMESPACE}:7070"
        },
        {
          name  = "RECOMMENDATION_SERVICE_ADDR"
          value = "recommendationservice.{CLOUDMAP_NAMESPACE}:8080"
        },
        {
          name  = "SHIPPING_SERVICE_ADDR"
          value = "shippingservice.{CLOUDMAP_NAMESPACE}:50051"
        },
        {
          name  = "CHECKOUT_SERVICE_ADDR"
          value = "checkoutservice.{CLOUDMAP_NAMESPACE}:5050"
        },
        {
          name  = "AD_SERVICE_ADDR"
          value = "adservice.{CLOUDMAP_NAMESPACE}:9555"
        },
        {
          name  = "SHOPPING_ASSISTANT_SERVICE_ADDR"
          value = "shoppingassistantservice.{CLOUDMAP_NAMESPACE}:80" #Doesn't appear to be implemented yet?
        },
        {
          name  = "DISABLE_PROFILER"
          value = "1"
        },
        {
          name  = "DISABLE_TRACING"
          value = "1"
        },
        {
          name  = "ENV_PLATFORM"
          value = "aws"
        }
      ]
    },
    "paymentservice" = {
      image    = "gcr.io/google-samples/microservices-demo/paymentservice:{IMAGE_VERSION}"
      port     = 50051
      protocol = "grpc"
      cpu      = 256
      memory   = 512
      env_vars = [
        {
          name  = "PORT"
          value = "50051"
        },
        {
          name  = "DISABLE_PROFILER"
          value = "1"
        }
      ]
    },
    "productcatalogservice" = {
      image    = "gcr.io/google-samples/microservices-demo/productcatalogservice:{IMAGE_VERSION}"
      port     = 3550
      protocol = "http"
      cpu      = 256
      memory   = 512
      env_vars = [
        {
          name  = "PORT"
          value = "3550"
        },
        {
          name  = "DISABLE_PROFILER"
          value = "1"
        }
      ]
    },
    "recommendationservice" = {
      image    = "gcr.io/google-samples/microservices-demo/recommendationservice:{IMAGE_VERSION}"
      port     = 8080
      protocol = "grpc"
      cpu      = 256
      memory   = 512
      env_vars = [
        {
          name  = "PORT"
          value = "8080"
        },
        {
          name  = "PRODUCT_CATALOG_SERVICE_ADDR"
          value = "productcatalogservice.{CLOUDMAP_NAMESPACE}:3550"
        },
        {
          name  = "DISABLE_PROFILER"
          value = "1"
        }
      ]
    },
    "shippingservice" = {
      image    = "gcr.io/google-samples/microservices-demo/shippingservice:{IMAGE_VERSION}"
      port     = 50051
      protocol = "grpc"
      cpu      = 256
      memory   = 512
      env_vars = [
        {
          name  = "PORT"
          value = "50051"
        },
        {
          name  = "DISABLE_PROFILER"
          value = "1"
        }
      ]
    }
  }
}
