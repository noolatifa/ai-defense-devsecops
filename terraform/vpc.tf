resource "aws_vpc" "aegis_vpc" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Name = "aegis-vpc"
  }
}


# creation de public subnet for natgateway
resource "aws_subnet" "public_subnet" {
  vpc_id                  = aws_vpc.aegis_vpc.id
  cidr_block              = "10.0.1.0/24"
  availability_zone       = "us-east-1a"

  tags = {
    Name = "aegis-public-subnet"
  }
}


# 3. La chambre privée (Où vivra notre conteneur ECS, isolé d'Internet)
resource "aws_subnet" "private_subnet" {
  vpc_id            = aws_vpc.aegis_vpc.id
  cidr_block        = "10.0.2.0/24"
  availability_zone = "us-east-1a"

  tags = {
    Name = "aegis-private-subnet"
  }
}

# 4 ENTREE/SORTIE avec internet (IGW)
resource "aws_internet_gateway" "aegis_igw" {
  vpc_id = aws_vpc.aegis_vpc.id

  tags = {
    Name = "aegis-igw"
  }
}


# 5 ip fixe for nat gateway 

resource "aws_eip" "aegis_nat_eip" {
 # domain = "vpc" 

  tags = {
    Name = "aegis-nat-eip"
  }
}

# 6 NAT GW CREATION (avec elastic ip above)  | !!! il est dur le public subnet !!!!

resource "aws_nat_gateway" "aegis_nat" {
  allocation_id = aws_eip.aegis_nat_eip.id
  subnet_id = aws_subnet.public_subnet.id

  tags = {
    Name = "aegis-nat-gateway"
  }

  depends_on = [aws_internet_gateway.aegis_igw]



}

# 7 table de routage publique ( le pub subnet uses l'igw) | 0000/0 pour dire all ips

resource "aws_route_table" "public_rt" {
  vpc_id = aws_vpc.aegis_vpc.id

    route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.aegis_igw.id
  }

    tags = {
    Name = "aegis-public-rt"
  }
}


# 8 table de routage privee  (private sub uses nat gateway)

resource "aws_route_table" "private_rt" {
  vpc_id = aws_vpc.aegis_vpc.id

    route {
    cidr_block = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.aegis_nat.id
  }

    tags = {
    Name = "aegis-private-rt"
  }
}


#ASSOCIATION DES ROUTE TABLES TO SUBNETS 


#public_rt 
resource "aws_route_table_association" "public_rt_assoc" {
  subnet_id      = aws_subnet.public_subnet.id
  route_table_id = aws_route_table.public_rt.id
}

#private_rt
resource "aws_route_table_association" "private_rt_assoc" {
  subnet_id      = aws_subnet.private_subnet.id
  route_table_id = aws_route_table.private_rt.id
}



# 9 SECURITY GROUP (firewall I/O)

resource "aws_security_group" "aegis_ecs_sg" {
  name        = "aegis-ecs-sg"
  description = "Pare-feu pour le conteneur AEGIS"
  vpc_id      = aws_vpc.aegis_vpc.id



  #ALLOW EGRESS
  egress {
    from_port = 0
    to_port = 0
    protocol = "-1"  #all protocolsss
    cidr_blocks = ["0.0.0.0/0"]
  }


# !!! NO DENY INGRESS NEEDED aws bloque tout par defaut


tags = {
  Name = "aegis_ecs_sg"
}


}