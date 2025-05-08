provider "ncloud" {
  access_key = "YOUR ACCESS KEY"
  secret_key = "YOUR SECRET KEY"
  region = "KR"

  site = "public"
  support_vpc = "true"
}

resource "ncloud_vpc" "vpc" {
  name            = "vpc"
  ipv4_cidr_block = "10.10.0.0/16"
}

resource "ncloud_network_acl" "nacl" {
  vpc_no = ncloud_vpc.vpc.id
}

resource "ncloud_login_key" "mykey" {
  key_name = "mykey"
}

resource "local_file" "ncp_pem" {
  filename = "ncp.pem"
  content = ncloud_login_key.mykey.private_key
}

resource "ncloud_subnet" "pub_subnet" {
  vpc_no          = ncloud_vpc.vpc.id
  subnet          = "10.10.10.0/24"
  zone            = "KR-2"
  network_acl_no  = ncloud_network_acl.nacl.id
  subnet_type     = "PUBLIC"
}

resource "ncloud_access_control_group" "nacg" {
  name   = "nacg"
  vpc_no = ncloud_vpc.vpc.id
}

resource "ncloud_access_control_group_rule" "nginx_rule" {
  access_control_group_no = ncloud_access_control_group.nacg.id
  inbound {
    protocol = "TCP"
    ip_block = "0.0.0.0/0"
    port_range = "22"
    description = "allow ssh"
  }  
  inbound {
    protocol    = "TCP"
    ip_block    = "0.0.0.0/0"
    port_range  = "80"
    description = "HTTP"
  }
  outbound {
    protocol = "TCP"
    ip_block = "0.0.0.0/0"
    port_range = "1-65535"
  }
  outbound {
    protocol = "ICMP"
    ip_block = "0.0.0.0/0"
    description = "ICMP"
  }
}

resource "ncloud_access_control_group_rule" "tomcat_rule" {
  access_control_group_no = ncloud_access_control_group.nacg.id
  inbound {
    protocol = "TCP"
    ip_block = "0.0.0.0/0"
    port_range = "22"
    description = "allow ssh"
  }  
  inbound {
    protocol    = "TCP"
    ip_block    = "0.0.0.0/0"
    port_range  = "8080"
    description = "HTTP"
  }
  outbound {
    protocol = "TCP"
    ip_block = "0.0.0.0/0"
    port_range = "1-65535"
  }
  outbound {
    protocol = "ICMP"
    ip_block = "0.0.0.0/0"
    description = "ICMP"
  }
}

resource "ncloud_access_control_group_rule" "db_rule" {
  access_control_group_no = ncloud_access_control_group.nacg.id
  inbound {
    protocol = "TCP"
    ip_block = "0.0.0.0/0"
    port_range = "22"
    description = "allow ssh"
  }  
  inbound {
    protocol    = "TCP"
    ip_block    = "0.0.0.0/0"
    port_range  = "3306"
    description = "HTTP"
  }
  outbound {
    protocol = "TCP"
    ip_block = "0.0.0.0/0"
    port_range = "1-65535"
  }
  outbound {
    protocol = "ICMP"
    ip_block = "0.0.0.0/0"
    description = "ICMP"
  }
}

resource "ncloud_route_table_association" "route_ass_public" {
  route_table_no = ncloud_vpc.vpc.default_public_route_table_no
  subnet_no      = ncloud_subnet.pub_subnet.id
}

resource "ncloud_network_interface" "nic1" {
  name = "nic1"
  subnet_no = ncloud_subnet.pub_subnet.id
  access_control_groups = [ncloud_access_control_group.nacg.id]
}

# Ubuntu 22.04 LTS 서버 3대
resource "ncloud_server" "nginx-server" {
  name                     = "nginx-server"
  server_image_product_code = "SW.VSVR.OS.LNX64.UBNTU.SVR2204.B050" # 실제 코드 확인 필요
  
  subnet_no                = ncloud_subnet.pub_subnet.id
  zone                     = "KR-2"
  login_key_name           = ncloud_login_key.mykey.key_name
  network_interface {
    network_interface_no           = ncloud_network_interface.nic1.id
    order = 0
  }
  user_data = ("nginx.sh")
}

resource "ncloud_server" "tomcat-server" {
  name                     = "tomcat-server"
  server_image_product_code = "SW.VSVR.OS.LNX64.UBNTU.SVR2204.B050"
  
  subnet_no                = ncloud_subnet.pub_subnet.id
  zone                     = "KR-2"
  login_key_name           = ncloud_login_key.mykey.key_name
   network_interface {
    network_interface_no           = ncloud_network_interface.nic1.id
    order = 0
  }
  user_data = ("tomcat.sh")
}

resource "ncloud_server" "db-server" {
  name                     = "db-server"
  server_image_product_code = "SW.VSVR.OS.LNX64.UBNTU.SVR2204.B050"
  
  subnet_no                = ncloud_subnet.pub_subnet.id
  zone                     = "KR-2"
  login_key_name           = ncloud_login_key.mykey.key_name
   network_interface {
    network_interface_no           = ncloud_network_interface.nic1.id
    order = 0
  }
  user_data = ("mysql.sh")
}

# CentOS 7 서버
resource "ncloud_server" "bastion-server" {
  name                     = "bastion-server"
  server_image_product_code = "SW.VSVR.OS.LNX64.CNTOS.0708.B050" # 실제 코드 확인 필요
  
  subnet_no                = ncloud_subnet.pub_subnet.id
  zone                     = "KR-2"
  login_key_name           = ncloud_login_key.mykey.key_name
   network_interface {
    network_interface_no           = ncloud_network_interface.nic1.id
    order = 0
  }
  user_data = ("setting.sh")
}
