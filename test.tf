//terraform functions
# locals {
#  string1       = "str1"
#  string2       = "str2"
#  int1          = 3
#  apply_format  = format("This is %s", local.string1)
#  apply_format2 = format("%s_%s_%d", local.string1, local.string2, local.int1)
# }
# output "test1" {
#   value = local.apply_format
# }
# output "test2" {
#   value = local.apply_format2
# }

//terraform data sources
# data "aws_ami_ids" "fetch-ami"{
#     owners = [ "self" ]
#     filter {
#       name = "name"
#       values = [ "wordpress-*" ]
#     }
# }

# output "ami-id" {
#   value = data.aws_ami_ids.fetch-ami.ids
# }