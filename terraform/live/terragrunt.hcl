# terraform/live/terragrunt.hcl
# terraform {
#   extra_arguments "common_vars" {
#     arguments = [
#       "-var", "subscription_id=${get_env("ARM_SUBSCRIPTION_ID")}",
#       "-var", "client_id=${get_env("ARM_CLIENT_ID")}",
#       "-var", "client_secret=${get_env("ARM_CLIENT_SECRET")}",
#       "-var", "tenant_id=${get_env("ARM_TENANT_ID")}"
#     ]
#   }
# }

# terraform/live/terragrunt.hcl
# Root file: only global extras (do not include other files from here)

terraform {
  extra_arguments "common_vars" {
    commands = ["plan", "apply", "destroy"]
    arguments = [
      "-var", "subscription_id=${get_env("ARM_SUBSCRIPTION_ID")}",
      "-var", "client_id=${get_env("ARM_CLIENT_ID")}",
      "-var", "client_secret=${get_env("ARM_CLIENT_SECRET")}",
      "-var", "tenant_id=${get_env("ARM_TENANT_ID")}"
    ]
  }
}
