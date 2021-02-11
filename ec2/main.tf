locals {
  is_t_instance_type = replace(var.instance_type, "/^t(2|3|3a){1}\\..*$/", "1") == "1" ? true : false
}

resource "aws_instance" "this" {
  count = var.instance_count

  ami              = var.ami
  instance_type    = var.instance_type
  user_data        = var.user_data
  user_data_base64 = var.user_data_base64
  subnet_id = length(var.network_interface) > 0 ? null : element(
    distinct(compact(concat([var.subnet_id], var.subnet_ids))),
    count.index,
  )
  key_name               = var.key_name
  monitoring             = var.monitoring
  get_password_data      = var.get_password_data
  vpc_security_group_ids = [aws_security_group.vpc_securitygroup.id]
  iam_instance_profile   = var.iam_instance_profile

  associate_public_ip_address = var.associate_public_ip_address
  private_ip                  = length(var.private_ips) > 0 ? element(var.private_ips, count.index) : var.private_ip
  ipv6_address_count          = var.ipv6_address_count
  ipv6_addresses              = var.ipv6_addresses

  ebs_optimized = var.ebs_optimized

  dynamic "ebs_block_device" {
    for_each = var.ebs_block_device
    content {
      delete_on_termination = lookup(ebs_block_device.value, "delete_on_termination", null)
      device_name           = ebs_block_device.value.device_name
      encrypted             = lookup(ebs_block_device.value, "encrypted", null)
      iops                  = lookup(ebs_block_device.value, "iops", null)
      kms_key_id            = lookup(ebs_block_device.value, "kms_key_id", null)
      snapshot_id           = lookup(ebs_block_device.value, "snapshot_id", null)
      volume_size           = lookup(ebs_block_device.value, "volume_size", null)
      volume_type           = lookup(ebs_block_device.value, "volume_type", null)
    }
  }

  dynamic "ephemeral_block_device" {
    for_each = var.ephemeral_block_device
    content {
      device_name  = ephemeral_block_device.value.device_name
      no_device    = lookup(ephemeral_block_device.value, "no_device", null)
      virtual_name = lookup(ephemeral_block_device.value, "virtual_name", null)
    }
  }

  dynamic "metadata_options" {
    for_each = length(keys(var.metadata_options)) == 0 ? [] : [var.metadata_options]
    content {
      http_endpoint               = lookup(metadata_options.value, "http_endpoint", "enabled")
      http_tokens                 = lookup(metadata_options.value, "http_tokens", "optional")
      http_put_response_hop_limit = lookup(metadata_options.value, "http_put_response_hop_limit", "1")
    }
  }

  dynamic "network_interface" {
    for_each = var.network_interface
    content {
      device_index          = network_interface.value.device_index
      network_interface_id  = lookup(network_interface.value, "network_interface_id", null)
      delete_on_termination = lookup(network_interface.value, "delete_on_termination", false)
    }
  }

  source_dest_check                    = length(var.network_interface) > 0 ? null : var.source_dest_check
  disable_api_termination              = var.disable_api_termination
  instance_initiated_shutdown_behavior = var.instance_initiated_shutdown_behavior
  placement_group                      = var.placement_group
  tenancy                              = var.tenancy

  tags = merge(
    {
      "Name" = var.instance_count > 1 || var.use_num_suffix ? format("%s${var.num_suffix_format}", var.name, count.index + 1) : var.name
    },
    var.tags,
  )

  volume_tags = merge(
    {
      "Name" = var.instance_count > 1 || var.use_num_suffix ? format("%s${var.num_suffix_format}", var.name, count.index + 1) : var.name
    },
    var.volume_tags,
  )

  credit_specification {
    cpu_credits = local.is_t_instance_type ? var.cpu_credits : null
  }
}
resource "aws_security_group" "vpc_securitygroup" {
  #name_prefix            = "${var.prename}-"  # Conflicts with name.
  name        = var.sg-name
  description = var.description
  vpc_id  = var.VPC_ID
  dynamic "ingress" {
    for_each = var.ingress_rules
    content {
      cidr_blocks      = lookup(ingress.value, "cidr_blocks", null)
      description      = lookup(ingress.value, "description", null)
      from_port        = lookup(ingress.value, "from_port", null)
      ipv6_cidr_blocks = lookup(ingress.value, "ipv6_cidr_blocks", null)
      prefix_list_ids  = lookup(ingress.value, "prefix_list_ids", null)
      protocol         = lookup(ingress.value, "protocol", null)
      security_groups  = lookup(ingress.value, "security_groups", null)
      self             = lookup(ingress.value, "self", null)
      to_port          = lookup(ingress.value, "to_port", null)
    }
  }

  dynamic "egress" {
    for_each = var.egress_rules
    content {
      cidr_blocks      = lookup(egress.value, "cidr_blocks", null)
      description      = lookup(egress.value, "description", null)
      from_port        = lookup(egress.value, "from_port", null)
      ipv6_cidr_blocks = lookup(egress.value, "ipv6_cidr_blocks", null)
      prefix_list_ids  = lookup(egress.value, "prefix_list_ids", null)
      protocol         = lookup(egress.value, "protocol", null)
      security_groups  = lookup(egress.value, "security_groups", null)
      self             = lookup(egress.value, "self", null)
      to_port          = lookup(egress.value, "to_port", null)
    }
  }
  revoke_rules_on_delete = var.revoke_rules_on_delete
  tags                   = var.sg-tags
}

resource "aws_security_group_rule" "ingress_tcp" {
 
  type              = "ingress"
  from_port         =  80 
  to_port           = 80 
  protocol          = "tcp"
  cidr_blocks       = var.ingress_cidr_blocks  # ["0.0.0.0/0"] #Cannot be specified with source_security_group_id.
  prefix_list_ids   = var.ingress_prefix_list_ids
  #source_security_group_id = var.SSH_SG     #Cannot be specified with cidr_blocks and self.
  ipv6_cidr_blocks = var.ingress_ipv6_cidr_blocks 
  self = var.ingress_self                     #Cannot be specified with source_security_group_id.
  description = "Allow Traffic to VPC"
  security_group_id = join("", aws_security_group.vpc_securitygroup.*.id)
}

resource "aws_security_group_rule" "egress" {
  type              = "egress"
  from_port         = 0
  to_port           = 65535
  protocol          = "-1"
  cidr_blocks       = var.egress_cidr_blocks #["0.0.0.0/0"]  ##Cannot be specified with source_security_group_id.
  prefix_list_ids   = var.egress_prefix_list_ids 
  ipv6_cidr_blocks  = var.egress_ipv6_cidr_blocks 
  #source_security_group_id =var.SSH_SG       # Cannot be specified with cidr_blocks and self.
  self              = var.egress_self                #Cannot be specified with source_security_group_id.
  description       = "Allow Traffic"
  security_group_id = join("", aws_security_group.vpc_securitygroup.*.id)
}
