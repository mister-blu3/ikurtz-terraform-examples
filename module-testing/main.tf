# Scenario A: Harness Module Registry (PASS)
# The source MUST match the format registered in Harness (e.g., app.harness.io/ORG/NAME/PROVIDER)
module "harness_module_pass" {
  # Replace ORG/NAME/PROVIDER with the actual path Harness gives you
  source  = "app.harness.io/EeRjnXTnS4GrLG5VNNJZUw/ikurtz-basic-module-test/aws" 
  version = "1.0.0" 
  file_path = "/tmp/harness-test.txt"
}

# Scenario B: Local Module (PASS)
# The Rego policy explicitly allows relative paths
# module "local_module_pass" {
  # source = "./modules/local-test" 
# }

# Scenario C: Public/External Registry Module (FAIL)
# The Rego policy will DENY this because it does not start with the allowed prefixes.
module "external_module_fail" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "5.0.0" 
}
