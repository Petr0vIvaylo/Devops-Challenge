
provider "aws" {
    access_key = "${var.access_key}"   
    secret_key = "${var.secret_key}"
    region = "${var.region}"
}

data "aws_availability_zones" "availability_zones" {}
    # Create vpc
resource "aws_vpc" "main" {
     cidr_block = "${var.vpc_cidr}"
}

    # Create Internet Gateway
resource "aws_internet_gateway" "gw" {
    vpc_id = "${aws_vpc.main.id}"
}

    # Create route table
resource "aws_route_table" "route_table" {
    vpc_id = "${aws_vpc.main.id}"

    route {
        cidr_block = "0.0.0.0/0"
        gateway_id = "${aws_internet_gateway.gw.id}"
    } 
}

    # Create Subnet
resource "aws_subnet" "subnet_1" {
    vpc_id = "${aws_vpc.main.id}"
    cidr_block = "${var.subnet_1_cidr}"
    availability_zone = "${data.aws_availability_zones.availability_zones.names[0]}"
}   
resource "aws_subnet" "subnet_2" {
    vpc_id = "${aws_vpc.main.id}"
    cidr_block = "${var.subnet_2_cidr}"
    availability_zone = "${data.aws_availability_zones.availability_zones.names[1]}"
}   

resource "aws_route_table_association" "route_association" {
    subnet_id      = "${aws_subnet.subnet_1.id}"
    route_table_id =  "${aws_route_table.route_table.id}"
}

    # Security Group to allow ports 22-ssh, 80-HTTP, 443-HTTPS
    locals {
      ports = [22, 80, 443, 3306]
    }
resource "aws_security_group" "web" {
    name = "Allow_web_traffic"
    description = "Allow_web_incomming_traffic"
    vpc_id = "${aws_vpc.main.id}"

    dynamic "ingress" {
        for_each = local.ports
        content {
            description = "HTTPS, HTTP, SSH, DB"
            from_port = ingress.value
            to_port = ingress.value
            protocol = "${var.web_server_protocol}"
            cidr_blocks = ["${var.all_traffic}"]
        }
        
    }

    egress {
        from_port   = 0
        to_port     = 0
        protocol    = "-1"          # all protocols
        cidr_blocks = ["${var.all_traffic}"]
    }
}

resource "aws_network_interface" "web_server_1_nic" {
    subnet_id = "${aws_subnet.subnet_1.id}"
    private_ips = ["${var.web_server_1_nic_IP}"]
    security_groups = [aws_security_group.web.id]
}

    #public ip address for server_1
resource "aws_eip" "public" {
    vpc                       = true
    network_interface         = aws_network_interface.web_server_1_nic.id
    associate_with_private_ip = "${var.web_server_1_nic_IP}"
    depends_on                = [aws_internet_gateway.gw]
}

resource "aws_instance" "web_server" {
    ami = "${var.web_OS_type}"
    instance_type = "${var.server_instance_type}"
    availability_zone = "${var.availability_zone}"
    key_name = "${var.key_pair}"

    network_interface {
        device_index = 0
        network_interface_id = aws_network_interface.web_server_1_nic.id
    }

    user_data = <<-EOF
                #!/bin/bash
                sudo apt update -y
                sudo apt install apache2 -y
                sudo install php php-mysql
                sudo mkdir -p /var/www/html/
                sudo chown -r ubuntu:apache2 /var/www
                sudo systemctl start apache2
                EOF
}

## create security group for db
resource "aws_security_group" "db_security_group" {
  name        = "db_security_group"
  description = "Allow all inbound traffic"
  vpc_id      = "${aws_vpc.main.id}"
}
## create security group ingress rule for db
resource "aws_security_group_rule" "db_ingress" {
  type              = "ingress"
  protocol          = "${var.db_security_group_protocol}"
  cidr_blocks       = ["${var.all_traffic}"]
  from_port         = "${var.db_security_group_port}"
  to_port           = "${var.db_security_group_port}"
  security_group_id = "${aws_security_group.db_security_group.id}"
}
## create security group egress rule for db
resource "aws_security_group_rule" "db_egress" {
  type              = "egress"
  protocol          = "${var.db_security_group_protocol}"
  cidr_blocks       = ["${var.all_traffic}"]
  from_port         = 0
  to_port           = 0
  security_group_id = "${aws_security_group.db_security_group.id}"
}

## create aws rds subnet groups
resource "aws_db_subnet_group" "db_subnet_group" {
  name       = "my_db_security_group"
  subnet_ids = ["${aws_subnet.subnet_1.id}", "${aws_subnet.subnet_2.id}"]
  tags = {
    Name = "my_database_subnet_group"
  }
}

  # Create DB instance
resource "aws_db_instance" "db_instance" {
    allocated_storage = "${var.db_storage}"
    storage_type = "${var.db_storage_type}"
    engine = "${var.db_engine}"
    engine_version = "${var.db_engine_version}"
    instance_class = "${var.db_instance_class}"
    port = "${var.db_security_group_port}"
    vpc_security_group_ids = ["${aws_security_group.db_security_group.id}"]
    db_subnet_group_name = "${aws_db_subnet_group.db_subnet_group.name}"
    name = "${var.db_name}"
    identifier = "${var.db_identifier}"
    username = "${var.db_username}"
    password = "${var.db_password}"
    skip_final_snapshot    = "${var.db_skip_final_snapshot}"
}


  #Load balancer
resource "aws_lb" "network-load-balancer" {
  name               = "network-load-balancer"
  load_balancer_type = "${var.load_balancer_type}"
    
  subnet_mapping {
    subnet_id            = "${aws_subnet.subnet_1.id}"
    #private_ipv4_address = "${web_server_1_nic_IP}"
  }

  subnet_mapping {
    subnet_id            = "${aws_subnet.subnet_2.id}"
  }
}

  # Cloudwatch CPU monitoring
resource "aws_cloudwatch_metric_alarm" "cpu_utilization" {
  alarm_name                = "${var.alarm_name}"  
  comparison_operator       = "${var.comparison_operator}"
  evaluation_periods        = "${var.evaluation_periods}"
  metric_name               = "${var.metric_name}"
  namespace                 = "${var.namespace}"
  period                    = "${var.period}"
  statistic                 = "${var.statistic}"
  threshold                 = "${var.threshold}"
  alarm_description         = "${var.alarm_description}"
  insufficient_data_actions = []
}

# Auto scaling group
resource "aws_launch_template" "failover_template" {
  image_id      = "${var.web_OS_type}"
  instance_type = "${var.server_instance_type}"   
}

resource "aws_autoscaling_group" "scaling" {
  availability_zones = ["${data.aws_availability_zones.availability_zones.names[0]}"]
  desired_capacity   = "${var.desired_capacity}"
  max_size           = "${var.max_size}"
  min_size           = "${var.min_size}"

  launch_template {
    id      = "${aws_launch_template.failover_template.id}"
    version = "$Latest"
  }
}


##############################################################################
output "server_public_ip" {
  value = aws_eip.public.public_ip
}
output "db_server_address" {
  value = "${aws_db_instance.db_instance.address}"
}