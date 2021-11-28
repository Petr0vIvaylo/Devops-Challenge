variable "access_key" {default = "***public_key***"} 
variable "secret_key" {default = "***private_key***"}
variable "region" {default = "eu-central-1"}
variable "vpc_cidr" { default = "10.0.0.0/22"}
variable "availability_zone" {default = "eu-central-1a"}
variable "subnet_1_cidr" {default = "10.0.1.0/24"}
variable "subnet_2_cidr" {default = "10.0.2.0/24"}

# variable "web_ports" {default = ["443", "80", "22", "3306"]}
variable "all_traffic" {default = "0.0.0.0/0"}
variable "web_server_1_nic_IP" {default = "10.0.1.50"}

variable "web_server_protocol" {default = "tcp"}
variable "server_instance_type" {default = "t2.micro"}
variable "web_OS_type" {
    default = "ami-0a49b025fffbbdac6"
    description = "Ubuntu Server 20.04 LTS (HVM), SSD Volume Type"
} 
variable "key_pair" {default = "main-key"}
variable "db_security_group_protocol" {default = "tcp"}
variable "db_security_group_port" {default = 3306}


# Load balancer
variable "load_balancer_type" {default = "network"}



#mySQL DB configration varaiables
variable "db_storage" {default = 20}
variable "db_storage_type" {default = "gp2"}
variable "db_engine" {default = "mysql"}
variable "db_engine_version" {default = "8.0"}
variable "db_instance_class" {default = "db.t2.micro"}
variable "db_name" {default = "mydb"}
variable "db_identifier" {default = "mysqldb"} 
variable "db_username" {default = "admin"} 
variable "db_password" {default = "MegaSecurePwd1!"} 
variable "db_skip_final_snapshot" {default = true} 

# Cloudwatch monitoring
variable  "alarm_name"   {default = "ec2 cpu utilization"}
variable "comparison_operator" {default = "GreaterThanOrEqualToThreshold"}
variable "evaluation_periods"  {default = 2}
variable "metric_name"         {default = "CPUUtilization"}
variable "namespace"           {default = "AWS/EC2"}
variable "period"              {default = 120}
variable "statistic"           {default = "Average"}
variable "threshold"           {default = 80}
variable "alarm_description"   {default = "This metric monitors ec2 cpu utilization"}


# aoutoscaling
variable "desired_capacity" {default = 1}
variable "max_size"         {default = 1}
variable "min_size"         {default = 1}
