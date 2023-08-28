#shared variables
region_name     = "us-east-2"


#vpc specific vars
vpc_cidr        = "10.1.0.0/16" 
#To Do - improve logic using cidrsubnet function to create these from main cidr
public_nets     = ["10.1.0.0/24","10.1.1.0/24"]
private_nets    = ["10.1.2.0/24","10.1.3.0/24"]
db_nets         = ["10.1.4.0/24","10.1.5.0/24"]
avail_zones     = ["us-east-2a","us-east-2b"]

#ec2 specific vars
win_image       = "Windows Server 2019"
linux_image     = "RHEL 8"
win_type        = "t3a.medium"
linux_type      = "t3a.micro"
win_hostnames   = ["bastion1","bastion2"]
linux_hostnames  = ["wpserver1","wpserver2"]
win_vol_size    = "50"
linux_vol_size  = "100"
vol_type        = "gp3"

#route 53 specific vars
domain_name     = "abcfjser.tv"
ttl             = "180"
sub_domain_name = "mysite.abcfjser.tv"
records = ["1.2.3.4"]
